// services/backend/domain/translation.go
package domain

import "context"

type TranslationRequest struct {
	Text       string `json:"text"`
	SourceLang string `json:"source_lang"`
	TargetLang string `json:"target_lang"`
}

type TranslationResponse struct {
	TranslatedText string `json:"translated_text"`
	Provider       string `json:"provider"`
}

type Translator interface {
	Translate(ctx context.Context, req TranslationRequest) (*TranslationResponse, error)
	StreamTranslate(ctx context.Context, req TranslationRequest, ch chan<- string) error
}

type WSMessage struct {
	Type    string `json:"type"`
	Sender  string `json:"sender"`
	Target  string `json:"target,omitempty"`
	Payload any    `json:"payload,omitempty"`
}
