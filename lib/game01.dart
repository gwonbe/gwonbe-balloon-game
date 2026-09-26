import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// 게임 01: 풍선 터뜨리기
class Game01Screen extends StatefulWidget {
  const Game01Screen({super.key});

  @override
  State<Game01Screen> createState() => _Game01ScreenState();
}

class Balloon {
  final int id;
  double x; // 0.0 ~ 1.0 (가로 상대 위치)
  double y; // 세로 픽셀 위치 (위에서부터)
  final double size;
  final Color color;
  final double speed; // px/sec

  Balloon({
    required this.id,
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.speed,
  });
}

class _Game01ScreenState extends State<Game01Screen> {
  static const int gameDuration = 30; // 제한 시간(초)
  static const List<Color> balloonColors = [
    Colors.red,
    Colors.pink,
    Colors.orange,
    Colors.amber,
    Colors.green,
    Colors.blue,
    Colors.purple,
  ];

  final Random _random = Random();
  final List<Balloon> _balloons = [];
  int _nextId = 0;

  Timer? _gameTimer; // 1초마다 남은 시간 감소
  Timer? _spawnTimer; // 주기적으로 풍선 생성
  Timer? _frameTimer; // 풍선 위치 업데이트(약 60fps)

  int _score = 0;
  int _timeLeft = gameDuration;
  bool _isPlaying = false;
  bool _isGameOver = false;

  Size _screenSize = Size.zero;

  void _startGame() {
    setState(() {
      _score = 0;
      _timeLeft = gameDuration;
      _isPlaying = true;
      _isGameOver = false;
      _balloons.clear();
    });

    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    _frameTimer?.cancel();

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeLeft--;
      });
      if (_timeLeft <= 0) {
        _endGame();
      }
    });

    _spawnTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      _spawnBalloon();
    });

    _frameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _updateBalloons();
    });
  }

  void _endGame() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    _frameTimer?.cancel();
    setState(() {
      _isPlaying = false;
      _isGameOver = true;
    });
  }

  void _spawnBalloon() {
    if (_screenSize == Size.zero) return;
    final double size = 50 + _random.nextDouble() * 40; // 50~90
    final double x = _random.nextDouble(); // 0.0~1.0
    final double speed = 60 + _random.nextDouble() * 90; // px/sec
    setState(() {
      _balloons.add(
        Balloon(
          id: _nextId++,
          x: x,
          y: _screenSize.height, // 화면 아래에서 시작
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
        b.y -= b.speed * 0.03; // 위로 이동
      }
      _balloons.removeWhere((b) => b.y + b.size < 0);
    });
  }

  void _popBalloon(Balloon balloon) {
    if (!_isPlaying) return;
    setState(() {
      _balloons.removeWhere((b) => b.id == balloon.id);
      _score++;
    });
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    _frameTimer?.cancel();
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
                ..._balloons.map(_buildBalloon),
                _buildTopBar(),
                if (!_isPlaying && !_isGameOver) _buildStartOverlay(),
                if (_isGameOver) _buildGameOverOverlay(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalloon(Balloon b) {
    final double maxLeft =
        (_screenSize.width - b.size).clamp(0, double.infinity);
    final double left = b.x * maxLeft;
    return Positioned(
      left: left,
      top: b.y,
      child: GestureDetector(
        onTap: () => _popBalloon(b),
        child: _BalloonWidget(size: b.size, color: b.color),
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
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
                  width: 105,
                ),
                const SizedBox(width: 10),
                _infoChip(
                  icon: Icons.timer,
                  value: '$_timeLeft',
                  unit: '초',
                  width: 105,
                ),
              ],
            ),
          ],
        ),
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
          // 왼쪽: 아이콘 고정
          SizedBox(
            width: 24,
            child: Icon(
              icon,
              size: 20,
              color: Colors.deepOrange,
            ),
          ),

          // 가운데: 숫자만 가운데 정렬
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          // 오른쪽: 단위 고정
          SizedBox(
            width: 20,
            child: Text(
              unit,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
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
                '🎈 풍선 터뜨리기 🎈',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '$gameDuration초 안에 풍선을 최대한 많이 터뜨리세요!',
                style: const TextStyle(fontSize: 16, color: Colors.white),
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
                '게임 종료!',
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
                    child: const Text('목록으로'),
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
                      '다시 하기',
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

class _BalloonWidget extends StatelessWidget {
  final double size;
  final Color color;

  const _BalloonWidget({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.3,
      child: CustomPaint(
        painter: _BalloonPainter(color: color),
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
