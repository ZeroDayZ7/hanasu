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
  String get roomInputSubtitle => 'ルームコードを入力するか、新規生成してください';

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

  @override
  String get micEnabled => 'マイク：オン';

  @override
  String get micMuted => 'マイク：ミュート';

  @override
  String roomTitle(String roomId) {
    return 'ルーム: $roomId';
  }

  @override
  String peerJoined(String peerId) {
    return 'ピア $peerId が参加しました';
  }

  @override
  String get peerLeft => 'ピアが退出しました';

  @override
  String get statusDisconnected => '切断済み';

  @override
  String get statusConnecting => 'サーバーに接続中...';

  @override
  String statusConnectedWithPeer(String peerId) {
    return '接続先: $peerId';
  }

  @override
  String get statusWaitingForPeer => '相手の接続を待機中...';

  @override
  String get statusError => '接続エラー！';
}
