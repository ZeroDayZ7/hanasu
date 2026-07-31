// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'HANASU :: P2P VOICE';

  @override
  String get roomInputHint => 'np. xyz15';

  @override
  String get roomInputSubtitle => 'Wpisz kod pokoju lub wygeneruj nowy';

  @override
  String get connectButton => 'POŁĄCZ';

  @override
  String get createRoomButton => 'STWÓRZ POKÓJ';

  @override
  String get copyCodeTooltip => 'Kopiuj kod';

  @override
  String codeCopiedSnackBar(String pin) {
    return 'Skopiowano kod pokoju do schowka: $pin';
  }

  @override
  String connectingToRoom(String pin) {
    return 'Łączenie z pokojem $pin...';
  }

  @override
  String roomTitle(String roomId) {
    return 'POKÓJ: $roomId';
  }

  @override
  String peerJoined(String peerId) {
    return 'Peer $peerId dołączył do pokoju';
  }

  @override
  String get peerLeft => 'Peer opuścił pokój';

  @override
  String get statusDisconnected => 'Rozłączono';

  @override
  String get statusConnecting => 'Łączenie z serwerem...';

  @override
  String statusConnectedWithPeer(String peerId) {
    return 'Połączono z: $peerId';
  }

  @override
  String get statusWaitingForPeer => 'Oczekiwanie na drugiego użytkownika...';

  @override
  String get statusError => 'Błąd połączenia!';
}
