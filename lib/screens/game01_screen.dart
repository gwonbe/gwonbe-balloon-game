import 'dart:async';
import 'dart:math';
import 'package:pangteojyo/l10n/app_localizations.dart';
import 'package:pangteojyo/utils/app_const.dart';
import 'package:pangteojyo/utils/base_game_state.dart';
import 'package:pangteojyo/utils/bgm_player.dart';
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

/// 풍선을 놓치거나 폭탄에 닿아 이 횟수만큼 생명을 잃으면 게임 종료
const int kMaxMiss = 3;

/// 모든 단계 공통 풍선 크기 범위 (단계가 올라가도 크기는 그대로)
const double kBalloonMinSize = 45;
const double kBalloonMaxSize = 75;

/// 기존 동작(프레임당 speed * 0.03, 16ms 간격)과 같은 체감 속도를 유지하기 위한 배율.
/// 실제 이동 속도(px/sec) = speed * 이 값
const double _kSpeedScale = 1.875;

/// 실제 풍선보다 터치 영역을 사방으로 20px씩 확장
const double touchPadding = 20;

/// 난이도는 15초마다 한 단계 오르고, 최대 단계에서 유지된다.
const int _kDifficultyStageDurationSeconds = 15;
const int _kMaxDifficultyStage = 8;
const double _kInitialBalloonSpawnInterval = 1.4;
const double _kFinalBalloonSpawnInterval = 0.75;
const double _kInitialBombSpawnInterval = 6.0;
const double _kFinalBombSpawnInterval = 3.8;
const double _kMaximumSpeedMultiplier = 1.56;

enum _GameStatus { ready, playing, gameOver }

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
    final double radius = size.width * (0.19 + progress * 0.48);

    canvas.drawCircle(
      center,
      radius * 0.78,
      Paint()
        ..color = const Color(0xFFFF5722).withValues(alpha: fade * 0.52)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Curved flame tongues expand around the blast and fade with the bomb.
    for (int i = 0; i < 14; i++) {
      final double angle = (i * 2 * pi / 14) + progress * 0.22;
      final double innerRadius = radius * (0.4 + (i.isEven ? 0.12 : 0));
      final double outerRadius = radius * (1.0 + (i % 3) * 0.14);
      final double halfWidth = radius * (i.isEven ? 0.18 : 0.14);
      final Offset direction = Offset(cos(angle), sin(angle));
      final Offset tangent = Offset(-direction.dy, direction.dx);
      final Offset base = center + direction * innerRadius;
      final Offset tip = center + direction * outerRadius;
      final double curveRadius = (innerRadius + outerRadius) * 0.42;
      final Path flame = Path()
        ..moveTo(
          base.dx - tangent.dx * halfWidth,
          base.dy - tangent.dy * halfWidth,
        )
        ..quadraticBezierTo(
          center.dx +
              direction.dx * curveRadius -
              tangent.dx * halfWidth * 0.45,
          center.dy +
              direction.dy * curveRadius -
              tangent.dy * halfWidth * 0.45,
          tip.dx,
          tip.dy,
        )
        ..quadraticBezierTo(
          center.dx +
              direction.dx * curveRadius +
              tangent.dx * halfWidth * 0.45,
          center.dy +
              direction.dy * curveRadius +
              tangent.dy * halfWidth * 0.45,
          base.dx + tangent.dx * halfWidth,
          base.dy + tangent.dy * halfWidth,
        )
        ..close();
      canvas.drawPath(
        flame,
        Paint()
          ..color =
              (i.isEven ? const Color(0xFFFF5722) : const Color(0xFFFF9800))
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
  double _playTime = 0; // 누적 생존 시간(초), 일시정지 시간 제외
  double _balloonSpawnElapsed = 0;
  double _bombSpawnElapsed = 0;
  int _score = 0;
  int _lives = kMaxMiss;
  int get _difficultyStage => min(
    _kMaxDifficultyStage,
    1 + (_playTime ~/ _kDifficultyStageDurationSeconds),
  ).toInt();
  double get _difficultySpeedMultiplier => min(
    _kMaximumSpeedMultiplier,
    1 + (_difficultyStage - 1) * 0.08,
  ).toDouble();

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
  int get currentScore => _score;

  @override
  void cancelAllTimers() {
    if (_ticker.isActive) _ticker.stop();
  }

  /// 현재 게임 상태를 유지하고 Ticker만 재시작한다.
  @override
  void startTimers() {
    _lastTick = Duration.zero; // Ticker는 시작할 때마다 elapsed가 0부터 시작
    if (!_ticker.isActive) _ticker.start();
  }

  @override
  BgmPlayer createBgmPlayer() => BgmPlayer(
    repeatDelay: const Duration(seconds: 3),
    replayPosition: const Duration(seconds: 16),
  );

  // ───────── 게임 로직 ─────────

  void _startGame() {
    cancelAllTimers();
    registerGameStart();

    setState(() {
      _lives = kMaxMiss;
      _score = 0;
      _playTime = 0;
      _balloonSpawnElapsed = 0;
      _bombSpawnElapsed = 0;
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
    _balloonSpawnElapsed += dt;
    _bombSpawnElapsed += dt;

    // 풍선 속도는 기존 계산을 유지하고 폭탄도 같은 단계 속도 범위로 이동한다.
    for (final b in _balloons) {
      b.y -= b.speed * _kSpeedScale * _difficultySpeedMultiplier * dt;
    }
    for (final bomb in _bombs) {
      if (!bomb.isExploding) {
        bomb.y -= bomb.speed * _kSpeedScale * _difficultySpeedMultiplier * dt;
      }
    }

    // 놓친 풍선은 생명을 줄이고, 화면 위로 지나간 폭탄은 사라진다.
    final int before = _balloons.length;
    _balloons.removeWhere((b) => !b.isPopping && b.y + b.size < 0);
    final int missed = before - _balloons.length;
    _bombs.removeWhere((bomb) => !bomb.isExploding && bomb.y + bomb.size < 0);

    // 일정 간격으로 풍선을 생성하고, 난이도 단계에 따라 간격을 완만하게 줄인다.
    final double difficultyProgress =
        (_difficultyStage - 1) / (_kMaxDifficultyStage - 1);
    final double balloonInterval =
        _kInitialBalloonSpawnInterval -
        (_kInitialBalloonSpawnInterval - _kFinalBalloonSpawnInterval) *
            difficultyProgress;
    while (_balloonSpawnElapsed >= balloonInterval) {
      _balloonSpawnElapsed -= balloonInterval;
      _spawnBalloon();
    }

    final double bombInterval =
        _kInitialBombSpawnInterval -
        (_kInitialBombSpawnInterval - _kFinalBombSpawnInterval) *
            difficultyProgress;
    while (_bombSpawnElapsed >= bombInterval) {
      _bombSpawnElapsed -= bombInterval;
      _spawnBomb();
    }

    // 풍선 레이어만 다시 그린다 (화면 전체 setState 아님)
    _frameNotifier.notify();

    // 4) 미스가 바뀐 경우에만 화면 전체 갱신
    if (missed > 0) {
      _loseLives(missed);
      if (_lives <= 0) {
        _failLevel();
        return;
      }
    }
  }

  /// 생명을 모두 잃으면 타이머와 음악을 멈추고 기록을 저장한다.
  void _failLevel() {
    cancelAllTimers();
    stopBgm();
    setState(() => _status = _GameStatus.gameOver);
    unawaited(saveBestScore());
  }

  /// 풍선 생성 (프레임 루프 안에서 호출되므로 setState를 쓰지 않는다)
  void _spawnBalloon() {
    if (_screenSize == Size.zero) return;
    final double size =
        kBalloonMinSize +
        _random.nextDouble() * (kBalloonMaxSize - kBalloonMinSize);
    final double speed = 130 + _random.nextDouble() * 60;
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
    final double speed = 130 + _random.nextDouble() * 60;
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
    setState(() => _score++);
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
    _loseLives(1);
    if (_lives <= 0) _failLevel();
  }

  void _loseLives(int count) {
    setState(() {
      _lives = (_lives - count).clamp(0, kMaxMiss).toInt();
    });
  }

  void _removeExplodedBomb(Bomb bomb) {
    if (!mounted || !bomb.isExploding) return;
    _bombs.removeWhere((b) => b.id == bomb.id);
    _frameNotifier.notify();
  }

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
                      message: l10n.game01ScreenStartMessage(kMaxMiss),
                      buttonLabel: l10n.game01ScreenStartButton,
                      onStart: _startGame,
                    ),
                  if (_status == _GameStatus.gameOver) _buildGameOverOverlay(),
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
    final double effectSize = bomb.size * 2.5;
    return Positioned(
      key: ValueKey('bomb-${bomb.id}'),
      left: bomb.x * maxLeft - (effectSize - bomb.size) / 2,
      top: bomb.y - (effectSize - bomb.size) / 2,
      width: effectSize,
      height: effectSize,
      child: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _tapBomb(bomb),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: bomb.isExploding ? 1 : 0),
            duration: const Duration(milliseconds: 420),
            onEnd: () => _removeExplodedBomb(bomb),
            builder: (context, progress, _) {
              return SizedBox(
                width: bomb.size + touchPadding * 2,
                height: bomb.size + touchPadding * 2,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    if (bomb.isExploding)
                      Positioned(
                        left:
                            -(effectSize - (bomb.size + touchPadding * 2)) / 2,
                        top: -(effectSize - (bomb.size + touchPadding * 2)) / 2,
                        width: effectSize,
                        height: effectSize,
                        child: CustomPaint(
                          painter: _ExplosionPainter(progress: progress),
                        ),
                      ),
                    Transform.scale(
                      scale: 1 + progress * 0.8,
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
      ),
    );
  }

  Widget _buildTopBar() {
    return GameTopBar(
      pauseButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildPauseButton(),
          const SizedBox(width: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < kMaxMiss; i++)
                Padding(
                  padding: EdgeInsets.only(right: i == kMaxMiss - 1 ? 0 : 1),
                  child: Icon(
                    Icons.favorite_rounded,
                    size: 14,
                    color: i < _lives
                        ? AppConst.infoChipIcon
                        : Colors.transparent,
                  ),
                ),
            ],
          ),
        ],
      ),
      chips: [
        InfoChip(
          icon: Icons.bubble_chart_rounded,
          value: '$_score',
          unit: l10n.game01ScreenBalloonUnit,
          width: 145,
        ),
      ],
    );
  }

  Widget _buildGameOverOverlay() {
    return buildDialogCard(
      title: l10n.game01ScreenGameOverTitle,
      message: l10n.game01ScreenGameOverMessage(kMaxMiss, _score),
      primaryLabel: l10n.game01ScreenRetryButton,
      onPrimaryAction: _startGame,
    );
  }
}
