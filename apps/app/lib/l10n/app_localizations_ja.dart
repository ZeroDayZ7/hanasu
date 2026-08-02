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
    return 'クリップボードにコードをコピーしました: $pin';
  }

  @override
  String connectingToRoom(String pin) {
    return 'ルーム $pin に接続中...';
  }

  @override
  String get micEnabled => 'マイク: オン';

  @override
  String get micMuted => 'マイク: ミュート';

  @override
  String roomTitle(String roomId) {
    return 'ルーム: $roomId';
  }

  @override
  String peerJoined(String peerId) {
    return 'ユーザー $peerId が参加しました';
  }

  @override
  String get peerLeft => 'ユーザーが退出しました';

  @override
  String get statusDisconnected => '切断されました';

  @override
  String get statusConnecting => 'サーバーに接続中...';

  @override
  String statusConnectedWithPeer(String peerId) {
    return '接続先: $peerId';
  }

  @override
  String get statusWaitingForPeer => '相手の参加を待っています...';

  @override
  String get statusError => '接続エラー！';

  @override
  String get createRoomLabel => 'ルーム名';

  @override
  String get createRoomHint => '新しいルーム名を入力してください';

  @override
  String get noRoomsMessage => 'ルームがありません。作成してチャットを開始してください。';

  @override
  String get joinRoomLabel => 'ルームコード';

  @override
  String get joinRoomHint => '既存のルームコードを入力してください';

  @override
  String get profileNickLabel => 'ニックネーム';

  @override
  String get profileNickHint => '表示名を入力してください';

  @override
  String get serverUnreachableError => 'サーバーに接続できません。通信状態を確認してください。';

  @override
  String get retryAction => '再試行';
}
