// services/backend/transport/ws/hub.go
package ws

import (
	"encoding/json"
	"sync"

	"server/domain"

	"github.com/gorilla/websocket"
	"go.uber.org/zap"
)

type Client struct {
	ID     string
	RoomID string
	Conn   *websocket.Conn
	Send   chan []byte
}

type MessageEnvelope struct {
	RoomID string
	Sender *Client
	Data   []byte
}

type Hub struct {
	rooms      map[string]map[*Client]bool
	register   chan *Client
	unregister chan *Client
	broadcast  chan MessageEnvelope
	mu         sync.RWMutex
	logger     *zap.Logger
}

func NewHub(logger *zap.Logger) *Hub {
	return &Hub{
		rooms:      make(map[string]map[*Client]bool),
		register:   make(chan *Client),
		unregister: make(chan *Client),
		broadcast:  make(chan MessageEnvelope),
		logger:     logger,
	}
}

func (h *Hub) Run() {
	for {
		select {
		case client := <-h.register:
			h.mu.Lock()
			if _, exists := h.rooms[client.RoomID]; !exists {
				h.rooms[client.RoomID] = make(map[*Client]bool)
			}

			for existingClient := range h.rooms[client.RoomID] {
				// Powiadomienie istniejącego klienta o nowym uczestniku
				notifyJoined, _ := json.Marshal(domain.WSMessage{
					Type:   "peer_joined",
					Sender: "server",
					Payload: map[string]string{
						"peer_id": client.ID,
					},
				})
				existingClient.Conn.WriteMessage(websocket.TextMessage, notifyJoined)

				// Powiadomienie nowego klienta o obecnych uczestnikach
				notifyExisting, _ := json.Marshal(domain.WSMessage{
					Type:   "peer_joined",
					Sender: "server",
					Payload: map[string]string{
						"peer_id": existingClient.ID,
					},
				})
				client.Conn.WriteMessage(websocket.TextMessage, notifyExisting)
			}

			h.rooms[client.RoomID][client] = true
			h.mu.Unlock()

			h.logger.Info("Client registered to room",
				zap.String("room_id", client.RoomID),
				zap.String("client_id", client.ID),
			)

		case client := <-h.unregister:
			h.mu.Lock()
			if clients, ok := h.rooms[client.RoomID]; ok {
				if _, ok := clients[client]; ok {
					delete(clients, client)
					client.Conn.Close()

					// Powiadomienie pozostałych członków pokoju o wyjściu klienta
					for remainingClient := range clients {
						notifyLeft, _ := json.Marshal(domain.WSMessage{
							Type:   "peer_left",
							Sender: "server",
							Payload: map[string]string{
								"peer_id": client.ID,
							},
						})
						remainingClient.Conn.WriteMessage(websocket.TextMessage, notifyLeft)
					}
				}
				if len(clients) == 0 {
					delete(h.rooms, client.RoomID)
				}
			}
			h.mu.Unlock()

			h.logger.Info("Client unregistered from room",
				zap.String("room_id", client.RoomID),
				zap.String("client_id", client.ID),
			)

		case env := <-h.broadcast:
			h.mu.RLock()
			if clients, ok := h.rooms[env.RoomID]; ok {
				for client := range clients {
					if client != env.Sender {
						err := client.Conn.WriteMessage(websocket.TextMessage, env.Data)
						if err != nil {
							h.logger.Error("Failed to send message to client",
								zap.String("client_id", client.ID),
								zap.Error(err),
							)
						}
					}
				}
			}
			h.mu.RUnlock()
		}
	}
}
