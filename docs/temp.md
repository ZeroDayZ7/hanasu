### 1. Bezpieczeństwo TURN Server (Hardcoded Credentials)

- **Problem:** W `WebRtcConfig` znajdowały się zahardkodowane poświadczenia do serwera TURN (`openrelay.metered.ca`). Wyciągnięcie ich z kodu aplikacji jest banalne i grozi ich wykorzystaniem przez osoby trzecie.
- **Rozwiązanie:** Zaakceptuj pobieranie jednorazowych, tymczasowych danych logowania do serwera TURN/STUN z backendu poprzez dedykowany endpoint API (`/api/v1/turn-credentials`) z krótkim czasem życia klucza (Ephemeral Credentials).

---

### 2. Isolate JSON Parsing dla WebRTC i WebSocket

- **Problem:** Parsowanie dużych pakietów wiadomości (np. listy stanów pokojów, payloady z ramkami audio/tekstowymi) odbywa się na głównym wątku UI (Main Isolate).
- **Rozwiązanie:** Przenieś funkcję `parseSignalingMessage` na osobny wątek przy pomocy `compute()` lub `Isolate.run()`, gdy rozmiary wiadomości przekraczają kilkanaście kilobajtów.

---

<!-- ### 3. Wprowadzenie Circuit Breakers dla WebSocket -->

<!-- - **Problem:** W `WsSignalingClient` istnieje mechanizm **Exponential Backoff**, ale bez limitu prób (albo przy trwałej awarii serwera) urządzenie będzie nieustannie drenować baterię próbowaniem połączenia.
- **Rozwiązanie:** Zaimplementuj wzorzec **Circuit Breaker** (Stany: _Closed_, _Open_, _Half-Open_). Po $N$ nieudanych próbach klient wchodzi w stan _Open_ na określony czas i przestaje wysyłać zapytania sieciowe.

---

### 4. Zero-Trust Data Sanitization & Strict Validation

- **Problem:** Odbierane obiekty SDP i ICE Candidate w `sdp_negotiation.dart` są przyjmowane bez wstępnej walidacji pod kątem poprawności składniowej (możliwość uszkodzenia sesji P2P lub wywołania unhandled exception).
- **Rozwiązanie:** Waliduj strukturę obiektów SDP (np. obecność kluczowych atrybutów media) przed wywołaniem natywnych metod `setRemoteDescription`.

--- -->

### 5. Graceful Audio Interruption Management

- **Problem:** Przerywanie audio przez połączenia przychodzące GSM (incoming phone calls) lub połączenia z zestawem Bluetooth może uszkodzić stan `AudioSession`.
- **Rozwiązanie:** Dodaj nasłuchiwacze dla `session.devicesChangedEventStream` oraz `session.becomingNoisyEventStream` w `WebRtcService`, aby automatycznie pauzować wyjście audio i płynnie przełączać routing (Słuchawka/Głośnik/Bluetooth).

---

### 6. Bezpieczny Secure Storage Key-Rotation & Encrypted State

- **Problem:** Użycie `flutter_secure_storage` bez obsługi wyjątków związanych z unieważnieniem kluczy szyfrujących systemu (np. po aktualizacji systemu Android/iOS lub zmianie blokady ekranu) wywołuje ciche crashe (`BadPaddingException` / `KeyStoreException`).
- **Rozwiązanie:** Owiń operacje na `FlutterSecureStorage` w uniwersalną obsługę błędów z opcją wykrywania uszkodzonych kluczy i automatycznego czyszczenia stanu (`resetOnError: true` jest ustawione dla Androida, ale na iOS brakuje jawnej obsługi `Keychain` corruption).

---

### 7. Explicit Memory Leak Sweeps

- **Problem:** Tworzone instancje `RTCVideoRenderer` i strumienie `MediaStream` mogą pozostawiać niezwolnione uchwyty po stronie kodu C++ (WebRTC Engine), jeśli użytkownik gwałtownie zamknie ekran (`pop`).
- **Rozwiązanie:** Zaimplementuj wzorzec `Finalizer` lub wymuś pełne zamykanie w `ref.onDispose()` we wszystkich Riverpod providerach związanych z mediami i strumieniami WebRTC.

---

### 8. Strict Type-Safe WebSocket Messaging Strategy

- **Problem:** Repozytorium wiadomości operuje na mapach typu `Map<String, dynamic>` podczas wysyłania komend przez WebSocket (`_client.send(payload)`).
- **Rozwiązanie:** Zamień surowe mapy na bezklasowe / klasowe uszczelnione obiekty DTO (`sealed class OutgoingWebSocketEvent`) z automatyczną serializacją do JSON przez `Freezed`. Zapobiegnie to literówkom w kluczach JSON.

---

### 9. Offline Cache / Outbox Pattern dla Wiadomości Tekstowych

- **Problem:** W razie braku połączenia internetowego próba wysłania wiadomości tekstowej kończy się błędem lub cichym odrzuceniem w `ChatWebSocketClient`.
- **Rozwiązanie:** Zaimplementuj wzorzec **Outbox Pattern**. Wiadomości są zapisywane lokalnie w kolejsce (np. Hive / SQLite) ze stanem `MessageStatus.sending`, a po wykryciu zdarzenia `WebSocketState.connected` automatycznie opróżniane i wysyłane na serwer.

---

### 10. End-to-End Metrics & Telemetry Exporter

- **Problem:** Metryki RTP w `webrtc_stats_monitor.dart` drukowane są wyłącznie do loggera konsolek.
- **Rozwiązanie:** Agreguj parametry _Jitter_, _Packet Loss_ i _RTT_ (Round Trip Time) i przesyłaj je w postaci zbitych pakietów telemetrycznych (np. co 30 sekund) do własnego backendu monitorującego w celu wykrywania problemów z jakością połączeń sieciowych klientów.
