package config

import (
	"os"
)

type Config struct {
	Port                string
	TranslationProvider string // np. "local", "openai"
	OllamaURL           string
	OpenAIAPIKey        string
}

func LoadConfig() Config {
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

	return Config{
		Port:                port,
		TranslationProvider: provider,
		OllamaURL:           ollamaURL,
		OpenAIAPIKey:        os.Getenv("OPENAI_API_KEY"),
	}
}
