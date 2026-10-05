import 'bgm_player.dart';

/// 앱 전역에서 공유하는 BGM 인스턴스
class AppBgm {
  AppBgm._();

  /// 홈 / 게임 목록 화면용 음악 (끝나면 2초 후 반복)
  static final BgmPlayer home = BgmPlayer(assetPath: '2026_003_0-80.mp3');
}