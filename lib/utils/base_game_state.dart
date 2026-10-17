import 'package:balloon_game/utils/app_bgm.dart';
import 'package:balloon_game/utils/bgm_player.dart';
import 'package:flutter/material.dart';

/// 게임 화면 공통 부모 State.
/// - BGM 재생/정지/일시정지/재개/해제
/// - 게임 일시정지/재개 흐름과 공용 UI(일시정지 버튼, 오버레이, 다이얼로그)
abstract class BaseGameState<T extends StatefulWidget> extends State<T> {
  final BgmPlayer _bgm = BgmPlayer();
  bool _isPaused = false;

  /// 일시정지 중인지 여부
  bool get isPaused => _isPaused;

  // ───────── 자식 클래스가 구현해야 하는 부분 ─────────

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

  void pauseGame() {
    if (!isPlaying || _isPaused) return;
    cancelAllTimers();
    _bgm.pause();
    setState(() {
      onPause();
      _isPaused = true;
    });
  }

  void resumeGame() {
    if (!_isPaused) return;
    setState(() {
      onResume();
      _isPaused = false;
    });
    _bgm.resume();
    startTimers();
  }

  @override
  void dispose() {
    cancelAllTimers();
    _bgm.dispose();
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

  /// 일시정지 / 재개 토글 버튼 (진행 중이거나 일시정지 중일 때만 표시)
  Widget buildPauseButton() {
    return circleButton(
      isPaused ? Icons.play_arrow : Icons.pause,
      isPaused ? resumeGame : pauseGame,
    );
  }

  Widget buildPausedOverlay() {
    return buildDialogCard(
      title: '일시정지 ⏸️',
      message: '이어서 진행하세요!',
      titleColor: Colors.blueGrey,
      onPrimaryAction: resumeGame,
      primaryLabel: '다시 시작',
      primaryColor: Colors.blue,
    );
  }

  Widget buildDialogCard({
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
}