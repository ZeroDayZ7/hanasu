package provider

import (
	"context"
	"fmt"
	"server/domain"
)

type LocalProvider struct {
	Endpoint string
}

func NewLocalProvider(endpoint string) *LocalProvider {
	return &LocalProvider{Endpoint: endpoint}
}

func (p *LocalProvider) Translate(ctx context.Context, req domain.TranslationRequest) (*domain.TranslationResponse, error) {
	// Miejsce na wywołanie lokalnego modelu (np. Ollama / Whisper + LLM)
	translated := fmt.Sprintf("[%s -> %s] (LOCAL) %s", req.SourceLang, req.TargetLang, req.Text)
	return &domain.TranslationResponse{
		TranslatedText: translated,
		Provider:       "local",
	}, nil
}

func (p *LocalProvider) StreamTranslate(ctx context.Context, req domain.TranslationRequest, ch chan<- string) error {
	defer close(ch)
	ch <- fmt.Sprintf("(Local Stream) %s", req.Text)
	return nil
}
