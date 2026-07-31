# Hanasu

System tłumaczenia mowy w czasie rzeczywistym przez sieć P2P / Tailscale z wykorzystaniem syntezy mowy Sherpa-ONNX.

## Struktura projektu

- `apps/` - Aplikacje klienckie (np. Flutter)
- `services/backend/` - Serwis brokerski / API (obsługa pokojów PIN i tłumaczeń)
- `services/tts-engine/` - Silnik syntezy mowy Sherpa-ONNX w Dockerze
- `data/` - Przechowywanie lokalnych modeli i plików wyjściowych (ignorowane przez Git)

## Uruchomienie środowiska

```bash
docker compose up -d --build
