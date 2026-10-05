import 'dart:async';
import 'dart:math';
import 'package:balloon_game/utils/app_bgm.dart';
import 'package:balloon_game/utils/bgm_player.dart';
import 'package:flutter/material.dart';

class Game02Screen extends StatefulWidget {
  const Game02Screen({super.key});

  @override
  State<Game02Screen> createState() => _Game02ScreenState();
}

enum _GameStatus {
  ready, // 시작 전
  playing, // 진행 중
  gameOver, // 시간 종료
}

class _Game02ScreenState extends State<Game02Screen> {
  static const int gameDuration = 99; // 제한 시간(초)
  static const int gridCount = 9; // 3x3
  final BgmPlayer _bgm = BgmPlayer();

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

  // 3x3 그리드 (고정 위치, 매 문제마다 값/색만 교체)
  List<int> _gridValues = List.filled(gridCount, 0);
  List<Color> _gridColors = List.filled(gridCount, Colors.blue);

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

  void _cancelAllTimers() {
    _gameTimer?.cancel();
    _feedbackTimer?.cancel();
  }

  void _generateQuestion() {
    final List<String> ops = ['+', '-', '*', '/'];
    final String op = ops[_random.nextInt(ops.length)];
    int a, b, answer;

    switch (op) {
      case '-':
        a = _random.nextInt(10); // 0~9
        b = _random.nextInt(10); // 0~9
        if (a < b) {
          final int t = a;
          a = b;
          b = t;
        }
        answer = a - b;
        break;
      case '*':
        a = _random.nextInt(10); // 0~9
        b = _random.nextInt(10); // 0~9
        answer = a * b;
        break;
      case '/':
        b = 1 + _random.nextInt(9); // 1~9 (0으로 나누기 방지)
        final int maxQ = 9 ~/ b; // 피연산자(a)도 한 자리 수가 되도록 몫 제한
        final int q = _random.nextInt(maxQ + 1); // 0~maxQ
        a = b * q;
        answer = q;
        break;
      case '+':
      default:
        a = _random.nextInt(10); // 0~9
        b = _random.nextInt(10); // 0~9
        answer = a + b;
        break;
    }

    _operand1 = a;
    _operand2 = b;
    _operator = op;
    _answer = answer;
  }

  int _wrongRangeMax() {
    switch (_operator) {
      case '-':
        return 9;
      case '*':
        return 81;
      case '/':
        return 9;
      case '+':
      default:
        return 18;
    }
  }

  /// 정답 1개 + 서로 다른 오답 8개를 뽑아 9칸에 무작위로 배치하고,
  /// 색상도 매번 섞어서 모두 다르게 배정한다.
  void _generateGrid() {
    final int maxVal = _wrongRangeMax();
    final List<int> pool = [
      for (int i = 0; i <= maxVal; i++)
        if (i != _answer) i,
    ];
    pool.shuffle(_random);

    final List<int> values = [_answer, ...pool.take(gridCount - 1)];
    values.shuffle(_random);

    final List<Color> colors = List<Color>.from(balloonColorPalette);
    colors.shuffle(_random);
    // 팔레트가 9개보다 적을 경우를 대비한 안전장치
    while (colors.length < gridCount) {
      colors.add(balloonColorPalette[_random.nextInt(balloonColorPalette.length)]);
    }

    setState(() {
      _gridValues = values;
      _gridColors = colors.take(gridCount).toList();
    });
  }

  void _startGame() {
    _cancelAllTimers();
    _generateQuestion();
    setState(() {
      _score = 0;
      _timeLeft = gameDuration;
      _status = _GameStatus.playing;
      _feedbackText = null;
    });
    _generateGrid();

    AppBgm.home.stop();
    _bgm.start(); // 이미 재생 중이면 무시되므로 '다시 시작'해도 음악이 끊기지 않음

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_status != _GameStatus.playing) return;
      setState(() {
        _timeLeft--;
      });
      if (_timeLeft <= 0) {
        _endGame();
      }
    });
  }

  void _endGame() {
    _cancelAllTimers();
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
    if (_status != _GameStatus.playing) return;
    if (_feedbackText != null) return; // 메시지 표시 중 중복 탭 방지

    final int value = _gridValues[index];
    if (value == _answer) {
      setState(() {
        _score++;
      });
      _showFeedback(true);
      _generateQuestion();
      _generateGrid();
    } else {
      _showFeedback(false);
    }
  }

  @override
  void dispose() {
    _cancelAllTimers();
    _bgm.dispose();
    AppBgm.home.start();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                if (_status == _GameStatus.playing)
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
                _buildTopBar(),
                if (_feedbackText != null) _buildFeedbackOverlay(),
                if (_status == _GameStatus.ready) _buildStartOverlay(),
                if (_status == _GameStatus.gameOver) _buildGameOverOverlay(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrid(BoxConstraints constraints) {
    const int columns = 3;
    const double gap = 16;
    final double gridWidth = min(constraints.maxWidth * 0.85, 340);
    final double cellSize = (gridWidth - gap * (columns - 1)) / columns;

    return SizedBox(
      width: gridWidth,
      child: Wrap(
        spacing: gap,
        runSpacing: gap,
        children: List.generate(gridCount, (index) {
          return GestureDetector(
            onTap: () => _onTapCell(index),
            child: _LabeledBalloonWidget(
              size: cellSize,
              color: _gridColors[index],
              label: '${_gridValues[index]}',
            ),
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

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _circleButton(
                  Icons.arrow_back,
                      () => Navigator.of(context).maybePop(),
                ),
                Row(
                  children: [
                    _infoChip(
                      icon: Icons.star,
                      value: '$_score',
                      unit: '점',
                      width: 95,
                    ),
                    const SizedBox(width: 8),
                    _infoChip(
                      icon: Icons.timer,
                      value: '$_timeLeft',
                      unit: '초',
                      width: 90,
                    ),
                  ],
                ),
              ],
            ),
            if (_status == _GameStatus.playing) ...[
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
            color: Colors.blueAccent,
            label: '$_operand1',
          ),
          const SizedBox(width: 10),
          _LabeledBalloonWidget(
            size: 56,
            color: Colors.redAccent,
            label: _operatorSymbol,
          ),
          const SizedBox(width: 10),
          _LabeledBalloonWidget(
            size: 56,
            color: Colors.blueAccent,
            label: '$_operand2',
          ),
        ],
      ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String value,
    required String unit,
    double width = 105,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Icon(
              icon,
              size: 18,
              color: Colors.deepOrange,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          Text(
            unit,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withValues(alpha: 0.85),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.black87),
        ),
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
                '계산식의 정답을 찾아 터뜨리세요!\n$gameDuration초 동안 최대한 많이 맞혀보세요!',
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
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '시간 종료! ⏰',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                '최종 점수 : $_score',
                style: const TextStyle(fontSize: 20, color: Colors.deepOrange),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('게임 중단'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _startGame,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text(
                      '다시 시작',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 숫자/연산자 텍스트가 표시된 풍선 위젯 (그리드와 상단 문제 풍선 공용)
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
            painter: _BalloonPainter(color: color),
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

class _BalloonPainter extends CustomPainter {
  final Color color;

  _BalloonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final Rect balloonRect = Rect.fromLTWH(0, 0, size.width, size.height * 0.8);
    final RRect rect = RRect.fromRectAndCorners(
      balloonRect,
      topLeft: Radius.circular(size.width / 2),
      topRight: Radius.circular(size.width / 2),
      bottomLeft: Radius.circular(size.width / 2.5),
      bottomRight: Radius.circular(size.width / 2.5),
    );
    canvas.drawRRect(rect, paint);

    // 하이라이트(반짝임)
    final Paint highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4);
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.2,
        size.height * 0.15,
        size.width * 0.2,
        size.height * 0.15,
      ),
      highlightPaint,
    );

    // 풍선 줄
    final Paint stringPaint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final Path path = Path()
      ..moveTo(size.width / 2, size.height * 0.8)
      ..lineTo(size.width / 2, size.height);
    canvas.drawPath(path, stringPaint);
  }

  @override
  bool shouldRepaint(covariant _BalloonPainter oldPainter) {
    return oldPainter.color != color;
  }
}
