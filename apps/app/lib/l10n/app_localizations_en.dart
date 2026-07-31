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
  String get roomInputHint => 'e.g. xyz15';

  @override
  String get roomInputSubtitle => 'Enter room code or generate a new one';

  @override
  String get connectButton => 'CONNECT';

  @override
  String get createRoomButton => 'CREATE ROOM';

  @override
  String get copyCodeTooltip => 'Copy code';

  @override
  String codeCopiedSnackBar(String pin) {
    return 'Room code copied to clipboard: $pin';
  }

  @override
  String connectingToRoom(String pin) {
    return 'Connecting to room $pin...';
  }
}
