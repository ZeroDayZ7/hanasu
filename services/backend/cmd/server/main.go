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

	logger.Init(cfg.Env)

	logger.Info("Initializing application...", zap.String("env", cfg.Env))

	translatorProvider, err := provider.NewTranslator(cfg)
	if err != nil {
		logger.Fatal("Failed to initialize translation provider", zap.Error(err))
	}

	hub := ws.NewHub(logger.Get())
	go hub.Run()

	http.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		logger.Debug("New HTTP WebSocket request", zap.String("remote_addr", r.RemoteAddr))
		ws.ServeWS(logger.Get(), hub, translatorProvider, w, r)
	})

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		if hub == nil {
			w.WriteHeader(http.StatusServiceUnavailable)
			_, _ = w.Write([]byte("HUB_UNAVAILABLE"))
			return
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"status":"UP","websocket":"ready"}`))
	})

	logger.Info("WebSocket / Signaling server started",
		zap.String("port", cfg.Port),
		zap.String("provider", cfg.TranslationProvider),
	)

	if err := http.ListenAndServe("0.0.0.0:"+cfg.Port, nil); err != nil {
		logger.Fatal("Failed to start server", zap.Error(err))
	}
}
