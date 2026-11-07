// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get homeScreenTapToStart => '터치하세요!';

  @override
  String get gameListScreenTitle => '게임 목록';

  @override
  String get game01Title => '둥실둥실';

  @override
  String get game01Description => '풍선이 하늘로 올라가기 전에 터뜨리세요!';

  @override
  String game01BestScore(int score, int levelCount) {
    return '최고 기록 : $score / $levelCount 단계 클리어';
  }

  @override
  String get game02Title => '구구단을 외자';

  @override
  String get game02Description => '구구단 정답 풍선을 터뜨리세요!';

  @override
  String game02BestScore(int score) {
    return '최고 기록 : $score개 정답';
  }

  @override
  String get game03Title => '사칙연산';

  @override
  String get game03Description => '사칙연산 정답 풍선을 터뜨리세요!';

  @override
  String game03BestScore(int score) {
    return '최고 기록 : $score개 정답';
  }

  @override
  String get gameListScreenNoRecord => '기록 없음';

  @override
  String get baseGameStateAdTimeTitle => '광고타임!';

  @override
  String get baseGameStateAdTimeMessage => '확인 버튼을 눌러주세요.';

  @override
  String get baseGameStateConfirmButton => '확인';

  @override
  String get baseGameStatePauseTitle => '일시정지';

  @override
  String get baseGameStatePauseMessage => '게임을 중단하시겠습니까?';

  @override
  String get baseGameStateQuitButton => '중단하기';

  @override
  String get baseGameStateContinueButton => '계속하기';

  @override
  String get game01ScreenSecondUnit => '초';

  @override
  String get game01ScreenMissUnit => '개';

  @override
  String game01ScreenStartMessage(int levelCount, int maxMiss) {
    return '총 $levelCount단계\n풍선을 놓치거나 폭탄을 터치하면 생명이 줄어요!\n생명 $maxMiss개를 모두 잃으면 게임 종료!\n단계가 올라갈수록 풍선이 더 빨라져요!';
  }

  @override
  String get game01ScreenStartButton => '게임 시작';

  @override
  String game01ScreenLevelClearedTitle(int level) {
    return '$level단계 클리어! 🎉';
  }

  @override
  String game01ScreenLevelClearedMessage(Object miss) {
    return '실수 횟수: $miss회\n다음 단계에 도전할까요?';
  }

  @override
  String get game01ScreenNextLevelButton => '다음 단계';

  @override
  String get game01ScreenGameOverTitle => '게임 종료! 😢';

  @override
  String game01ScreenGameOverMessage(int maxMiss) {
    return '생명 $maxMiss개를 모두 잃었어요!\n풍선을 놓치거나 폭탄을 터치하지 않게 조심하세요!';
  }

  @override
  String get game01ScreenRetryButton => '다시 시도';

  @override
  String get game01ScreenAllClearedTitle => '전체 클리어! 🏆';

  @override
  String game01ScreenAllClearedMessage(int levelCount) {
    return '$levelCount개 단계를 모두 완료했어요!\n정말 대단해요!';
  }

  @override
  String get game01ScreenConfirmButton => '확인';

  @override
  String get game02ScreenScoreUnit => '점';

  @override
  String get game02ScreenSecondUnit => '초';

  @override
  String get game02ScreenCorrectFeedback => '딩동댕!';

  @override
  String get game02ScreenIncorrectFeedback => '땡!';

  @override
  String get game02ScreenStartMessage => '구구단의 정답을 찾아 터뜨리세요!';

  @override
  String get game02ScreenStartButton => '게임 시작';

  @override
  String get game02ScreenGameOverTitle => '시간 종료!';

  @override
  String game02ScreenGameOverMessage(int score) {
    return '맞힌 개수 : $score';
  }

  @override
  String get game02ScreenConfirmButton => '확인';

  @override
  String get game03ScreenScoreUnit => '점';

  @override
  String get game03ScreenSecondUnit => '초';

  @override
  String get game03ScreenCorrectFeedback => '딩동댕!';

  @override
  String get game03ScreenIncorrectFeedback => '땡!';

  @override
  String get game03ScreenDropPrompt => '같은 색 풍선을 이곳으로 옮기세요';

  @override
  String get game03ScreenStartMessage => '계산식 색깔의 풍선을 정답 개수만큼 터뜨리세요!';

  @override
  String get game03ScreenStartButton => '게임 시작';

  @override
  String get game03ScreenGameOverTitle => '시간 종료!';

  @override
  String game03ScreenGameOverMessage(int score) {
    return '최종 점수 : $score';
  }

  @override
  String get game03ScreenConfirmButton => '확인';

  @override
  String get game04Title => '스피드 챌린지';

  @override
  String get game04Description => '색상 조건에 맞춰 풍선 100개를 빠르게 터뜨리세요!';

  @override
  String game04BestTime(String time) {
    return '최고 기록: $time초';
  }

  @override
  String get game04ScreenBalloonsUnit => '개';

  @override
  String get game04ScreenSecondsUnit => '초';

  @override
  String get game04ScreenColorRule => '이 색 풍선을 터뜨려요';

  @override
  String get game04ScreenStartMessage =>
      '색상 조건에 맞춰 풍선 100개를 최대한 빠르게 터뜨리세요!\n10개를 터뜨릴 때마다 목표 색상이 바뀝니다.';

  @override
  String get game04ScreenStartButton => '게임 시작';

  @override
  String get game04ScreenCompleteTitle => '스피드 챌린지 완료! 🎉';

  @override
  String game04ScreenCompleteMessage(String time) {
    return '걸린 시간: $time초';
  }

  @override
  String get game04ScreenReplayButton => '다시하기';

  @override
  String get game04ScreenRuleChangeFeedback => '룰 체인지!';
}
