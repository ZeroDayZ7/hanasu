// services/backend/transport/ws/router.go
package ws

import (
	"context"
	"encoding/json"
	"net/http"

	"server/domain"

	"github.com/gorilla/websocket"
	"go.uber.org/zap"
)

var upgrader = websocket.Upgrader{
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
	}

	hub.register <- client

	go handleConnection(r.Context(), logger, hub, t, client)
}

// services/backend/transport/ws/router.go

func handleConnection(ctx context.Context, logger *zap.Logger, hub *Hub, t domain.Translator, client *Client) {
	defer func() {
		logger.Info("Client disconnected", zap.String("remote_addr", client.ID), zap.String("room_id", client.RoomID))
		hub.unregister <- client
	}()

	for {
		_, message, err := client.Conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				logger.Warn("Unexpected WebSocket connection closure", zap.Error(err), zap.String("remote_addr", client.ID))
			}
			break
		}

		var wsMsg domain.WSMessage
		if err := json.Unmarshal(message, &wsMsg); err != nil {
			logger.Error("Failed to decode WS message", zap.Error(err), zap.ByteString("raw_message", message))
			continue
		}

		// KLUCZOWY KROK: Jeżeli klient nie przesłał pola Sender, wymuszamy przypisanie ID klienta
		if wsMsg.Sender == "" {
			wsMsg.Sender = client.ID
		}

		logger.Debug("Received WS message",
			zap.String("type", wsMsg.Type),
			zap.String("sender", wsMsg.Sender),
			zap.String("room_id", client.RoomID),
		)

		switch wsMsg.Type {
		case "offer", "answer", "candidate":
			logger.Info("Relaying WebRTC signal",
				zap.String("type", wsMsg.Type),
				zap.String("sender", wsMsg.Sender),
				zap.String("room_id", client.RoomID),
			)

			// Kodujemy wiadomość ponownie do JSON z uzupełnionym polem Sender
			payload, err := json.Marshal(wsMsg)
			if err != nil {
				logger.Error("Failed to marshal WebRTC message", zap.Error(err))
				continue
			}

			hub.broadcast <- MessageEnvelope{
				RoomID: client.RoomID,
				Sender: client,
				Data:   payload,
			}

		case "translate":
			text, ok := wsMsg.Payload.(string)
			if !ok {
				logger.Warn("Invalid payload type for translation", zap.String("sender", wsMsg.Sender))
				continue
			}

			logger.Debug("Starting translation", zap.String("sender", wsMsg.Sender), zap.String("text", text))

			req := domain.TranslationRequest{Text: text}
			resp, err := t.Translate(ctx, req)

			var translatedText string
			if err != nil || resp == nil {
				logger.Error("Translation failed, falling back to original text", zap.String("sender", wsMsg.Sender), zap.Error(err))
				translatedText = text
			} else {
				translatedText = resp.TranslatedText
				logger.Debug("Translation successful", zap.String("result", translatedText))
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

			hub.broadcast <- MessageEnvelope{
				RoomID: client.RoomID,
				Sender: nil,
				Data:   responsePayload,
			}

		default:
			logger.Debug("Handling default WS message type", zap.String("type", wsMsg.Type))

			payload, err := json.Marshal(wsMsg)
			if err != nil {
				logger.Error("Failed to marshal default message", zap.Error(err))
				continue
			}

			hub.broadcast <- MessageEnvelope{
				RoomID: client.RoomID,
				Sender: client,
				Data:   payload,
			}
		}
	}
}
