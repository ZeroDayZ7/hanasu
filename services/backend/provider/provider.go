package provider

import (
	"fmt"
	"server/config"
	"server/domain"
)

func NewTranslator(cfg config.Config) (domain.Translator, error) {
	switch cfg.TranslationProvider {
	case "local":
		return NewLocalProvider(cfg.OllamaURL), nil
	case "openai":
		return NewOpenAIProvider(cfg.OpenAIAPIKey), nil
	default:
		return nil, fmt.Errorf("nieobsługiwany provider tłumaczeń: %s", cfg.TranslationProvider)
	}
}
