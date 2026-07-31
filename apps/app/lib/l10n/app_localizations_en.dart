// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'HANASU :: P2P VOICE';

  @override
  String get roomInputHint => 'e.g., xyz15';

  @override
  String get roomInputSubtitle => 'Enter a room code or generate a new one';

  @override
  String get connectButton => 'CONNECT';

  @override
  String get createRoomButton => 'CREATE ROOM';

  @override
  String get copyCodeTooltip => 'Copy code';

  @override
  String codeCopiedSnackBar(String pin) {
    return 'Copied room code to clipboard: $pin';
  }

  @override
  String connectingToRoom(String pin) {
    return 'Connecting to room $pin...';
  }

  @override
  String roomTitle(String roomId) {
    return 'ROOM: $roomId';
  }

  @override
  String peerJoined(String peerId) {
    return 'Peer $peerId joined the room';
  }

  @override
  String get peerLeft => 'Peer left the room';

  @override
  String get statusDisconnected => 'Disconnected';

  @override
  String get statusConnecting => 'Connecting to server...';

  @override
  String statusConnectedWithPeer(String peerId) {
    return 'Connected to: $peerId';
  }

  @override
  String get statusWaitingForPeer => 'Waiting for peer...';

  @override
  String get statusError => 'Connection error!';
}
