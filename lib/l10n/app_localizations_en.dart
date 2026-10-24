// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get homeScreenTapToStart => 'Tap to Start!';

  @override
  String get gameListScreenTitle => 'Select a Game';

  @override
  String get game01Title => 'Floating Balloons';

  @override
  String get game01Description => 'Pop the balloons before they float away!';

  @override
  String game01BestScore(int score, int levelCount) {
    return 'Best Score: $score / $levelCount Levels Cleared';
  }

  @override
  String get game02Title => 'Multiplication Challenge';

  @override
  String get game02Description =>
      'Pop the balloons with the correct multiplication answers!';

  @override
  String game02BestScore(int score) {
    return 'Best Score: $score Correct Answers';
  }

  @override
  String get game03Title => 'Arithmetic Challenge';

  @override
  String get game03Description =>
      'Pop the balloons with the correct arithmetic answers!';

  @override
  String game03BestScore(int score) {
    return 'Best Score: $score Correct Answers';
  }

  @override
  String get gameListScreenNoRecord => 'No Record';

  @override
  String get baseGameStateAdTimeTitle => 'Ad Break!';

  @override
  String get baseGameStateAdTimeMessage => 'Please press Confirm.';

  @override
  String get baseGameStateConfirmButton => 'Confirm';

  @override
  String get baseGameStatePauseTitle => 'Paused ⏸️';

  @override
  String get baseGameStatePauseMessage => 'Do you want to quit the game?';

  @override
  String get baseGameStateQuitButton => 'Quit';

  @override
  String get baseGameStateContinueButton => 'Continue';

  @override
  String get game01ScreenSecondUnit => 'sec';

  @override
  String get game01ScreenMissUnit => '';

  @override
  String game01ScreenStartMessage(int levelCount, int duration, int maxMiss) {
    return 'Clear all $levelCount levels!\nPop balloons for $duration seconds in each level!\nMissing $maxMiss balloons ends the game!\nBalloons get faster as you progress!';
  }

  @override
  String get game01ScreenStartButton => 'Start Game';

  @override
  String game01ScreenLevelClearedTitle(int level) {
    return 'Level $level Cleared! 🎉';
  }

  @override
  String game01ScreenLevelClearedMessage(int duration, int miss) {
    return 'You survived for $duration seconds!\nBalloons missed: $miss\nReady for the next level?';
  }

  @override
  String get game01ScreenNextLevelButton => 'Next Level';

  @override
  String get game01ScreenGameOverTitle => 'Game Over! 😢';

  @override
  String game01ScreenGameOverMessage(int maxMiss) {
    return 'You missed $maxMiss balloons!\nTry again from the same level!';
  }

  @override
  String get game01ScreenRetryButton => 'Try Again';

  @override
  String get game01ScreenAllClearedTitle => 'All Levels Cleared! 🏆';

  @override
  String game01ScreenAllClearedMessage(int levelCount) {
    return 'You completed all $levelCount levels!\nAmazing job!';
  }

  @override
  String get game01ScreenConfirmButton => 'OK';

  @override
  String get game02ScreenScoreUnit => 'pts';

  @override
  String get game02ScreenSecondUnit => 'sec';

  @override
  String get game02ScreenCorrectFeedback => 'Correct!';

  @override
  String get game02ScreenIncorrectFeedback => 'Incorrect!';

  @override
  String game02ScreenStartMessage(int duration) {
    return 'Pop the balloon with the correct multiplication answer!\nGet as many answers right as you can in $duration seconds!';
  }

  @override
  String get game02ScreenStartButton => 'Start Game';

  @override
  String get game02ScreenGameOverTitle => 'Time\'s Up! ⏰';

  @override
  String game02ScreenGameOverMessage(int score) {
    return 'Correct Answers: $score';
  }

  @override
  String get game02ScreenConfirmButton => 'OK';

  @override
  String get game03ScreenScoreUnit => 'pts';

  @override
  String get game03ScreenSecondUnit => 'sec';

  @override
  String get game03ScreenCorrectFeedback => 'Correct!';

  @override
  String get game03ScreenIncorrectFeedback => 'Incorrect!';

  @override
  String game03ScreenStartMessage(int duration) {
    return 'Pop the balloons matching the answer to the equation!\nYou have $duration seconds!';
  }

  @override
  String get game03ScreenStartButton => 'Start Game';

  @override
  String get game03ScreenGameOverTitle => 'Time\'s Up! ⏰';

  @override
  String game03ScreenGameOverMessage(int score) {
    return 'Final Score: $score';
  }

  @override
  String get game03ScreenConfirmButton => 'OK';
}
