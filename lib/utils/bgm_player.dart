import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

/// 게임 공통 배경음악 플레이어.
/// - 음악이 끝나면 [repeatDelay] 후 자동으로 다시 재생
/// - Game01, Game02 등에서 각각 인스턴스를 만들어 사용
class BgmPlayer {
  /// assets/ 폴더 기준 경로 (audioplayers는 'assets/' 접두사를 자동으로 붙임)
  static const String defaultAsset = '2026_012_0-82.mp3';

  final String assetPath;
  final Duration repeatDelay;

  BgmPlayer({
    this.assetPath = defaultAsset,
    this.repeatDelay = const Duration(seconds: 2),
  });

  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<void>? _completeSub;
  Timer? _repeatTimer;

  bool _active = false; // 시작된 상태 여부
  bool _waitingReplay = false; // 곡이 끝나고 2초 대기 중인지
  bool _disposed = false;

  /// 재생 시작. 이미 시작된 상태면 아무것도 하지 않음
  /// (단계가 바뀔 때마다 호출해도 음악이 처음부터 다시 시작되지 않음).
  Future<void> start() async {
    if (_active || _disposed) return;
    _active = true;
    await _player.setReleaseMode(ReleaseMode.stop);
    _completeSub ??= _player.onPlayerComplete.listen((_) => _scheduleReplay());
    await _play();
  }

  Future<void> _play() async {
    _waitingReplay = false;
    await _player.play(AssetSource(assetPath));
  }

  void _scheduleReplay() {
    if (!_active || _disposed) return;
    _waitingReplay = true;
    _repeatTimer?.cancel();
    _repeatTimer = Timer(repeatDelay, () {
      if (_active && !_disposed) _play();
    });
  }

  /// 일시정지 (2초 대기 중이어도 안전하게 처리)
  Future<void> pause() async {
    if (!_active || _disposed) return;
    _repeatTimer?.cancel();
    if (!_waitingReplay) {
      await _player.pause();
    }
  }

  /// 일시정지 해제
  Future<void> resume() async {
    if (!_active || _disposed) return;
    if (_waitingReplay) {
      _scheduleReplay(); // 대기 중이었다면 다시 2초 뒤 재생
    } else {
      await _player.resume();
    }
  }

  /// 완전 정지 (다음에 start()를 호출하면 처음부터 재생)
  Future<void> stop() async {
    _active = false;
    _waitingReplay = false;
    _repeatTimer?.cancel();
    if (!_disposed) await _player.stop();
  }

  /// 화면 dispose 시 반드시 호출
  Future<void> dispose() async {
    _disposed = true;
    _active = false;
    _repeatTimer?.cancel();
    await _completeSub?.cancel();
    await _player.dispose();
  }
}