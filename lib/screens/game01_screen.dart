import 'dart:async';
import 'dart:math';
import 'package:pangteojyo/l10n/app_localizations.dart';
import 'package:pangteojyo/utils/app_const.dart';
import 'package:pangteojyo/utils/base_game_state.dart';
import 'package:pangteojyo/utils/game_storage.dart';
import 'package:pangteojyo/widgets/balloon_painter.dart';
import 'package:pangteojyo/widgets/info_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class Game01Screen extends StatefulWidget {
  const Game01Screen({super.key});

  @override
  State<Game01Screen> createState() => _Game01ScreenState();
}

// ───────── 상수 / 설정 ─────────

/// 전체 단계 수
const int kLevelCount = 5;

/// 모든 단계 공통 제한 시간(초)
const int kLevelDurationSeconds = 32;

/// 풍선을 놓치거나 폭탄에 닿아 이 횟수만큼 생명을 잃으면 게임 종료
const int kMaxMiss = 5;

/// 모든 단계 공통 풍선 크기 범위 (단계가 올라가도 크기는 그대로)
const double kBalloonMinSize = 45;
const double kBalloonMaxSize = 75;

/// 기존 동작(프레임당 speed * 0.03, 16ms 간격)과 같은 체감 속도를 유지하기 위한 배율.
/// 실제 이동 속도(px/sec) = speed * 이 값
const double _kSpeedScale = 1.875;

/// 실제 풍선보다 터치 영역을 사방으로 20px씩 확장
const double touchPadding = 20;

/// 단계별 설정: 풍선 속도 범위, 제한 시간 동안 나오는 풍선 수
class LevelConfig {
  final int level;
  final int spawnCount; // 제한 시간 동안 화면에 나오는 풍선 총 개수
  final double minSpeed;
  final double maxSpeed;

  const LevelConfig({
    required this.level,
    required this.spawnCount,
    required this.minSpeed,
    required this.maxSpeed,
  });
}

/// 모든 단계 제한 시간과 풍선 크기는 같고,
/// 단계가 오를수록 풍선이 빨라지고 화면에 더 많이 나온다.
final List<LevelConfig> kLevels = List.generate(kLevelCount, (i) {
  return LevelConfig(
    level: i + 1,
    spawnCount: 20 + i * 8,
    minSpeed: (100 + i * 30).toDouble(), // 100, 130, 160, 190, 220
    maxSpeed: (160 + i * 45).toDouble(), // 160, 205, 250, 295, 340
  );
});

enum _GameStatus {
  ready, // 시작 전
  playing, // 진행 중 (일시정지는 부모의 isPaused로 관리)
  levelCleared, // 제한 시간을 버텨서 해당 단계 클리어
  levelFailed, // 풍선을 kMaxMiss개 놓쳐서 실패
  allCleared, // 마지막 단계까지 모두 클리어
}

// ───────── 모델 ─────────

class Balloon {
  final int id;
  final double x; // 0.0 ~ 1.0 (가로 상대 위치)
  double y; // 세로 픽셀 위치 (위에서부터)
  final double size;
  final Color color;
  final double speed;
  bool isPopping = false;

  Balloon({
    required this.id,
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.speed,
  });
}

class Bomb {
  final int id;
  final double x;
  double y;
  final double size;
  final double speed;
  bool isExploding = false;

  Bomb({
    required this.id,
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
  });
}

class _BombPainter extends CustomPainter {
  const _BombPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width * 0.48, size.height * 0.59);
    final double radius = size.width * 0.32;

    canvas.drawCircle(
      center + const Offset(1.5, 2.5),
      radius,
      Paint()..color = Colors.black.withValues(alpha: 0.22),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A4A4A), Color(0xFF171717)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(-radius * 0.32, -radius * 0.35),
        width: radius * 0.48,
        height: radius * 0.28,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.28),
    );

    final Path fuse = Path()
      ..moveTo(center.dx + radius * 0.55, center.dy - radius * 0.62)
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.24,
        size.width * 0.72,
        size.height * 0.12,
      );
    canvas.drawPath(
      fuse,
      Paint()
        ..color = const Color(0xFF795548)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.09
        ..strokeCap = StrokeCap.round,
    );

    final Offset spark = Offset(size.width * 0.74, size.height * 0.12);
    final Paint sparkPaint = Paint()
      ..color = const Color(0xFFFFB300)
      ..strokeWidth = size.width * 0.055
      ..strokeCap = StrokeCap.round;
    for (final Offset ray in const [
      Offset(-0.10, -0.04),
      Offset(0.08, -0.09),
      Offset(0.13, 0.05),
      Offset(-0.02, 0.11),
    ]) {
      canvas.drawLine(
        spark + Offset(ray.dx * size.width * 0.55, ray.dy * size.height * 0.55),
        spark + Offset(ray.dx * size.width, ray.dy * size.height),
        sparkPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BombPainter oldDelegate) => false;
}

class _ExplosionPainter extends CustomPainter {
  final double progress;

  const _ExplosionPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double fade = (1 - progress).clamp(0.0, 1.0);
    final double radius = size.width * (0.19 + progress * 0.42);

    canvas.drawCircle(
      center,
      radius * 0.78,
      Paint()
        ..color = const Color(0xFFFF5722).withValues(alpha: fade * 0.52)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Curved flame tongues expand around the blast and fade with the bomb.
    for (int i = 0; i < 12; i++) {
      final double angle = (i * pi / 6) + progress * 0.22;
      final double innerRadius = radius * (0.4 + (i.isEven ? 0.12 : 0));
      final double outerRadius = radius * (1.0 + (i % 3) * 0.14);
      final double halfWidth = radius * (i.isEven ? 0.18 : 0.14);
      final Offset direction = Offset(cos(angle), sin(angle));
      final Offset tangent = Offset(-direction.dy, direction.dx);
      final Offset base = center + direction * innerRadius;
      final Offset tip = center + direction * outerRadius;
      final double curveRadius = (innerRadius + outerRadius) * 0.42;
      final Path flame = Path()
        ..moveTo(base.dx - tangent.dx * halfWidth, base.dy - tangent.dy * halfWidth)
        ..quadraticBezierTo(
          center.dx + direction.dx * curveRadius - tangent.dx * halfWidth * 0.45,
          center.dy + direction.dy * curveRadius - tangent.dy * halfWidth * 0.45,
          tip.dx,
          tip.dy,
        )
        ..quadraticBezierTo(
          center.dx + direction.dx * curveRadius + tangent.dx * halfWidth * 0.45,
          center.dy + direction.dy * curveRadius + tangent.dy * halfWidth * 0.45,
          base.dx + tangent.dx * halfWidth,
          base.dy + tangent.dy * halfWidth,
        )
        ..close();
      canvas.drawPath(
        flame,
        Paint()
          ..color = (i.isEven ? const Color(0xFFFF5722) : const Color(0xFFFF9800))
              .withValues(alpha: fade),
      );
    }

    canvas.drawCircle(
      center,
      radius * 0.72,
      Paint()
        ..color = const Color(0xFFFFC107).withValues(alpha: fade * 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5 * fade,
    );
    canvas.drawCircle(
      center,
      radius * 0.34,
      Paint()
        ..color = const Color(0xFFFFF176).withValues(alpha: fade * 0.95)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  @override
  bool shouldRepaint(covariant _ExplosionPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// 풍선 레이어만 다시 그리게 하기 위한 알림 객체
class _FrameNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

// ───────── State ─────────

class _Game01ScreenState extends BaseGameState<Game01Screen>
    with SingleTickerProviderStateMixin {
  late AppLocalizations l10n;
  final Random _random = Random();
  final List<Balloon> _balloons = [];
  final List<Bomb> _bombs = [];
  final _FrameNotifier _frameNotifier = _FrameNotifier();
  int _nextId = 0;

  // 이동 / 스폰 / 남은 시간을 모두 이 Ticker 하나로 처리한다.
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  double _playTime = 0; // 이번 단계에서 실제로 플레이한 시간(초). 일시정지 시간은 제외

  int _maxLevelCleared = 0; // 이번 플레이에서 클리어한 최고 단계 (1~5, 시작 전이면 0)
  int _levelIndex = 0; // 0-based (0 -> 단계 1)
  LevelConfig get _currentLevel => kLevels[_levelIndex];

  int _miss = 0; // 이번 단계에서 잃은 생명 수
  int _spawnedCount = 0; // 이번 단계에서 이미 생성된 풍선 수
  int _spawnedBombCount = 0;
  int _timeLeft = kLevelDurationSeconds;

  _GameStatus _status = _GameStatus.ready;
  Size _screenSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frameNotifier.dispose();
    super.dispose();
  }

  // ───────── BaseGameState 구현부 ─────────

  @override
  bool get isPlaying => _status == _GameStatus.playing;

  @override
  String get bestScoreKey => GameStorage.bestScoreGame01;

  @override
  int get currentScore => _maxLevelCleared;

  @override
  void cancelAllTimers() {
    if (_ticker.isActive) _ticker.stop();
  }

  /// 현재 _miss / _playTime / _spawnedCount / _balloons 상태를 그대로 두고
  /// Ticker만 (다시) 시작한다. 단계 시작 및 일시정지 후 재개에 공용으로 사용.
  @override
  void startTimers() {
    _lastTick = Duration.zero; // Ticker는 시작할 때마다 elapsed가 0부터 시작
    if (!_ticker.isActive) _ticker.start();
  }

  // ───────── 게임 로직 ─────────

  void _startLevel(int levelIndex) {
    cancelAllTimers();
    registerGameStart();

    setState(() {
      _levelIndex = levelIndex;
      _miss = 0; // 단계가 시작될 때마다 미스 초기화
      _spawnedCount = 0;
      _spawnedBombCount = 0;
      _playTime = 0;
      _timeLeft = kLevelDurationSeconds;
      _status = _GameStatus.playing;
      _balloons.clear();
      _bombs.clear();
    });

    // 정지된 상태에서 시작하면 처음부터 재생된다.
    startBgm();
    startTimers();
  }

  /// 매 프레임 호출: 풍선 이동 -> 미스 판정 -> 스폰 -> 남은 시간 갱신
  void _onTick(Duration elapsed) {
    if (_status != _GameStatus.playing) return;

    // 프레임 간격(초). 앱이 잠깐 멈췄다 돌아왔을 때 풍선이 튀지 않도록 상한을 둔다.
    final double dt = ((elapsed - _lastTick).inMicroseconds / 1e6)
        .clamp(0.0, 0.05)
        .toDouble();
    _lastTick = elapsed;
    _playTime += dt;

    // 풍선 속도는 기존 계산을 유지하고 폭탄도 같은 단계 속도 범위로 이동한다.
    for (final b in _balloons) {
      b.y -= b.speed * _kSpeedScale * dt;
    }
    for (final bomb in _bombs) {
      if (!bomb.isExploding) {
        bomb.y -= bomb.speed * _kSpeedScale * dt;
      }
    }

    // 놓친 풍선은 생명을 줄이고, 화면 위로 지나간 폭탄은 사라진다.
    final int before = _balloons.length;
    _balloons.removeWhere((b) => !b.isPopping && b.y + b.size < 0);
    final int missed = before - _balloons.length;
    _bombs.removeWhere((bomb) => !bomb.isExploding && bomb.y + bomb.size < 0);

    // 3) 제한 시간 안에 풍선이 고르게 나오도록 스폰
    final int totalSpawn = _currentLevel.spawnCount;
    final double interval = kLevelDurationSeconds / totalSpawn;
    while (_spawnedCount < totalSpawn &&
        _playTime >= (_spawnedCount + 0.5) * interval) {
      _spawnBalloon();
    }

    // 폭탄 장애물은 단계가 오를수록 조금씩 더 자주 나타난다.
    final int totalBombs = 6 + _levelIndex * 2;
    final double bombInterval = kLevelDurationSeconds / totalBombs;
    while (_spawnedBombCount < totalBombs &&
        _playTime >= (_spawnedBombCount + 0.5) * bombInterval) {
      _spawnBomb();
    }

    // 풍선 레이어만 다시 그린다 (화면 전체 setState 아님)
    _frameNotifier.notify();

    // 4) 미스가 바뀐 경우에만 화면 전체 갱신
    if (missed > 0) {
      setState(() => _miss += missed);
      if (_miss >= kMaxMiss) {
        _failLevel();
        return;
      }
    }

    // 5) 남은 시간은 정수 초가 바뀔 때만 갱신
    final int left = (kLevelDurationSeconds - _playTime)
        .ceil()
        .clamp(0, kLevelDurationSeconds)
        .toInt();
    if (left != _timeLeft) {
      setState(() => _timeLeft = left);
    }

    // 시간이 끝났다는 것은 미스가 kMaxMiss 미만이라는 뜻 -> 단계 클리어
    if (_playTime >= kLevelDurationSeconds) {
      _finishLevelCleared();
    }
  }

  /// 단계 클리어 처리: 타이머 정지 + 음악 정지 + 상태 전환.
  void _finishLevelCleared() {
    cancelAllTimers();
    stopBgm();

    setState(() {
      _timeLeft = 0;
      if (_levelIndex + 1 > _maxLevelCleared) {
        _maxLevelCleared = _levelIndex + 1;
      }
      _status = _levelIndex == kLevels.length - 1
          ? _GameStatus.allCleared
          : _GameStatus.levelCleared;
    });

    unawaited(saveBestScore());
  }

  /// 생명을 모두 잃어 게임 종료
  void _failLevel() {
    cancelAllTimers();
    stopBgm(); // 실패 다이얼로그에서도 음악 정지
    setState(() => _status = _GameStatus.levelFailed);
  }

  /// 풍선 생성 (프레임 루프 안에서 호출되므로 setState를 쓰지 않는다)
  void _spawnBalloon() {
    if (_screenSize == Size.zero) return;
    final LevelConfig config = _currentLevel;
    final double size =
        kBalloonMinSize +
        _random.nextDouble() * (kBalloonMaxSize - kBalloonMinSize);
    final double speed =
        config.minSpeed +
        _random.nextDouble() * (config.maxSpeed - config.minSpeed);

    _spawnedCount++;
    _balloons.add(
      Balloon(
        id: _nextId++,
        x: _random.nextDouble(), // 0.0~1.0
        y: _screenSize.height, // 화면 아래에서 시작
        size: size,
        color: AppConst
            .balloonColors[_random.nextInt(AppConst.balloonColors.length)],
        speed: speed,
      ),
    );
  }

  void _spawnBomb() {
    if (_screenSize == Size.zero) return;
    final LevelConfig config = _currentLevel;
    final double speed =
        config.minSpeed +
        _random.nextDouble() * (config.maxSpeed - config.minSpeed);

    _spawnedBombCount++;
    _bombs.add(
      Bomb(
        id: _nextId++,
        x: _random.nextDouble(),
        y: _screenSize.height,
        size: 48,
        speed: speed,
      ),
    );
  }

  void _popBalloon(Balloon balloon) {
    if (_status != _GameStatus.playing || isPaused || balloon.isPopping) return;
    balloon.isPopping = true;
    playBalloonPopSfx();
    _frameNotifier.notify();
  }

  void _removePoppedBalloon(Balloon balloon) {
    if (!mounted || !balloon.isPopping) return;
    _balloons.removeWhere((b) => b.id == balloon.id);
    _frameNotifier.notify();
  }

  void _tapBomb(Bomb bomb) {
    if (_status != _GameStatus.playing || isPaused || bomb.isExploding) return;
    bomb.isExploding = true;
    _frameNotifier.notify();
    setState(() => _miss++);
    if (_miss >= kMaxMiss) _failLevel();
  }

  void _removeExplodedBomb(Bomb bomb) {
    if (!mounted || !bomb.isExploding) return;
    _bombs.removeWhere((b) => b.id == bomb.id);
    _frameNotifier.notify();
  }

  void _goToNextLevel() {
    if (_levelIndex + 1 < kLevels.length) {
      _startLevel(_levelIndex + 1);
    }
  }

  void _retryLevel() => _startLevel(_levelIndex);

  // ───────── UI ─────────

  @override
  Widget build(BuildContext context) {
    l10n = AppLocalizations.of(context)!;

    return withSystemBackPause(
      Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            _screenSize = Size(constraints.maxWidth, constraints.maxHeight);
            return GameBackground(
              child: Stack(
                children: [
                  // 풍선 레이어: _frameNotifier가 알릴 때만 이 부분만 다시 빌드된다.
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _frameNotifier,
                      builder: (context, _) {
                        return Stack(
                          children: [
                            for (final b in _balloons) _buildBalloon(b),
                            for (final bomb in _bombs) _buildBomb(bomb),
                          ],
                        );
                      },
                    ),
                  ),
                  _buildTopBar(),
                  if (_status == _GameStatus.ready)
                    StartOverlay(
                      message: l10n.game01ScreenStartMessage(
                        kLevels.length,
                        kMaxMiss,
                      ),
                      buttonLabel: l10n.game01ScreenStartButton,
                      onStart: () => _startLevel(0),
                    ),
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
      ),
    );
  }

  Widget _buildBalloon(Balloon b) {
    final double maxLeft = (_screenSize.width - b.size).clamp(
      0,
      double.infinity,
    );
    final double left = b.x * maxLeft;

    return Positioned(
      key: ValueKey(b.id),
      left: left - touchPadding,
      top: b.y - touchPadding,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _popBalloon(b),
        child: Padding(
          padding: const EdgeInsets.all(touchPadding),
          child: AnimatedScale(
            scale: b.isPopping ? 1.45 : 1,
            duration: const Duration(milliseconds: 180),
            child: AnimatedOpacity(
              opacity: b.isPopping ? 0 : 1,
              duration: const Duration(milliseconds: 180),
              onEnd: () => _removePoppedBalloon(b),
              child: RepaintBoundary(
                child: SizedBox(
                  width: b.size,
                  height: b.size * 1.3,
                  child: CustomPaint(painter: BalloonPainter(color: b.color)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBomb(Bomb bomb) {
    final double maxLeft = (_screenSize.width - bomb.size)
        .clamp(0, double.infinity)
        .toDouble();
    return Positioned(
      key: ValueKey('bomb-${bomb.id}'),
      left: bomb.x * maxLeft - touchPadding,
      top: bomb.y - touchPadding,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _tapBomb(bomb),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: bomb.isExploding ? 1 : 0),
          duration: const Duration(milliseconds: 300),
          onEnd: () => _removeExplodedBomb(bomb),
          builder: (context, progress, _) {
            return SizedBox(
              width: bomb.size + touchPadding * 2,
              height: bomb.size + touchPadding * 2,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (bomb.isExploding)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ExplosionPainter(progress: progress),
                      ),
                    ),
                  Transform.scale(
                    scale: 1 + progress * 0.45,
                    child: Opacity(
                      opacity: 1 - progress,
                      child: SizedBox(
                        width: bomb.size,
                        height: bomb.size,
                        child: const CustomPaint(painter: _BombPainter()),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return GameTopBar(
      pauseButton: buildPauseButton(),
      chips: [
        InfoChip(
          icon: Icons.flag,
          value: '${_currentLevel.level}',
          unit: '/${kLevels.length}',
          width: 90,
        ),
        InfoChip(
          icon: Icons.favorite_rounded,
          value: '${(kMaxMiss - _miss).clamp(0, kMaxMiss)}',
          unit: '/$kMaxMiss',
          width: 95,
        ),
        InfoChip(
          icon: Icons.timer,
          value: '$_timeLeft',
          unit: l10n.game01ScreenSecondUnit,
          width: 90,
        ),
      ],
    );
  }

  // ───────── 결과 다이얼로그 (클리어 = 긍정 / 실패 = 부정) ─────────

  Widget _buildLevelClearOverlay() {
    return buildDialogCard(
      title: l10n.game01ScreenLevelClearedTitle(_currentLevel.level),
      message: l10n.game01ScreenLevelClearedMessage(_miss),
      primaryLabel: l10n.game01ScreenNextLevelButton,
      onPrimaryAction: _goToNextLevel,
    );
  }

  Widget _buildLevelFailedOverlay() {
    return buildDialogCard(
      title: l10n.game01ScreenGameOverTitle,
      message: l10n.game01ScreenGameOverMessage(kMaxMiss),
      primaryLabel: l10n.game01ScreenRetryButton,
      onPrimaryAction: _retryLevel,
    );
  }

  Widget _buildAllClearedOverlay() {
    return buildDialogCard(
      title: l10n.game01ScreenAllClearedTitle,
      message: l10n.game01ScreenAllClearedMessage(kLevels.length),
      primaryLabel: l10n.game01ScreenConfirmButton,
      onPrimaryAction: () => Navigator.of(context).maybePop(),
      showQuitButton: false,
    );
  }
}
