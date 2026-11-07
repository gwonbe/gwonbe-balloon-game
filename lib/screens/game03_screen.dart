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

  Timer? _gameTimer;
  final Stopwatch _gameStopwatch = Stopwatch();
  Timer? _feedbackTimer; // 정답/오답 메시지 자동으로 사라지게
  Timer? _nextRoundTimer; // 다음 문제로 넘어가기 전 짧은 대기

  _GameStatus _status = _GameStatus.ready;
  int _score = 0;
  int _timeLeft = _kGameDuration;

  // 현재 라운드(식 + 목표 색상)와 5x5 풍선판
  late _Round _round;
  late List<Color> _gridColors;
  late List<bool> _gridActive;
  late List<bool> _gridPopped;
  late List<Offset> _gridPositions;
  final GlobalKey _gridKey = GlobalKey();
  final List<int> _placedBalloons = [];
  bool _roundComplete = false;

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
    _gameStopwatch.stop();
  }

  @override
  void startTimers() {
    _gameStopwatch.start();
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_status != _GameStatus.playing || isPaused) return;

      final int remainingMilliseconds = _kGameDuration * 1000 - _gameStopwatch.elapsedMilliseconds;
      if (remainingMilliseconds <= 0) {
        _endGame();
        return;
      }

      final int remainingSeconds = (remainingMilliseconds / 1000).ceil();
      if (remainingSeconds != _timeLeft) {
        setState(() => _timeLeft = remainingSeconds);
      }
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
    _gridPopped = List<bool>.filled(_kGridCount, false);
    _gridPositions = List.generate(
      _kGridCount,
      (i) => Offset(
        ((i % _kGridColumns) + 0.5) / _kGridColumns,
        ((i ~/ _kGridColumns) + 0.5) / _kGridColumns,
      ),
    );
    _placedBalloons.clear();
    _roundComplete = false;
    _pendingNext = false;
  }

  void _startGame() {
    cancelAllTimers();
    registerGameStart();
    _gameStopwatch.reset();

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
      _timeLeft = 0;
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

  void _onDropBalloon(int index) {
    if (_status != _GameStatus.playing || isPaused) return;
    if (_feedbackText != null ||
        _nextRoundTimer?.isActive == true ||
        !_gridActive[index]) {
      return;
    }

    final bool isTargetColor = _gridColors[index] == _round.targetColor;

    setState(() {
      _gridActive[index] = false;
      if (isTargetColor) {
        _placedBalloons.add(index);
      } else {
        _gridPopped[index] = true;
      }
    });

    if (!isTargetColor) {
      _showFeedback(false);
      return;
    }

    if (_placedBalloons.length == _round.answer) {
      setState(() {
        _score++;
        _pendingNext = true;
        _roundComplete = true;
        for (int i = 0; i < _kGridCount; i++) {
          if (_gridActive[i]) _gridPopped[i] = true;
        }
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
                      padding: const EdgeInsets.fromLTRB(12, 150, 12, 12),
                      child: LayoutBuilder(builder: (context, constraints) {
                        final gridHeight = min(260.0, max(145.0, constraints.maxHeight - 175));
                        return Column(children: [
                          Expanded(child: _buildDropArea()),
                          const SizedBox(height: 12),
                          SizedBox(height: gridHeight, child: _buildGrid()),
                        ]);
                      }),
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

  /// 드래그할 수 있는 5x5 풍선판.
  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cellWidth = constraints.maxWidth / _kGridColumns;
        final double cellHeight = constraints.maxHeight / _kGridColumns;
        final double size = min(cellWidth * 0.68, cellHeight * 0.68);
        return SizedBox(
          key: _gridKey,
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Stack(children: [
            Positioned.fill(child: Container(decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
              borderRadius: BorderRadius.circular(20),
            ))),
            for (int index = 0; index < _kGridCount; index++)
              if (_gridActive[index] || _gridPopped[index])
                Positioned(
                  left: _gridPositions[index].dx * constraints.maxWidth - size / 2,
                  top: _gridPositions[index].dy * constraints.maxHeight - size * 0.65,
                  child: AnimatedScale(
                    scale: _gridPopped[index] ? 1.3 : 1,
                    duration: const Duration(milliseconds: 180),
                    child: AnimatedOpacity(
                      opacity: _gridPopped[index] ? 0 : 1,
                      duration: const Duration(milliseconds: 180),
                      child: _gridActive[index]
                          ? Draggable<int>(
                              data: index,
                              dragAnchorStrategy: pointerDragAnchorStrategy,
                              feedback: Material(color: Colors.transparent, child: LabeledBalloon(size: size, color: _gridColors[index], label: '', withShadow: true)),
                              childWhenDragging: const SizedBox.shrink(),
                              onDragEnd: (details) {
                                if (!_gridActive[index] || !mounted) return;
                                final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
                                if (box == null) return;
                                final local = box.globalToLocal(details.offset);
                                setState(() => _gridPositions[index] = Offset(
                                  ((local.dx + size / 2) / box.size.width).clamp(0.0, 1.0),
                                  ((local.dy + size * 0.65) / box.size.height).clamp(0.0, 1.0),
                                ));
                              },
                              child: LabeledBalloon(size: size, color: _gridColors[index], label: '', withShadow: true),
                            )
                          : LabeledBalloon(size: size, color: _gridColors[index], label: '', withShadow: true),
                    ),
                  ),
                ),
          ]),
        );
      },
    );
  }

  Widget _buildDropArea() => DragTarget<int>(
    onWillAcceptWithDetails: (_) => _status == _GameStatus.playing && !isPaused,
    onAcceptWithDetails: (details) => _onDropBalloon(details.data),
    builder: (context, candidates, rejected) => AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: double.infinity,
      height: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: candidates.isNotEmpty ? Colors.white.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _round.targetColor, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(children: [
        Text(l10n.game03ScreenDropPrompt, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        Expanded(child: Center(child: Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          spacing: 2,
          runSpacing: 0,
          children: _placedBalloons.map((index) => AnimatedOpacity(
            opacity: _roundComplete ? 0 : 1,
            duration: const Duration(milliseconds: 180),
            child: LabeledBalloon(size: 23, color: _gridColors[index], label: ''),
          )).toList(),
        ))),
      ]),
    ),
  );

  /// 상단 문제 표시: a ○ b = (터뜨린 목표 색 풍선 개수)
  Widget _buildQuestionBoard() {
    const double balloonSize = 52;
    final List<String> labels = [
      '${_round.operand1}',
      _round.operatorSymbol,
      '${_round.operand2}',
      '=',
      '${_placedBalloons.length}',
    ];

    final List<Widget> children = [];
    for (int i = 0; i < labels.length; i++) {
      if (i > 0) children.add(const SizedBox(width: 3));
      children.add(
        LabeledBalloon(
          size: balloonSize,
          color: _round.targetColor,
          label: labels[i],
          labelShadowColor: Colors.black54,
        ),
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
