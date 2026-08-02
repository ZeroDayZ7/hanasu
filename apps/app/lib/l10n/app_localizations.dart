import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('pl'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'HANASU :: P2P VOICE'**
  String get appTitle;

  /// No description provided for @roomInputHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., xyz15'**
  String get roomInputHint;

  /// No description provided for @roomInputSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a room code or generate a new one'**
  String get roomInputSubtitle;

  /// No description provided for @connectButton.
  ///
  /// In en, this message translates to:
  /// **'CONNECT'**
  String get connectButton;

  /// No description provided for @createRoomButton.
  ///
  /// In en, this message translates to:
  /// **'CREATE ROOM'**
  String get createRoomButton;

  /// No description provided for @copyCodeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get copyCodeTooltip;

  /// No description provided for @codeCopiedSnackBar.
  ///
  /// In en, this message translates to:
  /// **'Copied room code to clipboard: {pin}'**
  String codeCopiedSnackBar(String pin);

  /// No description provided for @connectingToRoom.
  ///
  /// In en, this message translates to:
  /// **'Connecting to room {pin}...'**
  String connectingToRoom(String pin);

  /// No description provided for @micEnabled.
  ///
  /// In en, this message translates to:
  /// **'Microphone: ON'**
  String get micEnabled;

  /// No description provided for @micMuted.
  ///
  /// In en, this message translates to:
  /// **'Microphone: MUTED'**
  String get micMuted;

  /// No description provided for @roomTitle.
  ///
  /// In en, this message translates to:
  /// **'ROOM: {roomId}'**
  String roomTitle(String roomId);

  /// No description provided for @peerJoined.
  ///
  /// In en, this message translates to:
  /// **'Peer {peerId} joined the room'**
  String peerJoined(String peerId);

  /// No description provided for @peerLeft.
  ///
  /// In en, this message translates to:
  /// **'Peer left the room'**
  String get peerLeft;

  /// No description provided for @statusDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get statusDisconnected;

  /// No description provided for @statusConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to server...'**
  String get statusConnecting;

  /// No description provided for @statusConnectedWithPeer.
  ///
  /// In en, this message translates to:
  /// **'Connected to: {peerId}'**
  String statusConnectedWithPeer(String peerId);

  /// No description provided for @statusWaitingForPeer.
  ///
  /// In en, this message translates to:
  /// **'Waiting for peer...'**
  String get statusWaitingForPeer;

  /// No description provided for @statusError.
  ///
  /// In en, this message translates to:
  /// **'Connection error!'**
  String get statusError;

  /// No description provided for @createRoomLabel.
  ///
  /// In en, this message translates to:
  /// **'Room name'**
  String get createRoomLabel;

  /// No description provided for @createRoomHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a name for the new room'**
  String get createRoomHint;

  /// No description provided for @noRoomsMessage.
  ///
  /// In en, this message translates to:
  /// **'No rooms yet. Create one to start chatting.'**
  String get noRoomsMessage;

  /// No description provided for @joinRoomLabel.
  ///
  /// In en, this message translates to:
  /// **'Room code'**
  String get joinRoomLabel;

  /// No description provided for @joinRoomHint.
  ///
  /// In en, this message translates to:
  /// **'Enter existing room code'**
  String get joinRoomHint;

  /// No description provided for @profileNickLabel.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get profileNickLabel;

  /// No description provided for @profileNickHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your display name'**
  String get profileNickHint;

  /// No description provided for @serverUnreachableError.
  ///
  /// In en, this message translates to:
  /// **'Server unreachable. Please check your connection.'**
  String get serverUnreachableError;

  /// No description provided for @retryAction.
  ///
  /// In en, this message translates to:
  /// **'RETRY'**
  String get retryAction;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
