// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'HANASU :: P2P VOICE';

  @override
  String get roomInputHint => '例: xyz15';

  @override
  String get roomInputSubtitle => 'ルームコードを入力するか新しく作成します';

  @override
  String get connectButton => '接続';

  @override
  String get createRoomButton => 'ルーム作成';

  @override
  String get copyCodeTooltip => 'コードをコピー';

  @override
  String codeCopiedSnackBar(String pin) {
    return 'ルームコードをクリップボードにコピーしました: $pin';
  }

  @override
  String connectingToRoom(String pin) {
    return 'ルーム $pin に接続中...';
  }
}
