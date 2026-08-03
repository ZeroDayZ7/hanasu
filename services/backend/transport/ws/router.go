// services/backend/transport/ws/router.go
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
	if roomID == "" {
		logger.Warn("Connection attempt without room parameter", zap.String("remote_addr", r.RemoteAddr))
		http.Error(w, "Room ID parameter is required", http.StatusBadRequest)
		return
	}

	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		logger.Error("Failed to upgrade connection to WebSocket", zap.Error(err), zap.String("remote_addr", r.RemoteAddr))
		return
	}

	client := &Client{
		ID:     r.RemoteAddr,
		RoomID: roomID,
		Conn:   conn,
		Send:   make(chan []byte, 256),
		Hub:    hub,
	}

	client.Hub.register <- client

	// Start async reader & writer pumps
	go client.writePump(logger)
	go client.readPump(r.Context(), logger, t)
}

func (c *Client) readPump(ctx context.Context, logger *zap.Logger, t domain.Translator) {
	defer func() {
		c.Hub.unregister <- c
		c.Conn.Close()
		logger.Info("Client read pump stopped", zap.String("remote_addr", c.ID), zap.String("room_id", c.RoomID))
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
				logger.Warn("Unexpected WebSocket connection closure", zap.Error(err), zap.String("remote_addr", c.ID))
			}
			break
		}

		var wsMsg domain.WSMessage
		if err := json.Unmarshal(message, &wsMsg); err != nil {
			logger.Error("Failed to decode WS message", zap.Error(err), zap.ByteString("raw_message", message))
			continue
		}

		if wsMsg.Sender == "" {
			wsMsg.Sender = c.ID
		}

		logger.Debug("Received WS message",
			zap.String("type", wsMsg.Type),
			zap.String("sender", wsMsg.Sender),
			zap.String("room_id", c.RoomID),
		)

		switch wsMsg.Type {
		case "offer", "answer", "candidate":
			payload, err := json.Marshal(wsMsg)
			if err != nil {
				logger.Error("Failed to marshal WebRTC message", zap.Error(err))
				continue
			}

			c.Hub.broadcast <- MessageEnvelope{
				RoomID: c.RoomID,
				Sender: c,
				Data:   payload,
			}

		case "translate":
			text, ok := wsMsg.Payload.(string)
			if !ok {
				logger.Warn("Invalid payload type for translation", zap.String("sender", wsMsg.Sender))
				continue
			}

			req := domain.TranslationRequest{Text: text}
			resp, err := t.Translate(ctx, req)

			var translatedText string
			if err != nil || resp == nil {
				logger.Error("Translation failed, falling back to original text", zap.String("sender", wsMsg.Sender), zap.Error(err))
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
				logger.Error("Failed to marshal WS response", zap.Error(err))
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
				logger.Error("Failed to marshal default message", zap.Error(err))
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
		logger.Debug("Client write pump stopped", zap.String("remote_addr", c.ID), zap.String("room_id", c.RoomID))
	}()

	for {
		select {
		case message, ok := <-c.Send:
			_ = c.Conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				// Kanał został zamknięty przez Hub
				_ = c.Conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			w, err := c.Conn.NextWriter(websocket.TextMessage)
			if err != nil {
				logger.Error("Failed to get next writer", zap.Error(err), zap.String("client_id", c.ID))
				return
			}
			_, _ = w.Write(message)

			// Opróżnienie bufora, jeśli zgromadziło się więcej wiadomości
			n := len(c.Send)
			for i := 0; i < n; i++ {
				_, _ = w.Write([]byte{'\n'})
				_, _ = w.Write(<-c.Send)
			}

			if err := w.Close(); err != nil {
				logger.Error("Failed to close message writer", zap.Error(err), zap.String("client_id", c.ID))
				return
			}

		case <-ticker.C:
			_ = c.Conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.Conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				logger.Debug("Failed to send ping message", zap.Error(err), zap.String("client_id", c.ID))
				return
			}
		}
	}
}
