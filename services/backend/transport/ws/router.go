package ws

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"server/domain"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true // Przyjęcie połączeń w sieci prywatnej (np. Tailscale)
	},
}

// ServeWS obsługuje podniesienie połączenia HTTP do WebSocket
func ServeWS(hub *Hub, t domain.Translator, w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("Błąd upgrade'u do WebSocket: %v", err)
		return
	}

	hub.register <- conn

	go handleConnection(r.Context(), hub, t, conn)
}

func handleConnection(ctx context.Context, hub *Hub, t domain.Translator, conn *websocket.Conn) {
	defer func() {
		hub.unregister <- conn
		conn.Close()
	}()

	for {
		_, message, err := conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("Nieoczekiwane zamknięcie WS: %v", err)
			}
			break
		}

		var wsMsg domain.WSMessage
		if err := json.Unmarshal(message, &wsMsg); err != nil {
			log.Printf("Błąd dekodowania pakietu WS: %v", err)
			continue
		}

		switch wsMsg.Type {
		case "offer", "answer", "candidate":
			hub.broadcast <- message

		case "translate":
			text, ok := wsMsg.Payload.(string)
			if !ok {
				log.Printf("Nieprawidłowy typ payloadu dla tłumaczenia od [%s]", wsMsg.Sender)
				continue
			}

			req := domain.TranslationRequest{
				Text: text,
			}

			resp, err := t.Translate(ctx, req)
			var translatedText string
			if err != nil || resp == nil {
				log.Printf("Błąd tłumaczenia tekstu od [%s]: %v", wsMsg.Sender, err)
				translatedText = text // Fallback do oryginalnego tekstu
			} else {
				translatedText = resp.TranslatedText
			}

			responsePayload, err := json.Marshal(domain.WSMessage{
				Type:    "translation_result",
				Sender:  "server",
				Payload: translatedText,
			})
			if err != nil {
				log.Printf("Błąd kodowania odpowiedzi WS: %v", err)
				continue
			}

			hub.broadcast <- responsePayload

		default:
			hub.broadcast <- message
		}
	}
}
