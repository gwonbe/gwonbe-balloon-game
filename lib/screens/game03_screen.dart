import 'dart:async';
import 'dart:math';
import 'package:balloon_game/utils/base_game_state.dart';
import 'package:balloon_game/utils/game_storage.dart';
import 'package:balloon_game/widgets/balloon_painter.dart';
import 'package:balloon_game/widgets/info_chip.dart';
import 'package:flutter/material.dart';

class Game03Screen extends StatefulWidget {
  const Game03Screen({super.key});

  @override
  State<Game03Screen> createState() => _Game03ScreenState();
}

enum _GameStatus {
  ready, // 시작 전
  playing, // 진행 중
  gameOver, // 시간 종료
}

class _Game03ScreenState extends BaseGameState<Game03Screen> {
  static const int gameDuration = 60; // 제한 시간(초)
  static const int gridCount = 25; // 5x5

  static const List<Color> balloonColorPalette = [
    Colors.red,
    Colors.pink,
    Colors.orange,
    Colors.amber,
    Colors.green,
    Colors.teal,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
  ];

  final Random _random = Random();

  Timer? _gameTimer; // 1초마다 남은 시간 감소
  Timer? _feedbackTimer; // 정답/오답 메시지 자동으로 사라지게

  _GameStatus _status = _GameStatus.ready;
  int _score = 0;
  int _timeLeft = gameDuration;

  // 현재 문제
  int _operand1 = 0;
  int _operand2 = 0;
  String _operator = '+'; // '+', '-', '*', '/'
  int _answer = 0;

  // 5x5 풍선판
  List<Color> _gridColors = List.filled(gridCount, Colors.blue);
  List<bool> _gridActive = List.filled(gridCount, true);
  Color _targetColor = Colors.blue;
  int _poppedTargetCount = 0;

  // 정답/오답 피드백 메시지
  String? _feedbackText;
  bool _feedbackCorrect = false;

  String get _operatorSymbol {
    switch (_operator) {
      case '*':
        return '×';
      case '/':
        return '÷';
      default:
        return _operator;
    }
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
  }

  @override
  void startTimers() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // 일시정지 중이거나 플레이 중이 아니면 카운트하지 않음
      if (_status != _GameStatus.playing || isPaused) return;
      setState(() {
        _timeLeft--;
      });
      if (_timeLeft <= 0) {
        _endGame();
      }
    });
  }

  @override
  void onPause() {
    _feedbackText = null;
  }

  // ───────── 게임 로직 ─────────

  void _generateQuestion() {
    final List<String> ops = ['+', '-', '*', '/'];
    final String op = ops[_random.nextInt(ops.length)];
    int a, b, answer;

    switch (op) {
      case '-':
        b = 1 + _random.nextInt(24);
        a = b + 1 + _random.nextInt(25 - b);
        answer = a - b;
        break;
      case '*':
        a = 1 + _random.nextInt(5);
        final int maxB = 25 ~/ a;
        b = 1 + _random.nextInt(maxB);
        answer = a * b;
        break;
      case '/':
        answer = 1 + _random.nextInt(25);
        b = 1 + _random.nextInt(25 ~/ answer);
        a = answer * b;
        break;
      case '+':
      default:
        a = 1 + _random.nextInt(24);
        b = 1 + _random.nextInt(25 - a);
        answer = a + b;
        break;
    }

    _operand1 = a;
    _operand2 = b;
    _operator = op;
    _answer = answer;
    _targetColor = balloonColorPalette[_random.nextInt(balloonColorPalette.length)];
    _poppedTargetCount = 0;
  }

  /// 정답 개수만큼 목표 색 풍선을 배치하고, 나머지는 다른 색상들로 랜덤하게 채운다.
  void _generateGrid() {
    final int requiredTargetCount = _answer.clamp(1, gridCount);
    final List<Color> otherColors = balloonColorPalette
        .where((color) => color != _targetColor)
        .toList();

    final List<Color> colors = [];
    // 정답 개수만큼 목표 색상 추가
    for (int i = 0; i < requiredTargetCount; i++) {
      colors.add(_targetColor);
    }
    // 남은 칸은 다른 색상들로 무작위 채우기
    while (colors.length < gridCount) {
      colors.add(otherColors[_random.nextInt(otherColors.length)]);
    }
    colors.shuffle(_random);

    setState(() {
      _gridColors = List<Color>.from(colors);
      // 풍선판을 완전히 새롭게 초기화 (모든 풍선 활성화, 터트린 카운트 초기화)
      _gridActive = List<bool>.filled(gridCount, true);
      _poppedTargetCount = 0;
    });
  }

  /// 정답을 맞혔을 때 새 식과 새 풍선판을 준비한다.
  void _startNextRound() {
    _generateQuestion();
    _generateGrid();
  }

  void _startGame() {
    cancelAllTimers();
    registerGameStart();
    _generateQuestion();
    setState(() {
      _score = 0;
      _timeLeft = gameDuration;
      _status = _GameStatus.playing;
      _feedbackText = null;
    });
    _generateGrid();

    startBgm();
    startTimers();
  }

  void _endGame() {
    cancelAllTimers();
    stopBgm();
    setState(() {
      _status = _GameStatus.gameOver;
      _feedbackText = null;
    });
  }

  void _showFeedback(bool correct) {
    _feedbackTimer?.cancel();
    setState(() {
      _feedbackCorrect = correct;
      _feedbackText = correct ? '딩동댕!' : '땡!';
    });
    _feedbackTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _feedbackText = null;
      });
    });
  }

  void _onTapCell(int index) {
    if (_status != _GameStatus.playing || isPaused) return;
    if (_feedbackText != null || !_gridActive[index]) return;

    final bool isTargetColor = _gridColors[index] == _targetColor;
    setState(() {
      _gridActive[index] = false; // 터뜨린 풍선은 즉시 제거
      if (isTargetColor) _poppedTargetCount++;
    });

    if (!isTargetColor) {
      _showFeedback(false);
      return;
    }

    if (_poppedTargetCount == _answer) {
      setState(() {
        _score++;
      });
      _showFeedback(true);
      _startNextRound();
    }
  }

  // ───────── UI ─────────

  @override
  Widget build(BuildContext context) {
    final bool showBoard = _status == _GameStatus.playing && !isPaused;

    return withSystemBackPause(
      Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF87CEEB), Color(0xFFE0F7FA)],
                ),
              ),
              child: Stack(
                children: [
                  if (showBoard)
                    Positioned.fill(
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 140),
                          child: Center(
                            child: _buildGrid(constraints),
                          ),
                        ),
                      ),
                    ),
                  _buildTopBar(showBoard),
                  if (_feedbackText != null) _buildFeedbackOverlay(),
                  if (_status == _GameStatus.ready) _buildStartOverlay(),
                  if (_status == _GameStatus.gameOver) _buildGameOverOverlay(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGrid(BoxConstraints constraints) {
    const int columns = 5;
    const double gap = 5;
    final double gridWidth = min(constraints.maxWidth * 0.94, 390);
    final double cellSize = (gridWidth - gap * (columns - 1)) / columns;

    return SizedBox(
      width: gridWidth,
      child: Wrap(
        spacing: gap,
        runSpacing: 2,
        children: List.generate(gridCount, (index) {
          return SizedBox(
            width: cellSize,
            height: cellSize * 1.3,
            child: _gridActive[index]
                ? GestureDetector(
              onTap: () => _onTapCell(index),
              child: _LabeledBalloonWidget(
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
  }

  Widget _buildFeedbackOverlay() {
    return Center(
      child: AnimatedOpacity(
        opacity: _feedbackText != null ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: BoxDecoration(
            color: (_feedbackCorrect ? Colors.green : Colors.red)
                .withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            _feedbackText ?? '',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(bool showBoard) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                buildPauseButton(),
                Row(
                  children: [
                    InfoChip(
                      icon: Icons.star,
                      value: '$_score',
                      unit: '점',
                      width: 95,
                    ),
                    const SizedBox(width: 8),
                    InfoChip(
                      icon: Icons.timer,
                      value: '$_timeLeft',
                      unit: '초',
                      width: 90,
                    ),
                  ],
                ),
              ],
            ),
            if (showBoard) ...[
              const SizedBox(height: 14),
              _buildQuestionBoard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionBoard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LabeledBalloonWidget(
            size: 56,
            color: _targetColor,
            label: '$_operand1',
          ),
          const SizedBox(width: 10),
          _LabeledBalloonWidget(
            size: 56,
            color: _targetColor,
            label: _operatorSymbol,
          ),
          const SizedBox(width: 10),
          _LabeledBalloonWidget(
            size: 56,
            color: _targetColor,
            label: '$_operand2',
          ),
        ],
      ),
    );
  }

  Widget _buildStartOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.4),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '계산식 색깔의 풍선을 정답 개수만큼 터뜨리세요!\n60초 동안 도전하세요!',
                style: TextStyle(fontSize: 16, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  backgroundColor: Colors.orange,
                ),
                child: const Text(
                  '게임 시작',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return buildDialogCard(
      title: '시간 종료! ⏰',
      message: '최종 점수 : $_score',
      titleColor: Colors.black87,
      onPrimaryAction: () => Navigator.of(context).maybePop(),
      primaryLabel: '확인',
      primaryColor: Colors.blue,
      showQuitButton: false,
    );
  }
}

class _LabeledBalloonWidget extends StatelessWidget {
  final double size;
  final Color color;
  final String label;

  const _LabeledBalloonWidget({
    required this.size,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.3,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(size, size * 1.3),
            painter: BalloonPainter(color: color),
          ),
          Align(
            alignment: const Alignment(0, -0.35),
            child: Text(
              label,
              style: TextStyle(
                fontSize: size * 0.34,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: const [
                  Shadow(
                    color: Colors.black38,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}