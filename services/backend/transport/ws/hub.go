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
	Hub    *Hub
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

			// Informowanie istniejących i nowego użytkownika
			for existingClient := range h.rooms[client.RoomID] {
				notifyJoined, _ := json.Marshal(domain.WSMessage{
					Type:   "peer_joined",
					Sender: "server",
					Payload: map[string]string{
						"peer_id": client.ID,
					},
				})
				select {
				case existingClient.Send <- notifyJoined:
				default:
				}

				notifyExisting, _ := json.Marshal(domain.WSMessage{
					Type:   "peer_joined",
					Sender: "server",
					Payload: map[string]string{
						"peer_id": existingClient.ID,
					},
				})
				select {
				case client.Send <- notifyExisting:
				default:
				}
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
					close(client.Send)

					notifyLeft, _ := json.Marshal(domain.WSMessage{
						Type:   "peer_left",
						Sender: "server",
						Payload: map[string]string{
							"peer_id": client.ID,
						},
					})

					for remainingClient := range clients {
						select {
						case remainingClient.Send <- notifyLeft:
						default:
						}
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
						select {
						case client.Send <- env.Data:
						default:
							// Bufor pełny - klient rozłączony/zatkany
							h.logger.Warn("Client buffer full, dropping message", zap.String("client_id", client.ID))
						}
					}
				}
			}
			h.mu.RUnlock()
		}
	}
}
