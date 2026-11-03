import 'dart:async';
import 'dart:math';
import 'package:balloon_game/l10n/app_localizations.dart';
import 'package:balloon_game/utils/app_const.dart';
import 'package:balloon_game/utils/base_game_state.dart';
import 'package:balloon_game/utils/game_storage.dart';
import 'package:balloon_game/widgets/info_chip.dart';
import 'package:flutter/material.dart';

class Game03Screen extends StatefulWidget {
  const Game03Screen({super.key});

  @override
  State<Game03Screen> createState() => _Game03ScreenState();
}

// ───────── 상수 ─────────

/// 제한 시간(초)
const int _kGameDuration = 48;

/// 5x5 풍선판
const int _kGridColumns = 5;
const int _kGridCount = 25;

/// 정답/오답 메시지 표시 시간
const Duration _kFeedbackDuration = Duration(milliseconds: 700);

/// 정답을 맞힌 뒤 다음 문제로 넘어가기 전 대기 시간
const Duration _kNextRoundDelay = Duration(milliseconds: 300);

enum _GameStatus {
  ready, // 시작 전
  playing, // 진행 중 (일시정지는 부모의 isPaused로 관리)
  gameOver, // 시간 종료
}

// ───────── 모델 ─────────

/// 한 라운드: 식(a op b = 정답)과 목표 색상
class _Round {
  final int operand1;
  final int operand2;
  final String operator; // '+', '-', '*', '/'
  final int answer;
  final Color targetColor;

  const _Round({
    required this.operand1,
    required this.operand2,
    required this.operator,
    required this.answer,
    required this.targetColor,
  });

  String get operatorSymbol {
    switch (operator) {
      case '*':
        return '×';
      case '/':
        return '÷';
      default:
        return operator;
    }
  }

  factory _Round.random(Random random) {
    const List<String> ops = ['+', '-', '*', '/'];
    final String op = ops[random.nextInt(ops.length)];

    // 정답은 항상 2~11
    final int answer = 2 + random.nextInt(10);

    late int a;
    late int b;

    switch (op) {
      case '+':
        // a + b = answer
        a = 1 + random.nextInt(answer - 1);
        b = answer - a;
        break;

      case '-':
        // a - b = answer, 두 숫자는 25 이하
        b = 1 + random.nextInt(25 - answer);
        a = answer + b;
        break;

      case '*':
        // a * b = answer
        final List<int> factors = [
          for (int i = 1; i <= answer; i++)
            if (answer % i == 0) i,
        ];
        a = factors[random.nextInt(factors.length)];
        b = answer ~/ a;
        break;

      default:
        // '/': a / b = answer, 나머지 없이 나누어떨어짐
        b = 1 + random.nextInt(25 ~/ answer);
        a = answer * b;
    }

    return _Round(
      operand1: a,
      operand2: b,
      operator: op,
      answer: answer,
      targetColor:
          AppConst.balloonColors[random.nextInt(AppConst.balloonColors.length)],
    );
  }

  /// 정답 개수보다 0~5개 더 많은 목표 색 풍선을 배치하고,
  /// 나머지는 다른 색상들로 균등하게 채운 뒤 섞어서 반환한다.
  List<Color> buildGridColors(Random random) {
    final int targetCount = answer + random.nextInt(6);

    // 정답이 클수록 색상 종류를 줄여서 목표 색을 찾기 쉽게 한다.
    final int colorCount;
    if (answer >= 10) {
      colorCount = 2;
    } else if (answer >= 7) {
      colorCount = 3;
    } else if (answer >= 4) {
      colorCount = 4;
    } else {
      colorCount = 5;
    }

    // 목표 색상 외에 사용할 색상 선택
    final List<Color> otherColors = AppConst.balloonColors
        .where((color) => color != targetColor)
        .toList()
      ..shuffle(random);
    final List<Color> nonTargetColors = otherColors.take(colorCount - 1).toList();

    return [
      for (int i = 0; i < targetCount; i++) targetColor,
      for (int i = 0; i < _kGridCount - targetCount; i++)
        nonTargetColors[i % nonTargetColors.length],
    ]..shuffle(random);
  }
}

// ───────── State ─────────

class _Game03ScreenState extends BaseGameState<Game03Screen> {
  late AppLocalizations l10n;
  final Random _random = Random();

  Timer? _gameTimer; // 1초마다 남은 시간 감소
  Timer? _feedbackTimer; // 정답/오답 메시지 자동으로 사라지게
  Timer? _nextRoundTimer; // 다음 문제로 넘어가기 전 짧은 대기

  _GameStatus _status = _GameStatus.ready;
  int _score = 0;
  int _timeLeft = _kGameDuration;

  // 현재 라운드(식 + 목표 색상)와 5x5 풍선판
  late _Round _round;
  late List<Color> _gridColors;
  late List<bool> _gridActive;
  int _poppedTargetCount = 0;

  // 정답을 맞혀서 다음 라운드로 넘어가야 하는 상태
  bool _pendingNext = false;

  // 정답/오답 피드백 메시지
  String? _feedbackText;
  bool _feedbackCorrect = false;

  @override
  void initState() {
    super.initState();
    _prepareNextRound(); // late 변수들을 첫 빌드 전에 초기화
  }

  // ───────── BaseGameState 구현부 ─────────

  @override
  bool get isPlaying => _status == _GameStatus.playing;

  @override
  String get bestScoreKey => GameStorage.bestScoreGame03;

  @override
  int get currentScore => _score;

  @override
  void cancelAllTimers() {
    _gameTimer?.cancel();
    _feedbackTimer?.cancel();
    _nextRoundTimer?.cancel();
  }

  @override
  void startTimers() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // 일시정지 중이거나 플레이 중이 아니면 카운트하지 않음
      if (_status != _GameStatus.playing || isPaused) return;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) _endGame();
    });
  }

  @override
  void onPause() {
    // 피드백/다음 라운드 타이머가 취소되므로 메시지를 지우고, 넘어갈 라운드가 있으면 처리한다.
    _feedbackText = null;
    if (_pendingNext) _prepareNextRound();
  }

  // ───────── 게임 로직 ─────────

  /// 새 식과 새 풍선판을 만든다. (setState 없음: setState 안이나 initState에서 호출)
  void _prepareNextRound() {
    _round = _Round.random(_random);
    _gridColors = _round.buildGridColors(_random);
    _gridActive = List<bool>.filled(_kGridCount, true);
    _poppedTargetCount = 0;
    _pendingNext = false;
  }

  void _startGame() {
    cancelAllTimers();
    registerGameStart();

    setState(() {
      _prepareNextRound();
      _score = 0;
      _timeLeft = _kGameDuration;
      _status = _GameStatus.playing;
      _feedbackText = null;
    });

    startBgm();
    startTimers();
  }

  void _endGame() {
    cancelAllTimers();
    stopBgm();

    setState(() {
      _status = _GameStatus.gameOver;
      _feedbackText = null;
      _pendingNext = false;
    });

    unawaited(saveBestScore());
  }

  void _showFeedback(bool correct) {
    _feedbackTimer?.cancel();

    setState(() {
      _feedbackCorrect = correct;
      _feedbackText = correct
          ? l10n.game03ScreenCorrectFeedback
          : l10n.game03ScreenIncorrectFeedback;
    });

    _feedbackTimer = Timer(_kFeedbackDuration, () {
      if (!mounted) return;
      setState(() => _feedbackText = null);
    });
  }

  void _onTapCell(int index) {
    if (_status != _GameStatus.playing || isPaused) return;
    if (_feedbackText != null ||
        _nextRoundTimer?.isActive == true ||
        !_gridActive[index]) {
      return;
    }

    final bool isTargetColor = _gridColors[index] == _round.targetColor;

    setState(() {
      _gridActive[index] = false;
      if (isTargetColor) _poppedTargetCount++;
    });

    if (!isTargetColor) {
      _showFeedback(false);
      return;
    }

    if (_poppedTargetCount == _round.answer) {
      setState(() {
        _score++;
        _pendingNext = true;
      });

      _showFeedback(true);

      // 메시지와 정답 카운트를 잠깐 보여준 뒤 다음 문제로 이동한다.
      _nextRoundTimer?.cancel();
      _nextRoundTimer = Timer(_kNextRoundDelay, () {
        if (!mounted || _status != _GameStatus.playing || isPaused) return;

        _feedbackTimer?.cancel();
        setState(() {
          _feedbackText = null;
          _prepareNextRound();
        });
      });
    }
  }

  // ───────── UI ─────────

  @override
  Widget build(BuildContext context) {
    l10n = AppLocalizations.of(context)!;

    final bool showBoard = _status == _GameStatus.playing && !isPaused;

    return withSystemBackPause(
      Scaffold(
        body: GameBackground(
          child: Stack(
            children: [
              if (showBoard)
                Positioned.fill(
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 140),
                      child: Center(child: _buildGrid()),
                    ),
                  ),
                ),
              GameTopBar(
                pauseButton: buildPauseButton(),
                chips: [
                  InfoChip(
                    icon: Icons.star,
                    value: '$_score',
                    unit: l10n.game03ScreenScoreUnit,
                    width: 95,
                  ),
                  InfoChip(
                    icon: Icons.timer,
                    value: '$_timeLeft',
                    unit: l10n.game03ScreenSecondUnit,
                    width: 90,
                  ),
                ],
                bottom: showBoard ? _buildQuestionBoard() : null,
              ),
              if (_feedbackText != null)
                FeedbackOverlay(text: _feedbackText!, correct: _feedbackCorrect),
              if (_status == _GameStatus.ready)
                StartOverlay(
                  message: l10n.game03ScreenStartMessage,
                  buttonLabel: l10n.game03ScreenStartButton,
                  onStart: _startGame,
                ),
              if (_status == _GameStatus.gameOver) _buildGameOverOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  /// 5x5 풍선판. 터진 풍선 자리는 빈 칸으로 남는다.
  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double gap = 5;
        final double gridWidth = min(constraints.maxWidth * 0.94, 390);
        final double cellSize =
            (gridWidth - gap * (_kGridColumns - 1)) / _kGridColumns;

        return SizedBox(
          width: gridWidth,
          child: Wrap(
            spacing: gap,
            runSpacing: 2,
            children: List.generate(_kGridCount, (index) {
              return SizedBox(
                width: cellSize,
                height: cellSize * 1.3,
                child: _gridActive[index]
                    ? GestureDetector(
                        onTap: () => _onTapCell(index),
                        child: LabeledBalloon(
                          size: cellSize,
                          color: _gridColors[index],
                          label: '',
                        ),
                      )
                    : const SizedBox.shrink(),
              );
            }),
          ),
        );
      },
    );
  }

  /// 상단 문제 표시: a ○ b = (터뜨린 목표 색 풍선 개수)
  Widget _buildQuestionBoard() {
    const double balloonSize = 44;
    final List<String> labels = [
      '${_round.operand1}',
      _round.operatorSymbol,
      '${_round.operand2}',
      '=',
      '$_poppedTargetCount',
    ];

    final List<Widget> children = [];
    for (int i = 0; i < labels.length; i++) {
      if (i > 0) children.add(const SizedBox(width: 3));
      children.add(
        LabeledBalloon(size: balloonSize, color: _round.targetColor, label: labels[i]),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  // 시간 종료 = 점수 결과를 보여주는 긍정 다이얼로그
  Widget _buildGameOverOverlay() {
    return buildDialogCard(
      title: l10n.game03ScreenGameOverTitle,
      message: l10n.game03ScreenGameOverMessage(_score),
      primaryLabel: l10n.game03ScreenConfirmButton,
      onPrimaryAction: () => Navigator.of(context).maybePop(),
      showQuitButton: false,
    );
  }
}
