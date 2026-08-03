package main

import (
	"context"
	"errors"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

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

	mux := http.NewServeMux()

	mux.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		logger.Debug("New HTTP WebSocket request", zap.String("remote_addr", r.RemoteAddr))
		ws.ServeWS(logger.Get(), hub, translatorProvider, w, r)
	})

	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		if hub == nil {
			w.WriteHeader(http.StatusServiceUnavailable)
			_, _ = w.Write([]byte("HUB_UNAVAILABLE"))
			return
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"status":"UP","websocket":"ready"}`))
	})

	srv := &http.Server{
		Addr:         "0.0.0.0:" + cfg.Port,
		Handler:      mux,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	go func() {
		logger.Info("WebSocket / Signaling server started",
			zap.String("port", cfg.Port),
			zap.String("provider", cfg.TranslationProvider),
		)
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			logger.Fatal("Failed to start server", zap.Error(err))
		}
	}()

	// Graceful Shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	logger.Info("Shutting down server gracefully...")

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		logger.Fatal("Server forced to shutdown", zap.Error(err))
	}

	logger.Info("Server stopped cleanly")
}
