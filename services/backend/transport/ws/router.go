package ws

import (
	"context"
	"encoding/json"
	"net/http"
	"time"

	"server/domain"

	"github.com/gorilla/websocket"
	"go.uber.org/zap"
)

const (
	writeWait      = 10 * time.Second
	pongWait       = 60 * time.Second
	pingPeriod     = (pongWait * 9) / 10
	maxMessageSize = 512 * 1024 // 512KB
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

func ServeWS(logger *zap.Logger, hub *Hub, t domain.Translator, w http.ResponseWriter, r *http.Request) {
	roomID := r.URL.Query().Get("room")
	logger.Debug("[router.go -> ServeWS -> 1.0 -> Incoming WS HTTP Request]", zap.String("remote_addr", r.RemoteAddr), zap.String("room_id", roomID))

	if roomID == "" {
		logger.Warn("[router.go -> ServeWS -> 1.1 -> Missing room parameter]", zap.String("remote_addr", r.RemoteAddr))
		http.Error(w, "Room ID parameter is required", http.StatusBadRequest)
		return
	}

	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		logger.Error("[router.go -> ServeWS -> ERR -> Upgrade failed]", zap.Error(err), zap.String("remote_addr", r.RemoteAddr))
		return
	}

	client := &Client{
		ID:     r.RemoteAddr,
		RoomID: roomID,
		Conn:   conn,
		Send:   make(chan []byte, 256),
		Hub:    hub,
	}

	logger.Debug("[router.go -> ServeWS -> 1.2 -> Upgrade successful, registering client in hub]", zap.String("client_id", client.ID))
	client.Hub.register <- client

	go client.writePump(logger)
	go client.readPump(r.Context(), logger, t)
}

func (c *Client) readPump(ctx context.Context, logger *zap.Logger, t domain.Translator) {
	defer func() {
		logger.Debug("[router.go -> readPump -> 1.0 -> Stopping read pump]", zap.String("remote_addr", c.ID), zap.String("room_id", c.RoomID))
		c.Hub.unregister <- c
		c.Conn.Close()
		logger.Info("[router.go -> readPump -> 1.1 -> Client read pump stopped]", zap.String("remote_addr", c.ID), zap.String("room_id", c.RoomID))
	}()

	c.Conn.SetReadLimit(maxMessageSize)
	_ = c.Conn.SetReadDeadline(time.Now().Add(pongWait))
	c.Conn.SetPongHandler(func(string) error {
		_ = c.Conn.SetReadDeadline(time.Now().Add(pongWait))
		return nil
	})

	for {
		_, message, err := c.Conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				logger.Warn("[router.go -> readPump -> 1.2 -> Unexpected WS closure]", zap.Error(err), zap.String("remote_addr", c.ID))
			}
			break
		}

		var wsMsg domain.WSMessage
		if err := json.Unmarshal(message, &wsMsg); err != nil {
			logger.Error("[router.go -> readPump -> ERR -> Unmarshal failed]", zap.Error(err), zap.ByteString("raw_message", message))
			continue
		}

		if wsMsg.Sender == "" {
			wsMsg.Sender = c.ID
		}

		logger.Debug("[router.go -> readPump -> 1.3 -> Received WS message]",
			zap.String("type", wsMsg.Type),
			zap.String("sender", wsMsg.Sender),
			zap.String("room_id", c.RoomID),
		)

		switch wsMsg.Type {
		case "offer", "answer", "candidate":
			payload, err := json.Marshal(wsMsg)
			if err != nil {
				logger.Error("[router.go -> readPump -> ERR -> Marshal WebRTC message failed]", zap.Error(err))
				continue
			}

			logger.Debug("[router.go -> readPump -> 1.4 -> Forwarding WebRTC message to broadcast]", zap.String("type", wsMsg.Type))
			c.Hub.broadcast <- MessageEnvelope{
				RoomID: c.RoomID,
				Sender: c,
				Data:   payload,
			}

		case "translate":
			text, ok := wsMsg.Payload.(string)
			if !ok {
				logger.Warn("[router.go -> readPump -> 1.5 -> Invalid payload for translation]", zap.String("sender", wsMsg.Sender))
				continue
			}

			req := domain.TranslationRequest{Text: text}
			resp, err := t.Translate(ctx, req)

			var translatedText string
			if err != nil || resp == nil {
				logger.Error("[router.go -> readPump -> ERR -> Translation failed]", zap.String("sender", wsMsg.Sender), zap.Error(err))
				translatedText = text
			} else {
				translatedText = resp.TranslatedText
			}

			responsePayload, err := json.Marshal(domain.WSMessage{
				Type:    "translation_result",
				Sender:  "server",
				Payload: translatedText,
			})
			if err != nil {
				logger.Error("[router.go -> readPump -> ERR -> Marshal translation response failed]", zap.Error(err))
				continue
			}

			c.Hub.broadcast <- MessageEnvelope{
				RoomID: c.RoomID,
				Sender: nil,
				Data:   responsePayload,
			}

		default:
			payload, err := json.Marshal(wsMsg)
			if err != nil {
				logger.Error("[router.go -> readPump -> ERR -> Marshal default message failed]", zap.Error(err))
				continue
			}

			c.Hub.broadcast <- MessageEnvelope{
				RoomID: c.RoomID,
				Sender: c,
				Data:   payload,
			}
		}
	}
}

func (c *Client) writePump(logger *zap.Logger) {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		c.Conn.Close()
		logger.Debug("[router.go -> writePump -> 1.0 -> Client write pump stopped]", zap.String("remote_addr", c.ID), zap.String("room_id", c.RoomID))
	}()

	for {
		select {
		case message, ok := <-c.Send:
			_ = c.Conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				_ = c.Conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			w, err := c.Conn.NextWriter(websocket.TextMessage)
			if err != nil {
				logger.Error("[router.go -> writePump -> ERR -> NextWriter failed]", zap.Error(err), zap.String("client_id", c.ID))
				return
			}
			_, _ = w.Write(message)

			n := len(c.Send)
			for i := 0; i < n; i++ {
				_, _ = w.Write([]byte{'\n'})
				_, _ = w.Write(<-c.Send)
			}

			if err := w.Close(); err != nil {
				logger.Error("[router.go -> writePump -> ERR -> Writer close failed]", zap.Error(err), zap.String("client_id", c.ID))
				return
			}

		case <-ticker.C:
			_ = c.Conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.Conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				logger.Debug("[router.go -> writePump -> ERR -> Ping failed]", zap.Error(err), zap.String("client_id", c.ID))
				return
			}
		}
	}
}
