package main

import (
	"net/http"

	"server/config"
	"server/pkg/logger"
	"server/provider"
	"server/transport/ws"

	"go.uber.org/zap"
)

func main() {
	cfg := config.LoadConfig()

	// 1. Inicjalizacja globalnego loggera
	logger.Init(cfg.Env)

	logger.Info("Inicjalizacja aplikacji...", zap.String("env", cfg.Env))

	// 2. Inicjalizacja dostawcy tłumaczeń
	translatorProvider, err := provider.NewTranslator(cfg)
	if err != nil {
		logger.Fatal("Błąd inicjalizacji dostawcy tłumaczeń", zap.Error(err))
	}

	// 3. Uruchomienie Hub'a WebSocket
	hub := ws.NewHub()
	go hub.Run()

	// 4. Endpoints
	http.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		logger.Debug("Nowe żądanie HTTP WebSocket", zap.String("remote_addr", r.RemoteAddr))
		ws.ServeWS(hub, translatorProvider, w, r)
	})

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("OK"))
	})

	// 5. Start serwera HTTP
	logger.Info("Serwer WebSocket / Signaling uruchomiony",
		zap.String("port", cfg.Port),
		zap.String("provider", cfg.TranslationProvider),
	)

	if err := http.ListenAndServe(":"+cfg.Port, nil); err != nil {
		logger.Fatal("Błąd uruchamiania serwera", zap.Error(err))
	}
}
