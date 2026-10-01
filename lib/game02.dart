import 'dart:async';
import 'dart:math';
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

class NumberBalloon {
  final int id;
  final int value;
  double x; // 0.0 ~ 1.0 (가로 상대 위치)
  double y; // 세로 픽셀 위치 (위에서부터)
  final double size;
  final Color color;
  final double speed; // px/sec

  NumberBalloon({
    required this.id,
    required this.value,
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.speed,
  });
}

class _Game02ScreenState extends State<Game02Screen> {
  static const int gameDuration = 99; // 제한 시간(초)
  static const List<Color> balloonColors = [
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
  final List<NumberBalloon> _balloons = [];
  int _nextId = 0;

  Timer? _gameTimer; // 1초마다 남은 시간 감소
  Timer? _spawnTimer; // 숫자 풍선 주기적 생성
  Timer? _frameTimer; // 풍선 위치 업데이트(약 60fps)

  _GameStatus _status = _GameStatus.ready;
  int _score = 0;
  int _timeLeft = gameDuration;

  // 현재 문제
  int _operand1 = 0;
  int _operand2 = 0;
  String _operator = '+'; // '+', '-', '*', '/'
  int _answer = 0;

  Size _screenSize = Size.zero;

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

  bool get _hasCorrectOnScreen =>
      _balloons.any((b) => b.value == _answer);

  void _cancelAllTimers() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    _frameTimer?.cancel();
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

  int _randomWrongNumber() {
    final int maxVal = _wrongRangeMax();
    int wrong;
    do {
      wrong = _random.nextInt(maxVal + 1);
    } while (wrong == _answer);
    return wrong;
  }

  void _startGame() {
    _cancelAllTimers();
    setState(() {
      _score = 0;
      _timeLeft = gameDuration;
      _status = _GameStatus.playing;
      _balloons.clear();
      _generateQuestion();
    });

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_status != _GameStatus.playing) return;
      setState(() {
        _timeLeft--;
      });
      if (_timeLeft <= 0) {
        _endGame();
      }
    });

    _spawnTimer = Timer.periodic(const Duration(milliseconds: 900), (timer) {
      if (_status != _GameStatus.playing) return;
      _spawnBalloon();
    });

    _frameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_status != _GameStatus.playing) return;
      _updateBalloons();
    });

    // 시작하자마자 정답 풍선이 하나는 보이도록 즉시 스폰
    _spawnBalloon(forceCorrect: true);
  }

  void _endGame() {
    _cancelAllTimers();
    setState(() {
      _status = _GameStatus.gameOver;
    });
  }

  void _spawnBalloon({bool forceCorrect = false}) {
    if (_screenSize == Size.zero) return;

    final int value =
    (forceCorrect || !_hasCorrectOnScreen) ? _answer : _randomWrongNumber();

    final double size = 55 + _random.nextDouble() * 35; // 55~90
    final double x = _random.nextDouble(); // 0.0~1.0
    final double speed = 70 + _random.nextDouble() * 80; // px/sec

    setState(() {
      _balloons.add(
        NumberBalloon(
          id: _nextId++,
          value: value,
          x: x,
          y: _screenSize.height,
          size: size,
          color: balloonColors[_random.nextInt(balloonColors.length)],
          speed: speed,
        ),
      );
    });
  }

  void _updateBalloons() {
    setState(() {
      for (final b in _balloons) {
        b.y -= b.speed * 0.03;
      }
      _balloons.removeWhere((b) => b.y + b.size < 0);
    });
  }

  void _popBalloon(NumberBalloon balloon) {
    if (_status != _GameStatus.playing) return;
    final bool correct = balloon.value == _answer;

    setState(() {
      _balloons.removeWhere((b) => b.id == balloon.id);
    });

    if (correct) {
      setState(() {
        _score++;
        _balloons.clear();
        _generateQuestion();
      });
      // 새 문제에 대한 정답 풍선을 바로 하나 띄워줌
      _spawnBalloon(forceCorrect: true);
    }
  }

  @override
  void dispose() {
    _cancelAllTimers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          _screenSize = Size(constraints.maxWidth, constraints.maxHeight);
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
                ..._balloons.map(_buildNumberBalloon),
                _buildTopBar(),
                if (_status == _GameStatus.ready) _buildStartOverlay(),
                if (_status == _GameStatus.gameOver) _buildGameOverOverlay(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNumberBalloon(NumberBalloon b) {
    final double maxLeft =
    (_screenSize.width - b.size).clamp(0, double.infinity);
    final double left = b.x * maxLeft;
    return Positioned(
      left: left,
      top: b.y,
      child: GestureDetector(
        onTap: () => _popBalloon(b),
        child: _LabeledBalloonWidget(
          size: b.size,
          color: b.color,
          label: '${b.value}',
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                '계산식의 정답이 적힌 풍선을 터뜨리세요!\n$gameDuration초 동안 최대한 많이 맞혀보세요!',
                style: TextStyle(fontSize: 16, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    child: const Text('게임 중단'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _startGame,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
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

/// 숫자/연산자 텍스트가 표시된 풍선 위젯 (떠오르는 풍선과 상단 문제 풍선 공용)
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