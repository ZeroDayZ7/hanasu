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
			h.handleRegister(client)
		case client := <-h.unregister:
			h.handleUnregister(client)
		case env := <-h.broadcast:
			h.handleBroadcast(env)
		}
	}
}

func (h *Hub) handleRegister(client *Client) {
	// 1. Zbudowanie wiadomości przed sekcją krytyczną (unikamy zbędnego CPU pod blokadą)
	selfJoinedMsg, err := json.Marshal(domain.WSMessage{
		Type:   "room_joined",
		Sender: "server",
		Payload: map[string]string{
			"my_peer_id": client.ID,
			"room_id":    client.RoomID,
		},
	})
	if err != nil {
		h.logger.Error("[hub.go -> handleRegister -> Marshal selfJoinedMsg failed]", zap.Error(err))
		return
	}

	peerJoinedMsg, err := json.Marshal(domain.WSMessage{
		Type:   "peer_joined",
		Sender: "server",
		Payload: map[string]string{
			"peer_id": client.ID,
		},
	})
	if err != nil {
		h.logger.Error("[hub.go -> handleRegister -> Marshal peerJoinedMsg failed]", zap.Error(err))
		return
	}

	h.mu.Lock()
	h.logger.Debug("[hub.go -> handleRegister -> Registering client]", zap.String("client_id", client.ID), zap.String("room_id", client.RoomID))

	room, exists := h.rooms[client.RoomID]
	if !exists {
		room = make(map[*Client]bool)
		h.rooms[client.RoomID] = room
		h.logger.Debug("[hub.go -> handleRegister -> Created new room entry in memory]", zap.String("room_id", client.RoomID))
	}

	// 2. Wysłanie potwierdzenia rejestracji z `my_peer_id` do samego siebie
	h.trySend(client, selfJoinedMsg, "self_room_joined")

	// 3. Wymiana powiadomień z istniejącymi klientami
	for existingClient := range room {
		// Powiadom istniejącego klienta o nowym peerze
		h.trySend(existingClient, peerJoinedMsg, "existing_peer_joined")

		// Powiadom nowego klienta o istniejącym peerze
		existingPeerMsg, _ := json.Marshal(domain.WSMessage{
			Type:   "peer_joined",
			Sender: "server",
			Payload: map[string]string{
				"peer_id": existingClient.ID,
			},
		})
		h.trySend(client, existingPeerMsg, "new_client_peer_joined")
	}

	room[client] = true
	h.mu.Unlock()

	h.logger.Info("[hub.go -> handleRegister -> Client registered successfully]",
		zap.String("room_id", client.RoomID),
		zap.String("client_id", client.ID),
	)
}

func (h *Hub) handleUnregister(client *Client) {
	h.mu.Lock()
	h.logger.Debug("[hub.go -> handleUnregister -> Unregistering client]", zap.String("client_id", client.ID), zap.String("room_id", client.RoomID))

	clients, ok := h.rooms[client.RoomID]
	if !ok {
		h.mu.Unlock()
		return
	}

	if _, exists := clients[client]; exists {
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
			h.trySend(remainingClient, notifyLeft, "peer_left")
		}
	}

	if len(clients) == 0 {
		delete(h.rooms, client.RoomID)
		h.logger.Debug("[hub.go -> handleUnregister -> Room emptied and removed]", zap.String("room_id", client.RoomID))
	}
	h.mu.Unlock()

	h.logger.Info("[hub.go -> handleUnregister -> Client unregistered successfully]",
		zap.String("room_id", client.RoomID),
		zap.String("client_id", client.ID),
	)
}

func (h *Hub) handleBroadcast(env MessageEnvelope) {
	h.mu.RLock()
	defer h.mu.RUnlock()

	h.logger.Debug("[hub.go -> handleBroadcast -> Broadcasting message in room]", zap.String("room_id", env.RoomID))

	clients, ok := h.rooms[env.RoomID]
	if !ok {
		return
	}

	for client := range clients {
		if client != env.Sender {
			h.trySend(client, env.Data, "broadcast_dispatch")
		}
	}
}

// trySend to bezpieczny wrapper zapobiegający blokowaniu pętli głównej w przypadku pełnego kanału.
func (h *Hub) trySend(client *Client, data []byte, actionContext string) bool {
	select {
	case client.Send <- data:
		h.logger.Debug("[hub.go -> trySend -> Message dispatched]",
			zap.String("client_id", client.ID),
			zap.String("context", actionContext),
		)
		return true
	default:
		h.logger.Warn("[hub.go -> trySend -> Client buffer full, message dropped]",
			zap.String("client_id", client.ID),
			zap.String("context", actionContext),
		)
		return false
	}
}
