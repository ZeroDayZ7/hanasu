package provider

import (
	"context"
	"fmt"
	"server/domain"
)

type OpenAIProvider struct {
	APIKey string
}

func NewOpenAIProvider(apiKey string) *OpenAIProvider {
	return &OpenAIProvider{APIKey: apiKey}
}

func (p *OpenAIProvider) Translate(ctx context.Context, req domain.TranslationRequest) (*domain.TranslationResponse, error) {
	translated := fmt.Sprintf("[%s -> %s] (OPENAI) %s", req.SourceLang, req.TargetLang, req.Text)
	return &domain.TranslationResponse{
		TranslatedText: translated,
		Provider:       "openai",
	}, nil
}

func (p *OpenAIProvider) StreamTranslate(ctx context.Context, req domain.TranslationRequest, ch chan<- string) error {
	defer close(ch)
	ch <- fmt.Sprintf("(OpenAI Stream) %s", req.Text)
	return nil
}
