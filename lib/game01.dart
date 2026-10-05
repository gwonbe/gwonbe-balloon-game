import 'dart:async';
import 'dart:math';
import 'package:balloon_game/utils/app_bgm.dart';
import 'package:balloon_game/utils/bgm_player.dart';
import 'package:flutter/material.dart';

/// 게임 01: 풍선 터뜨리기
class Game01Screen extends StatefulWidget {
  const Game01Screen({super.key});

  @override
  State<Game01Screen> createState() => _Game01ScreenState();
}

/// 단계별 설정: 제한 시간, 목표 풍선 개수, 풍선 속도/크기 범위, 스폰 밀도
class LevelConfig {
  final int level;
  final int durationSeconds;
  final int requiredBalloons;
  final double minSpeed; // px/sec
  final double maxSpeed; // px/sec
  final double minSize;
  final double maxSize;
  final double spawnMultiplier; // 목표 개수 대비 실제 화면에 나오는 풍선 배율

  const LevelConfig({
    required this.level,
    required this.durationSeconds,
    required this.requiredBalloons,
    required this.minSpeed,
    required this.maxSpeed,
    required this.minSize,
    required this.maxSize,
    required this.spawnMultiplier,
  });
}

/// 9단계: 시간 60->20초(5초씩 감소), 목표 개수 16->48개(4개씩 증가),
/// 단계가 오를수록 풍선은 더 빠르고/작아지고, 화면에 더 많이 나옵니다.
final List<LevelConfig> kLevels = List.generate(9, (i) {
  return LevelConfig(
    level: i + 1,
    durationSeconds: 60 - i * 5,
    requiredBalloons: 16 + i * 4,
    minSpeed: (90 + i * 15).toDouble(),
    maxSpeed: (160 + i * 20).toDouble(),
    minSize: (50 - i * 3).clamp(26, 100).toDouble(),
    maxSize: (85 - i * 5).clamp(40, 120).toDouble(),
    spawnMultiplier: 1.3 + i * 0.1,
  );
});

enum _GameStatus {
  ready, // 시작 전
  playing, // 진행 중
  paused, // 일시정지
  levelCleared, // 해당 단계 목표 달성
  levelFailed, // 시간 초과로 실패
  allCleared, // 마지막 단계까지 모두 클리어
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
  Timer? _spawnTimer; // 목표 개수만큼 풍선을 시간 내에 골고루 생성
  Timer? _frameTimer; // 풍선 위치 업데이트(약 60fps)

  int _levelIndex = 0; // 0-based (0 -> 단계 1)
  LevelConfig get _currentLevel => kLevels[_levelIndex];

  final BgmPlayer _bgm = BgmPlayer();

  // 목표 개수보다 실제로 화면에 더 많은 풍선이 나오도록 하는 배율
  // (클리어 조건인 목표 개수는 그대로 유지, 화면만 더 풍성하게)
  int get _totalSpawnCount =>
      (_currentLevel.requiredBalloons * _currentLevel.spawnMultiplier).round();

  int _score = 0; // 이번 단계에서 터뜨린 풍선 수
  int _spawnedCount = 0; // 이번 단계에서 이미 생성된 풍선 수
  int _timeLeft = 0;

  _GameStatus _status = _GameStatus.ready;

  Size _screenSize = Size.zero;

  void _cancelAllTimers() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    _frameTimer?.cancel();
  }

  void _startLevel(int levelIndex) {
    _cancelAllTimers();
    final LevelConfig config = kLevels[levelIndex];

    setState(() {
      _levelIndex = levelIndex;
      _score = 0;
      _spawnedCount = 0;
      _timeLeft = config.durationSeconds;
      _status = _GameStatus.playing;
      _balloons.clear();
    });

    AppBgm.home.stop();
    _bgm.start(); // 이미 재생 중이면 무시되므로 단계가 넘어가도 음악이 끊기지 않음
    _startTimers();
  }

  /// 현재 _score / _timeLeft / _spawnedCount / _balloons 상태를 그대로 두고
  /// 세 개의 타이머만 (다시) 시작한다. 레벨 시작 및 일시정지 후 재개에 공용으로 사용.
  void _startTimers() {
    final LevelConfig config = _currentLevel;

    // 남은 시간 카운트다운
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_status != _GameStatus.playing) return;
      setState(() {
        _timeLeft--;
      });
      if (_timeLeft <= 0) {
        _onTimeUp();
      }
    });

    // 목표 개수보다 많은 풍선(_totalSpawnCount)이 제한 시간 안에 고르게 나오도록 간격 계산
    final int intervalMs =
    ((config.durationSeconds * 1000) / _totalSpawnCount).round();
    _spawnTimer = Timer.periodic(
      Duration(milliseconds: intervalMs.clamp(100, 5000)),
          (timer) {
        if (_status != _GameStatus.playing) return;
        if (_spawnedCount >= _totalSpawnCount) {
          timer.cancel();
          return;
        }
        _spawnBalloon();
      },
    );

    _frameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_status != _GameStatus.playing) return;
      _updateBalloons();
    });
  }

  void _pauseGame() {
    if (_status != _GameStatus.playing) return;
    _cancelAllTimers();
    _bgm.pause();
    setState(() {
      _status = _GameStatus.paused;
    });
  }

  void _resumeGame() {
    if (_status != _GameStatus.paused) return;
    setState(() {
      _status = _GameStatus.playing;
    });
    _bgm.resume();
    _startTimers();
  }

  void _onTimeUp() {
    _cancelAllTimers();
    setState(() {
      if (_score >= _currentLevel.requiredBalloons) {
        _status = (_levelIndex == kLevels.length - 1)
            ? _GameStatus.allCleared
            : _GameStatus.levelCleared;
      } else {
        _status = _GameStatus.levelFailed;
      }
    });
  }

  void _spawnBalloon() {
    if (_screenSize == Size.zero) return;
    final LevelConfig config = _currentLevel;
    final double size =
        config.minSize + _random.nextDouble() * (config.maxSize - config.minSize);
    final double x = _random.nextDouble(); // 0.0~1.0
    final double speed = config.minSpeed +
        _random.nextDouble() * (config.maxSpeed - config.minSpeed);
    setState(() {
      _spawnedCount++;
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
    if (_status != _GameStatus.playing) return;
    setState(() {
      _balloons.removeWhere((b) => b.id == balloon.id);
      _score++;
    });

    // 목표 개수를 다 터뜨렸다면 즉시 단계 클리어 처리
    if (_score >= _currentLevel.requiredBalloons) {
      _cancelAllTimers();
      setState(() {
        _status = (_levelIndex == kLevels.length - 1)
            ? _GameStatus.allCleared
            : _GameStatus.levelCleared;
      });
    }
  }

  void _goToNextLevel() {
    if (_levelIndex + 1 < kLevels.length) {
      _startLevel(_levelIndex + 1);
    }
  }

  void _retryLevel() {
    _startLevel(_levelIndex);
  }

  void _restartFromBeginning() {
    _startLevel(0);
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
                if (_status == _GameStatus.ready) _buildStartOverlay(),
                if (_status == _GameStatus.paused) _buildPausedOverlay(),
                if (_status == _GameStatus.levelCleared)
                  _buildLevelClearOverlay(),
                if (_status == _GameStatus.levelFailed)
                  _buildLevelFailedOverlay(),
                if (_status == _GameStatus.allCleared)
                  _buildAllClearedOverlay(),
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
    final LevelConfig config = kLevels[_levelIndex];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _circleButton(
                  Icons.arrow_back, () => Navigator.of(context).maybePop(),
                ),
                if (_status == _GameStatus.playing || _status == _GameStatus.paused) ...[
                  const SizedBox(height: 8),
                  _circleButton(
                    _status == _GameStatus.paused ? Icons.play_arrow : Icons.pause,
                    _status == _GameStatus.paused ? _resumeGame : _pauseGame,
                  ),
                ],
              ],
            ),

            // 오른쪽: 정보 칩 3개
            Row(
              children: [
                _infoChip(
                  icon: Icons.flag,
                  value: '${config.level}',
                  unit: '/${kLevels.length}',
                  width: 90,
                ),
                const SizedBox(width: 8),
                _infoChip(
                  icon: Icons.star,
                  value: '$_score',
                  unit: '/${config.requiredBalloons}',
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
            width: 22,
            child: Icon(
              icon,
              size: 18,
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
                fontSize: 15,
              ),
            ),
          ),

          // 오른쪽: 단위 고정
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
    final LevelConfig first = kLevels.first;
    return Container(
      color: Colors.black.withValues(alpha: 0.4),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(
                '총 ${kLevels.length}단계!\n'
                    '단계 ${first.level}: ${first.durationSeconds}초 안에 풍선 ${first.requiredBalloons}개를 터뜨리세요!\n'
                    '단계가 올라갈수록 풍선이 더 빠르고 작아져요!',
                style: const TextStyle(fontSize: 16, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _startLevel(0),
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

  Widget _buildDialogCard({
    required String title,
    required String message,
    required Color titleColor,
    required VoidCallback onPrimaryAction,
    required String primaryLabel,
    required Color primaryColor,
  }) {
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
              Text(
                title,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.center,
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
                    onPressed: onPrimaryAction,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      backgroundColor: primaryColor,
                    ),
                    child: Text(
                      primaryLabel,
                      style: const TextStyle(fontSize: 16, color: Colors.white),
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

  Widget _buildPausedOverlay() {
    return _buildDialogCard(
      title: '일시정지 ⏸️',
      message:
      '이어서 진행하세요!',
      titleColor: Colors.blueGrey,
      onPrimaryAction: _resumeGame,
      primaryLabel: '다시 시작',
      primaryColor: Colors.blue,
    );
  }

  Widget _buildLevelClearOverlay() {
    final LevelConfig cleared = kLevels[_levelIndex];
    return _buildDialogCard(
      title: '단계 ${cleared.level} 클리어! 🎉',
      message:
      '풍선 ${cleared.requiredBalloons}개를 모두 터뜨렸어요!\n'
          '다음 단계에 도전할까요?',
      titleColor: Colors.green,
      onPrimaryAction: _goToNextLevel,
      primaryLabel: '다음 단계',
      primaryColor: Colors.blue,
    );
  }

  Widget _buildLevelFailedOverlay() {
    return _buildDialogCard(
      title: '시간 종료! ⏰',
      message: '아쉬워요!\n같은 단계부터 다시 도전해 보세요!',
      titleColor: Colors.redAccent,
      onPrimaryAction: _retryLevel,
      primaryLabel: '다시 시도',
      primaryColor: Colors.orange,
    );
  }

  Widget _buildAllClearedOverlay() {
    return _buildDialogCard(
      title: '전체 클리어! 🏆',
      message: '${kLevels.length}개 단계을 모두 완료했어요!\n정말 대단해요!',
      titleColor: Colors.deepOrange,
      onPrimaryAction: _restartFromBeginning,
      primaryLabel: '처음부터',
      primaryColor: Colors.blue,
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
