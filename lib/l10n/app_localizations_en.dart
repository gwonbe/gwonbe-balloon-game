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
  String game01ScreenStartMessage(int levelCount, int maxMiss) {
    return 'Complete all $levelCount levels!\nMissing a balloon or tapping a bomb costs a life!\nLose all $maxMiss lives and the game ends.\nBalloons get faster each level!';
  }

  @override
  String get game01ScreenStartButton => 'Start Game';

  @override
  String game01ScreenLevelClearedTitle(int level) {
    return 'Level $level Cleared! 🎉';
  }

  @override
  String game01ScreenLevelClearedMessage(Object miss) {
    return 'Mistakes: $miss\nReady for the next level?';
  }

  @override
  String get game01ScreenNextLevelButton => 'Next Level';

  @override
  String get game01ScreenGameOverTitle => 'Game Over! 😢';

  @override
  String game01ScreenGameOverMessage(int maxMiss) {
    return 'You lost all $maxMiss lives!\nAvoid missing balloons and tapping bombs!';
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
  String get game02ScreenStartMessage =>
      'Pop the balloon with the correct multiplication answer!';

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
  String get game03ScreenStartMessage =>
      'Pop the balloons matching the answer to the equation!';

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

  @override
  String get game04Title => 'Speed Challenge';

  @override
  String get game04Description =>
      'Pop 100 balloons by color as fast as you can!';

  @override
  String game04BestTime(String time) {
    return 'Best time: ${time}s';
  }

  @override
  String get game04ScreenBalloonsUnit => 'popped';

  @override
  String get game04ScreenSecondsUnit => 'sec';

  @override
  String get game04ScreenColorRule => 'Pop this color';

  @override
  String get game04ScreenStartMessage =>
      'Pop all 100 balloons by color as fast as you can!\nThe target color changes every 10 balloons.';

  @override
  String get game04ScreenStartButton => 'Start Game';

  @override
  String get game04ScreenCompleteTitle => 'Speed Challenge Complete! 🎉';

  @override
  String game04ScreenCompleteMessage(String time) {
    return 'Time: ${time}s';
  }

  @override
  String get game04ScreenReplayButton => 'Play Again';

  @override
  String get game04ScreenRuleChangeFeedback => 'Rule Change!';
}
