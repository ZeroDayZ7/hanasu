package config

import (
	"os"

	"server/pkg/logger"

	"go.uber.org/zap"
)

type Config struct {
	Env                 string
	Port                string
	TranslationProvider string
	OllamaURL           string
	OpenAIAPIKey        string
}

func LoadConfig() Config {
	env := os.Getenv("APP_ENV")
	if env == "" {
		env = os.Getenv("ENV")
	}
	if env == "" {
		env = "development"
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	provider := os.Getenv("TRANSLATION_PROVIDER")
	if provider == "" {
		provider = "local"
	}

	ollamaURL := os.Getenv("OLLAMA_URL")
	if ollamaURL == "" {
		ollamaURL = "http://localhost:11434"
	}

	openAIKey := os.Getenv("OPENAI_API_KEY")

	cfg := Config{
		Env:                 env,
		Port:                port,
		TranslationProvider: provider,
		OllamaURL:           ollamaURL,
		OpenAIAPIKey:        openAIKey,
	}

	// 1. Logowanie informacji o wczytanej konfiguracji
	hasOpenAIKey := openAIKey != ""
	logger.Debug("Załadowano konfigurację",
		zap.String("env", cfg.Env),
		zap.String("port", cfg.Port),
		zap.String("provider", cfg.TranslationProvider),
		zap.String("ollama_url", cfg.OllamaURL),
		zap.Bool("has_openai_key", hasOpenAIKey),
	)

	return cfg
}
