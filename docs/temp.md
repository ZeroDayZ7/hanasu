Rozumiem, z czym się zmagasz. Błędy związane z WebRTC, cyklem życia nawigacji w we Flutterze oraz komunikacją w czasie rzeczywistym bywają niezwykle uciążliwe. Twoje problemy wynikają z kilku klasycznych pułapek: wycieku efektów ubocznych (side-effects) do metody `build`, błędnej konfiguracji mapy ograniczeń WebRTC oraz brakujących deklaracji w klasach stanu i kontrolerach.

Zarządzanie zasobami przy strumieniach audio i WebSocketach wymaga deterministycznego podejścia. Dodatkowo, zamiast zamykać całą logikę w potężnych klasach typu `WebRtcService`, warto przejść na bardziej funkcyjne podejście, eksportując niezależne funkcje tam, gdzie to możliwe, co ułatwi testowanie i zapobiegnie wyciekom pamięci.

Przejdźmy do konkretów. Najpierw naprawimy krytyczne błędy, a następnie rozpiszemy 20-punktowy plan refaktoryzacji.

### 🛠️ Natychmiastowe naprawy błędów

#### 1. Błąd wielokrotnej nawigacji (4x push na Androidzie)

**Przyczyna:** W `RoomScreen` sprawdzasz stan `activeRoomId` bezpośrednio w ciele metody `build` i wywołujesz `WidgetsBinding.instance.addPostFrameCallback`. Przy każdej zmianie stanu (lub odświeżeniu UI), Flutter ponownie wykonuje ten blok i wrzuca kolejny ekran na stos.
**Rozwiązanie:** Użyj `ref.listen` do nasłuchiwania zmian stanu poza cyklem renderowania widoku.

**Zmień w `room_screen.dart`:**
Usuń blok `if (roomState.activeRoomId.isNotEmpty) { ... }` z początku metody `build` i dodaj nasłuchiwanie bezpośrednio pod deklaracją `ref.watch`:

```dart
  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(roomControllerProvider);

    // Poprawna obsługa nawigacji jako efektu ubocznego
    ref.listen<RoomState>(roomControllerProvider, (previous, next) {
      if (next.activeRoomId.isNotEmpty && previous?.activeRoomId != next.activeRoomId) {
        _navigateToSession(next.activeRoomId);
      }
    });

    if (roomState.isCheckingSession) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // ... reszta kodu

```

#### 2. Cyfrowe świsty, echo i własny głos na Androidzie

**Przyczyna:** Słownik `_mediaConstraints` w Dart oczekuje wartości typu `bool` (np. `true`), a nie ciągów znaków (`'true'`). Przez to sprzętowe usuwanie echa (AEC) nie jest uruchamiane. Ponadto metoda `Helper.setSpeakerphoneOn(true)` wymusza głośnik estradowy, co powoduje fizyczne sprzężenie zwrotne (mikrofon zbiera dźwięk z głośnika).

**Zmień w `webrtc_service.dart`:**

```dart
  final Map<String, dynamic> _mediaConstraints = {
    'audio': {
      'mandatory': {
        'echoCancellation': true, // Zmieniono z 'true' na true
        'noiseSuppression': true, // Zmieniono z 'true' na true
        'autoGainControl': true,  // Zmieniono z 'true' na true
      },
      'optional': [],
    },
    'video': false,
  };

```

Oraz wyłącz stałe wymuszanie głośnika. Pozwól systemowi (lub użytkownikowi przyciskiem) decydować o wyjściu audio:

```dart
    _peerConnection!.onTrack = (RTCTrackEvent event) {
      // ...
      if (event.track.kind == 'audio') {
        event.track.enabled = true;

        // ZAKOMENTUJ LUB USUŃ TO:
        // Helper.setSpeakerphoneOn(true);

```

#### 3. Braki w `RoomController` i `RoomState` (Błędy z analizatora)

Twoje widoki odwołują się do metod i właściwości, których nie zdefiniowałeś w `RoomController`.

**Zmień w `room_controller.dart`:**
Dodaj pole `isCheckingSession` do stanu i zaimplementuj brakujące metody będące aliasami lub implementacjami dla UI:

```dart
class RoomState {
  final bool isLoading;
  final bool isCheckingSession; // Dodano
  final String activeRoomId;
  final List<ChatRoom> rooms;
  final String? errorMessage;

  const RoomState({
    this.isLoading = true,
    this.isCheckingSession = false, // Dodano
    this.activeRoomId = '',
    this.rooms = const [],
    this.errorMessage,
  });

  RoomState copyWith({
    bool? isLoading,
    bool? isCheckingSession,
    String? activeRoomId,
    List<ChatRoom>? rooms,
    String? errorMessage,
  }) {
    return RoomState(
      isLoading: isLoading ?? this.isLoading,
      isCheckingSession: isCheckingSession ?? this.isCheckingSession,
      activeRoomId: activeRoomId ?? this.activeRoomId,
      rooms: rooms ?? this.rooms,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

```

Dodaj te metody w klasie `RoomController`:

```dart
  String generateNewCode() {
    return generateRoomCode();
  }

  Future<void> saveRoom(String pin) async {
    await saveActiveRoom(pin);
  }

  Future<void> clearRoom() async {
    await clearActiveRoom();
  }

```

---

### 📋 20-punktowa profesjonalna lista refaktoryzacyjna

Poniżej znajduje się rygorystyczny plan uporządkowania architektury i naprawy fundamentalnych problemów z kodem.

**Architektura i Podejście Funkcyjne**

1. **Rozbicie klas serwisowych:** Wyodrębnij logikę negocjacji SDP (Offer/Answer) z `WebRtcService` do samodzielnych asynchronicznych funkcji (np. `export async function createSdpOffer(...)`), aby uniknąć przetrzymywania stanu w "boskim obiekcie".
2. **Czyste funkcje mapujące:** Przenieś deserializację WebSocketów (np. `_handleIncomingMessage`) do niezależnych, testowalnych funkcji, które przyjmują surowy `String` i zwracają szczelnie zdefiniowane typy `WebSocketEvent`.
3. **Funkcyjne wstrzykiwanie zależności:** Zamiast przechowywać `AppLogger` i `SignalingClient` jako wewnętrzne pola klasy stanu, przekazuj je wyłącznie jako argumenty do czystych funkcji wykonawczych, zachowując kontroler Riverpod jedynie do zarządzania mutacją stanu.

**Zarządzanie stanem i Riverpod** 4. **Migracja na AsyncNotifier:** Zastąp standardowy `Notifier` z flagą `isLoading` wbudowanym `AsyncNotifier` dla `RoomController`, co zredukuje ilość kodu blokowego i ujednolici obsługę błędów / ładowania. 5. **Eliminacja efektów ubocznych w interfejsie:** Zastosuj wzorzec Event/Action w kontrolerach. Interfejs użytkownika nie powinien wołać bezpośrednio repozytoriów ani samodzielnie czyścić stosu wywołań. 6. **Rozdzielenie providerów:** Podziel `sessionControllerProvider` na mniejsze fragmenty (np. osobny provider dla stanu czatu, osobny dla strumienia audio), aby uniknąć przebudowywania całego ekranu czatu przy każdej nowej wiadomości.

**Nawigacja (GoRouter)** 7. **Wdrożenie deklaratywnego routingu:** Zainstaluj i skonfiguruj `go_router`. Użyj ścieżek opartych na URI (np. `/room/:id`), co automatycznie rozwiąże problem ze stosem (używając `context.go` zamiast `Navigator.push`). 8. **Deep Linking:** Dzięki `go_router` bez problemu zaimplementujesz wchodzenie do pokojów za pomocą linków webowych dzielonych ze znajomymi (np. aplikacja przechwytuje URL i parsuje PIN).

**WebRTC i optymalizacja zasobów** 9. **Polityka cyklu życia streamu:** Zaimplementuj ścisłe ubijanie (`dispose`) dla `MediaStreamTrack` bezpośrednio przy opuszczaniu pokoju. Zapobiegnie to pozostawieniu włączonej diody mikrofonu w systemie operacyjnym. 10. **Zarządzanie urządzeniami wejścia/wyjścia:** Dodaj system wykrywania podłączonych słuchawek. Jeśli użytkownik nie ma słuchawek, domyślnie redukuj wzmocnienie mikrofonu (Gain Control), aby zminimalizować ryzyko pisków. 11. **Izolacja kolejki ICE Candidates:** Obecnie przechowujesz `_pendingIceCandidates` w mutowalnej tablicy. Warto zaimplementować to jako rekreowany Rx/Stream, aby wyeliminować błędy wyścigu (race conditions) pomiędzy SDP a ICE. 12. **Mute vs Disable track:** Aby inni nie słyszeli użytkownika, gdy ten na to nie pozwala, wyłączaj `enabled = false` na obiekcie `audioTrack`, zamiast odcinać wysyłanie pakietów RTP w całości – utrzymuje to połączenie P2P przy życiu.

**Sieć i WebSockety** 13. **Exponential Backoff dla WebSocket:** Zmień sztywny timer `Timer.periodic(3s)` na rosnący czas opóźnienia z pewnym stopniem losowości (jitter), aby po restarcie serwera wszyscy klienci nie zablokowali go jednoczesną próbą połączenia. 14. **Generator kodu dla JSON:** Porzuć ręczne pisanie mapowania `fromJson` (które widać w modelach). Wykorzystaj pakiety `freezed` oraz `json_serializable`, aby zapewnić bezpieczeństwo typów (type-safety) w czasie kompilacji. 15. **Walidacja schematów:** Zanim strumień z gniazda przetworzy payload z czatu, przepuść go przez warstwę walidacyjną (np. sprawdzającą kompletność kluczy id, author_id), żeby zapobiec rzucaniu błędami na poziomie UI.

**Inżynieria UI/UX** 16. **Debouncing akcji dołączenia:** Dodaj mechanizm zabezpieczający (debounce) na przyciski łączące do pokoju, aby podwójne szybkie tapnięcie w ekran nie wysyłało dwóch pakietów inicjujących (co obecnie generuje błąd podwójnego połączenia do bazy / RTC). 17. **Abstrakcja schowka:** Wyrzuć logikę `ClipboardData` z interfejsu (widgetu) do niezależnego serwisu wstrzykiwanego przez Riverpod. Interfejs powinien jedynie wywołać funkcję, a serwis obsłużyć schowek i wyemitować powiadomienie (SnackBar) z użyciem globalnego klucza `ScaffoldMessengerKey`. 18. **Ujednolicenie palety kolorów:** Wydziel tokeny kolorów (np. `Color(0xFF6366F1)`) bezpośrednio do niestandardowego motywu bazowego `ThemeExtension`, aby móc nimi dynamicznie sterować i nie twardo kodować wartości HEX w widgetach.

**Błędy Domeny (Naprawa pozostałych ostrzeżeń LSP)** 19. **Domena ChatMessage:** W pliku `chat_message.dart` musisz zdefiniować enum `MessageSource` (np. `user`, `system`, `remote`) oraz dodać pole `source` i `translatedText` do konstruktora, by naprawić zgłoszone błędy z `chat_message_list.dart`. 20. **Definicja SessionController:** W widoku sesji wywołujesz konstruktor dostarczając same argumenty (np. `SessionController(roomId: ..., authorId: ..., authorNick: ...)`), ale plik ten jest źle skonfigurowany pod kątem Riverpod – musisz ujednolicić sygnaturę metody `build()` w generatorze kodu (np. `@riverpod class SessionController extends _$SessionController`).

---

Dzięki poprawie `_mediaConstraints` i nawigacji powinieneś od razu zauważyć, że podstawowa część czatu i audio funkcjonuje sprawnie.

Analizator kodu wskazuje jednak na braki w plikach modelu i kontrolera sesji (`undefined_named_parameter 'source'`, `missing_required_argument 'authorId'`). Czy możesz udostępnić aktualny kod modeli `ChatMessage` oraz klasę `SessionController`, abym mógł dostarczyć Ci dokładne, zaktualizowane implementacje dla tych plików?
