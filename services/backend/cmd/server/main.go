package main

import (
	"fmt"
	"log"
	"net/http"

	"server/config"
	"server/provider"
	"server/transport/ws"
)

func main() {
	cfg := config.LoadConfig()

	// Inicjalizacja wybranego dostawcy tłumaczeń
	translatorProvider, err := provider.NewTranslator(cfg)
	if err != nil {
		log.Fatalf("Błąd inicjalizacji dostawcy tłumaczeń: %v", err)
	}

	// Uruchomienie Hub'a WebSocket
	hub := ws.NewHub()
	go hub.Run()

	// Endpoints
	http.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		ws.ServeWS(hub, translatorProvider, w, r)
	})

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	fmt.Printf("🌐 Serwer WebSocket / Signaling uruchomiony na porcie %s (Provider: %s)...\n", cfg.Port, cfg.TranslationProvider)
	if err := http.ListenAndServe(":"+cfg.Port, nil); err != nil {
		log.Fatalf("Błąd uruchamiania serwera: %v", err)
	}
}
