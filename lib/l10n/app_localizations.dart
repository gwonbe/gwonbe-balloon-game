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
  /// In en, this message translates to:
  /// **'Tap to Start!'**
  String get homeScreenTapToStart;

  /// No description provided for @gameListScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a Game'**
  String get gameListScreenTitle;

  /// No description provided for @game01Title.
  ///
  /// In en, this message translates to:
  /// **'Floating Balloons'**
  String get game01Title;

  /// No description provided for @game01Description.
  ///
  /// In en, this message translates to:
  /// **'Pop the balloons before they float away!'**
  String get game01Description;

  /// No description provided for @game01BestScore.
  ///
  /// In en, this message translates to:
  /// **'Best Score: {score} / {levelCount} Levels Cleared'**
  String game01BestScore(int score, int levelCount);

  /// No description provided for @game02Title.
  ///
  /// In en, this message translates to:
  /// **'Multiplication Challenge'**
  String get game02Title;

  /// No description provided for @game02Description.
  ///
  /// In en, this message translates to:
  /// **'Pop the balloons with the correct multiplication answers!'**
  String get game02Description;

  /// No description provided for @game02BestScore.
  ///
  /// In en, this message translates to:
  /// **'Best Score: {score} Correct Answers'**
  String game02BestScore(int score);

  /// No description provided for @game03Title.
  ///
  /// In en, this message translates to:
  /// **'Arithmetic Challenge'**
  String get game03Title;

  /// No description provided for @game03Description.
  ///
  /// In en, this message translates to:
  /// **'Pop the balloons with the correct arithmetic answers!'**
  String get game03Description;

  /// No description provided for @game03BestScore.
  ///
  /// In en, this message translates to:
  /// **'Best Score: {score} Correct Answers'**
  String game03BestScore(int score);

  /// No description provided for @gameListScreenNoRecord.
  ///
  /// In en, this message translates to:
  /// **'No Record'**
  String get gameListScreenNoRecord;

  /// No description provided for @baseGameStateAdTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Ad Break!'**
  String get baseGameStateAdTimeTitle;

  /// No description provided for @baseGameStateAdTimeMessage.
  ///
  /// In en, this message translates to:
  /// **'Please press Confirm.'**
  String get baseGameStateAdTimeMessage;

  /// No description provided for @baseGameStateConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get baseGameStateConfirmButton;

  /// No description provided for @baseGameStatePauseTitle.
  ///
  /// In en, this message translates to:
  /// **'Paused ⏸️'**
  String get baseGameStatePauseTitle;

  /// No description provided for @baseGameStatePauseMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to quit the game?'**
  String get baseGameStatePauseMessage;

  /// No description provided for @baseGameStateQuitButton.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get baseGameStateQuitButton;

  /// No description provided for @baseGameStateContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get baseGameStateContinueButton;

  /// No description provided for @game01ScreenSecondUnit.
  ///
  /// In en, this message translates to:
  /// **'sec'**
  String get game01ScreenSecondUnit;

  /// No description provided for @game01ScreenMissUnit.
  ///
  /// In en, this message translates to:
  /// **''**
  String get game01ScreenMissUnit;

  /// No description provided for @game01ScreenStartMessage.
  ///
  /// In en, this message translates to:
  /// **'Complete all {levelCount} levels!\nMissing a balloon or tapping a bomb costs a life!\nLose all {maxMiss} lives and the game ends.\nBalloons get faster each level!'**
  String game01ScreenStartMessage(int levelCount, int maxMiss);

  /// No description provided for @game01ScreenStartButton.
  ///
  /// In en, this message translates to:
  /// **'Start Game'**
  String get game01ScreenStartButton;

  /// No description provided for @game01ScreenLevelClearedTitle.
  ///
  /// In en, this message translates to:
  /// **'Level {level} Cleared! 🎉'**
  String game01ScreenLevelClearedTitle(int level);

  /// No description provided for @game01ScreenLevelClearedMessage.
  ///
  /// In en, this message translates to:
  /// **'Mistakes: {miss}\nReady for the next level?'**
  String game01ScreenLevelClearedMessage(Object miss);

  /// No description provided for @game01ScreenNextLevelButton.
  ///
  /// In en, this message translates to:
  /// **'Next Level'**
  String get game01ScreenNextLevelButton;

  /// No description provided for @game01ScreenGameOverTitle.
  ///
  /// In en, this message translates to:
  /// **'Game Over! 😢'**
  String get game01ScreenGameOverTitle;

  /// No description provided for @game01ScreenGameOverMessage.
  ///
  /// In en, this message translates to:
  /// **'You lost all {maxMiss} lives!\nAvoid missing balloons and tapping bombs!'**
  String game01ScreenGameOverMessage(int maxMiss);

  /// No description provided for @game01ScreenRetryButton.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get game01ScreenRetryButton;

  /// No description provided for @game01ScreenAllClearedTitle.
  ///
  /// In en, this message translates to:
  /// **'All Levels Cleared! 🏆'**
  String get game01ScreenAllClearedTitle;

  /// No description provided for @game01ScreenAllClearedMessage.
  ///
  /// In en, this message translates to:
  /// **'You completed all {levelCount} levels!\nAmazing job!'**
  String game01ScreenAllClearedMessage(int levelCount);

  /// No description provided for @game01ScreenConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get game01ScreenConfirmButton;

  /// No description provided for @game02ScreenScoreUnit.
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get game02ScreenScoreUnit;

  /// No description provided for @game02ScreenSecondUnit.
  ///
  /// In en, this message translates to:
  /// **'sec'**
  String get game02ScreenSecondUnit;

  /// No description provided for @game02ScreenCorrectFeedback.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get game02ScreenCorrectFeedback;

  /// No description provided for @game02ScreenIncorrectFeedback.
  ///
  /// In en, this message translates to:
  /// **'Incorrect!'**
  String get game02ScreenIncorrectFeedback;

  /// No description provided for @game02ScreenStartMessage.
  ///
  /// In en, this message translates to:
  /// **'Pop the balloon with the correct multiplication answer!'**
  String get game02ScreenStartMessage;

  /// No description provided for @game02ScreenStartButton.
  ///
  /// In en, this message translates to:
  /// **'Start Game'**
  String get game02ScreenStartButton;

  /// No description provided for @game02ScreenGameOverTitle.
  ///
  /// In en, this message translates to:
  /// **'Time\'s Up! ⏰'**
  String get game02ScreenGameOverTitle;

  /// No description provided for @game02ScreenGameOverMessage.
  ///
  /// In en, this message translates to:
  /// **'Correct Answers: {score}'**
  String game02ScreenGameOverMessage(int score);

  /// No description provided for @game02ScreenConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get game02ScreenConfirmButton;

  /// No description provided for @game03ScreenScoreUnit.
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get game03ScreenScoreUnit;

  /// No description provided for @game03ScreenSecondUnit.
  ///
  /// In en, this message translates to:
  /// **'sec'**
  String get game03ScreenSecondUnit;

  /// No description provided for @game03ScreenCorrectFeedback.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get game03ScreenCorrectFeedback;

  /// No description provided for @game03ScreenIncorrectFeedback.
  ///
  /// In en, this message translates to:
  /// **'Incorrect!'**
  String get game03ScreenIncorrectFeedback;

  /// No description provided for @game03ScreenStartMessage.
  ///
  /// In en, this message translates to:
  /// **'Pop the balloons matching the answer to the equation!'**
  String get game03ScreenStartMessage;

  /// No description provided for @game03ScreenStartButton.
  ///
  /// In en, this message translates to:
  /// **'Start Game'**
  String get game03ScreenStartButton;

  /// No description provided for @game03ScreenGameOverTitle.
  ///
  /// In en, this message translates to:
  /// **'Time\'s Up! ⏰'**
  String get game03ScreenGameOverTitle;

  /// No description provided for @game03ScreenGameOverMessage.
  ///
  /// In en, this message translates to:
  /// **'Final Score: {score}'**
  String game03ScreenGameOverMessage(int score);

  /// No description provided for @game03ScreenConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get game03ScreenConfirmButton;

  /// No description provided for @game04Title.
  ///
  /// In en, this message translates to:
  /// **'Speed Challenge'**
  String get game04Title;

  /// No description provided for @game04Description.
  ///
  /// In en, this message translates to:
  /// **'Pop 100 balloons as fast as you can!'**
  String get game04Description;

  /// No description provided for @game04BestTime.
  ///
  /// In en, this message translates to:
  /// **'Best time: {time}s'**
  String game04BestTime(String time);

  /// No description provided for @game04ScreenBalloonsUnit.
  ///
  /// In en, this message translates to:
  /// **'popped'**
  String get game04ScreenBalloonsUnit;

  /// No description provided for @game04ScreenSecondsUnit.
  ///
  /// In en, this message translates to:
  /// **'sec'**
  String get game04ScreenSecondsUnit;

  /// No description provided for @game04ScreenColorRule.
  ///
  /// In en, this message translates to:
  /// **'Pop this color'**
  String get game04ScreenColorRule;

  /// No description provided for @game04ScreenLetterRule.
  ///
  /// In en, this message translates to:
  /// **'Pop this letter'**
  String get game04ScreenLetterRule;

  /// No description provided for @game04ScreenStartMessage.
  ///
  /// In en, this message translates to:
  /// **'Pop all 100 balloons as fast as you can!\nThe target changes every 10 balloons.'**
  String get game04ScreenStartMessage;

  /// No description provided for @game04ScreenStartButton.
  ///
  /// In en, this message translates to:
  /// **'Start Game'**
  String get game04ScreenStartButton;

  /// No description provided for @game04ScreenCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Speed Challenge Complete! 🎉'**
  String get game04ScreenCompleteTitle;

  /// No description provided for @game04ScreenCompleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Time: {time}s'**
  String game04ScreenCompleteMessage(String time);

  /// No description provided for @game04ScreenReplayButton.
  ///
  /// In en, this message translates to:
  /// **'Play Again'**
  String get game04ScreenReplayButton;

  /// No description provided for @game04ScreenRuleChangeFeedback.
  ///
  /// In en, this message translates to:
  /// **'Rule Change!'**
  String get game04ScreenRuleChangeFeedback;
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
