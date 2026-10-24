import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

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
    Locale('ko'),
  ];

  /// No description provided for @homeScreenTapToStart.
  ///
  /// In ko, this message translates to:
  /// **'터치하세요!'**
  String get homeScreenTapToStart;

  /// No description provided for @gameListScreenTitle.
  ///
  /// In ko, this message translates to:
  /// **'게임 목록'**
  String get gameListScreenTitle;

  /// No description provided for @game01Title.
  ///
  /// In ko, this message translates to:
  /// **'둥실둥실'**
  String get game01Title;

  /// No description provided for @game01Description.
  ///
  /// In ko, this message translates to:
  /// **'풍선이 하늘로 올라가기 전에 터뜨리세요!'**
  String get game01Description;

  /// No description provided for @game01BestScore.
  ///
  /// In ko, this message translates to:
  /// **'최고 기록 : {score} / {levelCount} 단계 클리어'**
  String game01BestScore(int score, int levelCount);

  /// No description provided for @game02Title.
  ///
  /// In ko, this message translates to:
  /// **'구구단을 외자'**
  String get game02Title;

  /// No description provided for @game02Description.
  ///
  /// In ko, this message translates to:
  /// **'구구단 정답 풍선을 터뜨리세요!'**
  String get game02Description;

  /// No description provided for @game02BestScore.
  ///
  /// In ko, this message translates to:
  /// **'최고 기록 : {score}개 정답'**
  String game02BestScore(int score);

  /// No description provided for @game03Title.
  ///
  /// In ko, this message translates to:
  /// **'사칙연산'**
  String get game03Title;

  /// No description provided for @game03Description.
  ///
  /// In ko, this message translates to:
  /// **'사칙연산 정답 풍선을 터뜨리세요!'**
  String get game03Description;

  /// No description provided for @game03BestScore.
  ///
  /// In ko, this message translates to:
  /// **'최고 기록 : {score}개 정답'**
  String game03BestScore(int score);

  /// No description provided for @gameListScreenNoRecord.
  ///
  /// In ko, this message translates to:
  /// **'기록 없음'**
  String get gameListScreenNoRecord;

  /// No description provided for @baseGameStateAdTimeTitle.
  ///
  /// In ko, this message translates to:
  /// **'광고타임!'**
  String get baseGameStateAdTimeTitle;

  /// No description provided for @baseGameStateAdTimeMessage.
  ///
  /// In ko, this message translates to:
  /// **'확인 버튼을 눌러주세요.'**
  String get baseGameStateAdTimeMessage;

  /// No description provided for @baseGameStateConfirmButton.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get baseGameStateConfirmButton;

  /// No description provided for @baseGameStatePauseTitle.
  ///
  /// In ko, this message translates to:
  /// **'일시정지 ⏸️'**
  String get baseGameStatePauseTitle;

  /// No description provided for @baseGameStatePauseMessage.
  ///
  /// In ko, this message translates to:
  /// **'게임을 중단하시겠습니까?'**
  String get baseGameStatePauseMessage;

  /// No description provided for @baseGameStateQuitButton.
  ///
  /// In ko, this message translates to:
  /// **'중단하기'**
  String get baseGameStateQuitButton;

  /// No description provided for @baseGameStateContinueButton.
  ///
  /// In ko, this message translates to:
  /// **'계속하기'**
  String get baseGameStateContinueButton;

  /// No description provided for @game01ScreenSecondUnit.
  ///
  /// In ko, this message translates to:
  /// **'초'**
  String get game01ScreenSecondUnit;

  /// No description provided for @game01ScreenMissUnit.
  ///
  /// In ko, this message translates to:
  /// **'개'**
  String get game01ScreenMissUnit;

  /// No description provided for @game01ScreenStartMessage.
  ///
  /// In ko, this message translates to:
  /// **'총 {levelCount}단계\n단계마다 {duration}초 동안 풍선을 터뜨리세요!\n풍선을 {maxMiss}개 놓치면 게임이 끝나요!\n단계가 올라갈수록 풍선이 더 빨라져요!'**
  String game01ScreenStartMessage(int levelCount, int duration, int maxMiss);

  /// No description provided for @game01ScreenStartButton.
  ///
  /// In ko, this message translates to:
  /// **'게임 시작'**
  String get game01ScreenStartButton;

  /// No description provided for @game01ScreenLevelClearedTitle.
  ///
  /// In ko, this message translates to:
  /// **'{level}단계 클리어! 🎉'**
  String game01ScreenLevelClearedTitle(int level);

  /// No description provided for @game01ScreenLevelClearedMessage.
  ///
  /// In ko, this message translates to:
  /// **'{duration}초를 잘 버텼어요!\n놓친 풍선: {miss}개\n다음 단계에 도전할까요?'**
  String game01ScreenLevelClearedMessage(int duration, int miss);

  /// No description provided for @game01ScreenNextLevelButton.
  ///
  /// In ko, this message translates to:
  /// **'다음 단계'**
  String get game01ScreenNextLevelButton;

  /// No description provided for @game01ScreenGameOverTitle.
  ///
  /// In ko, this message translates to:
  /// **'게임 종료! 😢'**
  String get game01ScreenGameOverTitle;

  /// No description provided for @game01ScreenGameOverMessage.
  ///
  /// In ko, this message translates to:
  /// **'풍선을 {maxMiss}개 놓쳤어요!\n같은 단계부터 다시 도전해 보세요!'**
  String game01ScreenGameOverMessage(int maxMiss);

  /// No description provided for @game01ScreenRetryButton.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get game01ScreenRetryButton;

  /// No description provided for @game01ScreenAllClearedTitle.
  ///
  /// In ko, this message translates to:
  /// **'전체 클리어! 🏆'**
  String get game01ScreenAllClearedTitle;

  /// No description provided for @game01ScreenAllClearedMessage.
  ///
  /// In ko, this message translates to:
  /// **'{levelCount}개 단계를 모두 완료했어요!\n정말 대단해요!'**
  String game01ScreenAllClearedMessage(int levelCount);

  /// No description provided for @game01ScreenConfirmButton.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get game01ScreenConfirmButton;

  /// No description provided for @game02ScreenScoreUnit.
  ///
  /// In ko, this message translates to:
  /// **'점'**
  String get game02ScreenScoreUnit;

  /// No description provided for @game02ScreenSecondUnit.
  ///
  /// In ko, this message translates to:
  /// **'초'**
  String get game02ScreenSecondUnit;

  /// No description provided for @game02ScreenCorrectFeedback.
  ///
  /// In ko, this message translates to:
  /// **'딩동댕!'**
  String get game02ScreenCorrectFeedback;

  /// No description provided for @game02ScreenIncorrectFeedback.
  ///
  /// In ko, this message translates to:
  /// **'땡!'**
  String get game02ScreenIncorrectFeedback;

  /// No description provided for @game02ScreenStartMessage.
  ///
  /// In ko, this message translates to:
  /// **'구구단의 정답을 찾아 터뜨리세요!\n{duration}초 동안 최대한 많이 맞혀보세요!'**
  String game02ScreenStartMessage(int duration);

  /// No description provided for @game02ScreenStartButton.
  ///
  /// In ko, this message translates to:
  /// **'게임 시작'**
  String get game02ScreenStartButton;

  /// No description provided for @game02ScreenGameOverTitle.
  ///
  /// In ko, this message translates to:
  /// **'시간 종료! ⏰'**
  String get game02ScreenGameOverTitle;

  /// No description provided for @game02ScreenGameOverMessage.
  ///
  /// In ko, this message translates to:
  /// **'맞힌 개수 : {score}'**
  String game02ScreenGameOverMessage(int score);

  /// No description provided for @game02ScreenConfirmButton.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get game02ScreenConfirmButton;

  /// No description provided for @game03ScreenScoreUnit.
  ///
  /// In ko, this message translates to:
  /// **'점'**
  String get game03ScreenScoreUnit;

  /// No description provided for @game03ScreenSecondUnit.
  ///
  /// In ko, this message translates to:
  /// **'초'**
  String get game03ScreenSecondUnit;

  /// No description provided for @game03ScreenCorrectFeedback.
  ///
  /// In ko, this message translates to:
  /// **'딩동댕!'**
  String get game03ScreenCorrectFeedback;

  /// No description provided for @game03ScreenIncorrectFeedback.
  ///
  /// In ko, this message translates to:
  /// **'땡!'**
  String get game03ScreenIncorrectFeedback;

  /// No description provided for @game03ScreenStartMessage.
  ///
  /// In ko, this message translates to:
  /// **'계산식 색깔의 풍선을 정답 개수만큼 터뜨리세요!\n{duration}초 동안 도전하세요!'**
  String game03ScreenStartMessage(int duration);

  /// No description provided for @game03ScreenStartButton.
  ///
  /// In ko, this message translates to:
  /// **'게임 시작'**
  String get game03ScreenStartButton;

  /// No description provided for @game03ScreenGameOverTitle.
  ///
  /// In ko, this message translates to:
  /// **'시간 종료! ⏰'**
  String get game03ScreenGameOverTitle;

  /// No description provided for @game03ScreenGameOverMessage.
  ///
  /// In ko, this message translates to:
  /// **'최종 점수 : {score}'**
  String game03ScreenGameOverMessage(int score);

  /// No description provided for @game03ScreenConfirmButton.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get game03ScreenConfirmButton;
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
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
