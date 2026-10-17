import 'dart:math';
import 'package:balloon_game/utils/base_game_state.dart';
import 'package:balloon_game/widgets/balloon_painter.dart';
import 'package:balloon_game/widgets/info_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class Game01Screen extends StatefulWidget {
  const Game01Screen({super.key});

  @override
  State<Game01Screen> createState() => _Game01ScreenState();
}

/// 전체 단계 수
const int kLevelCount = 5;

/// 모든 단계 공통 제한 시간(초)
const int kLevelDurationSeconds = 30;

/// 이 횟수만큼 풍선을 놓치면 게임 종료
const int kMaxMiss = 5;

/// 모든 단계 공통 풍선 크기 범위 (단계가 올라가도 크기는 그대로)
const double kBalloonMinSize = 45;
const double kBalloonMaxSize = 75;

/// 기존 동작(프레임당 speed * 0.03, 16ms 간격)과 같은 체감 속도를 유지하기 위한 배율.
/// 실제 이동 속도(px/sec) = speed * 이 값
const double _kSpeedScale = 1.875;

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

/// 모든 단계 30초 고정, 풍선 크기 고정.
/// 단계가 오를수록 풍선이 빨라지고, 화면에 더 많이 나옵니다.
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
  levelCleared, // 30초를 버텨서 해당 단계 클리어
  levelFailed, // 풍선을 kMaxMiss개 놓쳐서 실패
  allCleared, // 마지막 단계까지 모두 클리어
}

class Balloon {
  final int id;
  final double x; // 0.0 ~ 1.0 (가로 상대 위치)
  double y; // 세로 픽셀 위치 (위에서부터)
  final double size;
  final Color color;
  final double speed;

  Balloon({
    required this.id,
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.speed,
  });
}

/// 풍선 레이어만 다시 그리게 하기 위한 알림 객체
class _FrameNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

class _Game01ScreenState extends BaseGameState<Game01Screen>
    with SingleTickerProviderStateMixin {
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
  final _FrameNotifier _frameNotifier = _FrameNotifier();
  int _nextId = 0;

  // 이동 / 스폰 / 남은 시간을 모두 이 Ticker 하나로 처리한다.
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  double _playTime = 0; // 이번 단계에서 실제로 플레이한 시간(초). 일시정지 시간은 제외

  int _levelIndex = 0; // 0-based (0 -> 단계 1)
  LevelConfig get _currentLevel => kLevels[_levelIndex];

  int get _totalSpawnCount => _currentLevel.spawnCount;

  int _miss = 0; // 이번 단계에서 놓친 풍선 수 (단계 시작 시 0으로 초기화)
  int _spawnedCount = 0; // 이번 단계에서 이미 생성된 풍선 수
  int _timeLeft = 0;

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
      _playTime = 0;
      _timeLeft = kLevelDurationSeconds;
      _status = _GameStatus.playing;
      _balloons.clear();
    });

    // 정지된 상태에서 시작하면 처음부터 재생된다.
    startBgm();
    startTimers();
  }

  /// 매 프레임 호출: 풍선 이동 -> 미스 판정 -> 스폰 -> 남은 시간 갱신
  void _onTick(Duration elapsed) {
    if (_status != _GameStatus.playing) return;

    // 프레임 간격(초). 앱이 잠깐 멈췄다 돌아왔을 때 풍선이 튀지 않도록 상한을 둔다.
    final double dt =
    ((elapsed - _lastTick).inMicroseconds / 1e6).clamp(0.0, 0.05).toDouble();
    _lastTick = elapsed;
    _playTime += dt;

    // 1) 풍선 이동
    for (final b in _balloons) {
      b.y -= b.speed * _kSpeedScale * dt;
    }

    // 2) 터뜨리지 못하고 화면 위로 사라진 풍선 = 미스
    final int before = _balloons.length;
    _balloons.removeWhere((b) => b.y + b.size < 0);
    final int missed = before - _balloons.length;

    // 3) 제한 시간 안에 풍선이 고르게 나오도록 스폰
    final double interval = kLevelDurationSeconds / _totalSpawnCount;
    while (_spawnedCount < _totalSpawnCount &&
        _playTime >= (_spawnedCount + 0.5) * interval) {
      _spawnBalloon();
    }

    // 풍선 레이어만 다시 그린다 (화면 전체 setState 아님)
    _frameNotifier.notify();

    // 4) 미스가 바뀐 경우에만 화면 전체 갱신
    if (missed > 0) {
      setState(() {
        _miss += missed;
      });
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
      setState(() {
        _timeLeft = left;
      });
    }

    // 시간이 끝났다는 것은 미스가 kMaxMiss 미만이라는 뜻 -> 단계 클리어
    if (_playTime >= kLevelDurationSeconds) {
      _finishLevelCleared();
    }
  }

  /// 단계 클리어 처리: 타이머 정지 + 음악 정지 + 상태 전환.
  void _finishLevelCleared() {
    cancelAllTimers();
    stopBgm(); // 다이얼로그에 머무는 동안 음악 정지
    setState(() {
      _timeLeft = 0;
      _status = (_levelIndex == kLevels.length - 1)
          ? _GameStatus.allCleared
          : _GameStatus.levelCleared;
    });
  }

  /// 풍선을 kMaxMiss개 놓쳐서 게임 종료
  void _failLevel() {
    cancelAllTimers();
    stopBgm(); // 실패 다이얼로그에서도 음악 정지
    setState(() {
      _status = _GameStatus.levelFailed;
    });
  }

  /// 풍선 생성 (프레임 루프 안에서 호출되므로 setState를 쓰지 않는다)
  void _spawnBalloon() {
    if (_screenSize == Size.zero) return;
    final LevelConfig config = _currentLevel;
    final double size = kBalloonMinSize +
        _random.nextDouble() * (kBalloonMaxSize - kBalloonMinSize);
    final double speed = config.minSpeed +
        _random.nextDouble() * (config.maxSpeed - config.minSpeed);

    _spawnedCount++;
    _balloons.add(
      Balloon(
        id: _nextId++,
        x: _random.nextDouble(), // 0.0~1.0
        y: _screenSize.height, // 화면 아래에서 시작
        size: size,
        color: balloonColors[_random.nextInt(balloonColors.length)],
        speed: speed,
      ),
    );
  }

  void _popBalloon(Balloon balloon) {
    if (_status != _GameStatus.playing || isPaused) return;
    _balloons.removeWhere((b) => b.id == balloon.id);
    _frameNotifier.notify(); // 풍선 레이어만 갱신
  }

  void _goToNextLevel() {
    if (_levelIndex + 1 < kLevels.length) {
      _startLevel(_levelIndex + 1);
    }
  }

  void _retryLevel() {
    _startLevel(_levelIndex);
  }

  // ───────── UI ─────────

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
                // 풍선 레이어: _frameNotifier가 알릴 때만 이 부분만 다시 빌드된다.
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _frameNotifier,
                    builder: (context, _) {
                      return Stack(
                        children: [
                          for (final b in _balloons) _buildBalloon(b),
                        ],
                      );
                    },
                  ),
                ),
                _buildTopBar(),
                if (_status == _GameStatus.ready) _buildStartOverlay(),
                if (_status == _GameStatus.levelCleared) _buildLevelClearOverlay(),
                if (_status == _GameStatus.levelFailed) _buildLevelFailedOverlay(),
                if (_status == _GameStatus.allCleared) _buildAllClearedOverlay(),
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
      key: ValueKey(b.id),
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
            buildPauseButton(),

            // 오른쪽: 정보 칩 3개 (단계 / 미스 / 남은 시간)
            Row(
              children: [
                InfoChip(
                  icon: Icons.flag,
                  value: '${config.level}',
                  unit: '/${kLevels.length}',
                  width: 90,
                ),
                const SizedBox(width: 8),
                InfoChip(
                  icon: Icons.heart_broken,
                  value: '$_miss',
                  unit: '/$kMaxMiss',
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
              const SizedBox(height: 12),
              Text(
                '총 ${kLevels.length}단계!\n'
                    '단계마다 $kLevelDurationSeconds초 동안 풍선을 터뜨리세요!\n'
                    '풍선을 $kMaxMiss개 놓치면 게임이 끝나요!\n'
                    '단계가 올라갈수록 풍선이 더 빨라져요!',
                style: const TextStyle(fontSize: 16, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _startLevel(0),
                style: ElevatedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
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

  Widget _buildLevelClearOverlay() {
    final LevelConfig cleared = kLevels[_levelIndex];
    return buildDialogCard(
      title: '단계 ${cleared.level} 클리어! 🎉',
      message: '$kLevelDurationSeconds초를 잘 버텼어요!\n'
          '놓친 풍선: $_miss개\n'
          '다음 단계에 도전할까요?',
      titleColor: Colors.green,
      onPrimaryAction: _goToNextLevel,
      primaryLabel: '다음 단계',
      primaryColor: Colors.blue,
    );
  }

  Widget _buildLevelFailedOverlay() {
    return buildDialogCard(
      title: '게임 종료! 😢',
      message: '풍선을 $kMaxMiss개 놓쳤어요!\n같은 단계부터 다시 도전해 보세요!',
      titleColor: Colors.redAccent,
      onPrimaryAction: _retryLevel,
      primaryLabel: '다시 시도',
      primaryColor: Colors.orange,
    );
  }

  Widget _buildAllClearedOverlay() {
    return buildDialogCard(
      title: '전체 클리어! 🏆',
      message: '${kLevels.length}개 단계를 모두 완료했어요!\n정말 대단해요!',
      titleColor: Colors.deepOrange,
      onPrimaryAction: () => Navigator.of(context).maybePop(), // 게임 목록으로
      primaryLabel: '확인',
      primaryColor: Colors.blue,
      showQuitButton: false,
    );
  }
}

class _BalloonWidget extends StatelessWidget {
  final double size;
  final Color color;

  const _BalloonWidget({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary: 풍선이 움직일 때 위치만 옮기고 다시 그리지 않는다.
    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size * 1.3,
        child: CustomPaint(
          painter: BalloonPainter(color: color),
        ),
      ),
    );
  }
}