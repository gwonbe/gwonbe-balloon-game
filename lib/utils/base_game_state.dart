import 'package:balloon_game/utils/app_bgm.dart';
import 'package:balloon_game/utils/bgm_player.dart';
import 'package:balloon_game/utils/game_storage.dart';
import 'package:flutter/material.dart';

/// 게임 화면 공통 부모 State.
/// - BGM 재생/정지/일시정지/재개/해제
/// - 일시정지 버튼(확인창) 및 공용 다이얼로그 UI
abstract class BaseGameState<T extends StatefulWidget> extends State<T> {
  final BgmPlayer _bgm = BgmPlayer();
  bool _isPaused = false;
  bool _isDialogOpen = false;

  /// 광고를 띄우는 게임 시작 횟수 기준
  static const int kAdThreshold = 10;

  /// dispose 이후에도 안전하게 광고창을 띄우기 위해 Navigator를 미리 잡아둔다.
  NavigatorState? _navigator;

  /// 일시정지 중인지 여부 (일시정지 확인창이 떠 있는 동안 true)
  bool get isPaused => _isPaused;

  // ───────── 자식 클래스가 구현해야 하는 부분 ─────────

  /// 최고 기록 저장용 SharedPreferences 키
  String get bestScoreKey;

  /// 이 게임에서 전달할 현재 기록 (game01: 최고 도달 단계, game02: 정답 개수)
  int get currentScore;

  /// 지금 게임이 진행 중인가? (일시정지 가능한 상태인가)
  bool get isPlaying;

  /// 이 게임에서 쓰는 모든 타이머를 취소한다.
  void cancelAllTimers();

  /// 현재 상태(점수, 남은 시간 등)는 그대로 두고 타이머만 (다시) 시작한다.
  void startTimers();

  /// 일시정지 직전에 추가로 처리할 것이 있으면 override (setState 안에서 호출됨)
  void onPause() {}

  /// 재개 직전에 추가로 처리할 것이 있으면 override (setState 안에서 호출됨)
  void onResume() {}

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navigator = Navigator.of(context);
  }

  // ───────── 게임 시작 횟수 / 광고 ─────────

  /// 게임을 시작할 때마다 호출한다. (단계 시작, 재시도 포함)
  void registerGameStart() {
    GameStorage.incrementAdCount();
  }

  static Future<void> _showAdIfNeeded(NavigatorState? navigator) async {
    final int count = await GameStorage.getAdCount();
    if (count < kAdThreshold) return;
    if (navigator == null || !navigator.mounted) return;
    final overlayContext = navigator.overlay?.context;
    if (overlayContext == null) return;

    await GameStorage.setAdCount(0); // 중복 표시 방지를 위해 먼저 초기화

    await showDialog<void>(
      context: overlayContext,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        // ... 기존 광고타임 다이얼로그 그대로
      ),
    );
  }

  // ───────── BGM ─────────

  /// 홈 BGM을 끄고 게임 BGM 시작.
  /// 재생 중이면 무시되고, stopBgm()으로 멈춘 뒤라면 처음부터 재생된다.
  void startBgm() {
    AppBgm.home.stop();
    _bgm.start();
  }

  /// 게임 BGM 정지 (재생 위치 초기화). 다음 startBgm()은 처음부터 재생한다.
  void stopBgm() {
    _bgm.stop();
  }

  // ───────── 일시정지 / 재개 ─────────

  void _pauseGame() {
    if (!isPlaying || _isPaused) return;
    cancelAllTimers();
    _bgm.pause();
    setState(() {
      onPause();
      _isPaused = true;
    });
  }

  void _resumeGame() {
    if (!_isPaused) return;
    setState(() {
      onResume();
      _isPaused = false;
    });
    _bgm.resume();
    startTimers();
  }

  /// 일시정지 버튼을 눌렀을 때 호출.
  /// 진행 중이면 게임/음악을 멈추고 확인창을 띄운다.
  /// - 계속하기: 멈췄던 게임/음악을 이어서 재개
  /// - 중단하기: 이전 화면으로 이동 (음악은 다시 재생하지 않음)
  /// 시작 전이거나 결과 화면이면 이미 멈춰 있으므로 확인창만 띄운다.
  Future<void> showPauseDialog() async {
    if (_isDialogOpen) return;
    _isDialogOpen = true;

    final bool pausedByDialog = isPlaying && !_isPaused;
    if (pausedByDialog) _pauseGame();

    final bool? quit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '일시정지 ⏸️',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          '게임을 중단하시겠습니까?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          // 왼쪽: 중단하기 (테두리만)
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('중단하기'),
          ),
          // 오른쪽: 계속하기 (색칠)
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('계속하기'),
          ),
        ],
      ),
    );

    _isDialogOpen = false;
    if (!mounted) return;

    if (quit == true) {
      // 홈으로 이동. dispose()에서 BGM이 해제되므로 음악은 다시 재생되지 않는다.
      Navigator.of(context).pop();
      return;
    }

    if (pausedByDialog) _resumeGame();
  }

  @override
  void dispose() {
    cancelAllTimers();
    _bgm.dispose();

    // 최고 기록 갱신 (현재 기록이 더 높을 때만 덮어씀)
    GameStorage.saveBestScoreIfHigher(bestScoreKey, currentScore);

    // 게임 화면이 닫힌 뒤(게임 목록이 보이는 상태)에 광고 여부를 확인
    final nav = _navigator;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showAdIfNeeded(nav);
    });

    super.dispose();
  }

  // ───────── 공용 UI ─────────

  Widget circleButton(IconData icon, VoidCallback onTap) {
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

  /// 일시정지(⏸) 버튼. 누르면 일시정지 확인창을 띄운다.
  Widget buildPauseButton() {
    return circleButton(Icons.pause, showPauseDialog);
  }

  /// [showQuitButton]이 false면 '게임 중단' 버튼 없이 확인 버튼 하나만 보여준다.
  Widget buildDialogCard({
    required String title,
    required String message,
    required Color titleColor,
    required VoidCallback onPrimaryAction,
    required String primaryLabel,
    required Color primaryColor,
    bool showQuitButton = true,
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
                  if (showQuitButton) ...[
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      child: const Text('중단하기'),
                    ),
                    const SizedBox(width: 12),
                  ],
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
}