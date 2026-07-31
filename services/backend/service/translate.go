package service

import (
	"context"
	"errors"
	"server/domain"
)

// ProcessTranslation wykonuje tłumaczenie używając podanego dostawcy
func ProcessTranslation(ctx context.Context, t domain.Translator, req domain.TranslationRequest) (*domain.TranslationResponse, error) {
	if req.Text == "" {
		return nil, errors.New("pusty tekst do tłumaczenia")
	}
	return t.Translate(ctx, req)
}

// StreamTranslation strumieniuje tłumaczenie do kanału
func StreamTranslation(ctx context.Context, t domain.Translator, req domain.TranslationRequest, ch chan<- string) error {
	if req.Text == "" {
		close(ch)
		return errors.New("pusty tekst do tłumaczenia")
	}
	return t.StreamTranslate(ctx, req, ch)
}
