import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:pangteojyo/l10n/app_localizations.dart';
import 'package:pangteojyo/utils/app_bgm.dart';
import 'package:pangteojyo/utils/app_const.dart';
import 'package:pangteojyo/utils/bgm_player.dart';
import 'package:pangteojyo/utils/game_storage.dart';
import 'package:pangteojyo/widgets/balloon_painter.dart';
import 'package:flutter/material.dart';

// ════════════════════════════════════════════════════════════════
// 게임 화면 공통 State
// ════════════════════════════════════════════════════════════════

/// 게임 화면 공통 부모 State.
/// - BGM 재생/정지/일시정지/재개/해제
/// - 일시정지 버튼(확인창) 및 공용 다이얼로그 UI
abstract class BaseGameState<T extends StatefulWidget> extends State<T> {
  final BgmPlayer _bgm = BgmPlayer();
  final AudioPlayer _popSfxPlayer = AudioPlayer();
  late final Future<void> _popSfxReady = _popSfxPlayer.setAudioContext(
    AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build(),
  );
  Future<void> _popSfxQueue = Future<void>.value();
  Completer<void>? _activePopSfxCompletion;
  bool _popSfxDisposed = false;
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

  /// 이 게임에서 전달할 현재 기록
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
    if (navigator == null || !navigator.mounted) return;

    final int count = await GameStorage.getAdCount();
    if (!navigator.mounted) return;
    if (count < kAdThreshold) return;

    await GameStorage.setAdCount(0);
    if (!navigator.mounted) return;

    final l10n = AppLocalizations.of(navigator.context)!;

    await GameDialog.show<void>(
      context: navigator.context,
      title: l10n.baseGameStateAdTimeTitle,
      message: l10n.baseGameStateAdTimeMessage,
      buttonsBuilder: (ctx) => [
        GameDialogButton(
          label: l10n.baseGameStateConfirmButton,
          isPrimary: true,
          onPressed: () => Navigator.of(ctx).pop(),
        ),
      ],
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

  /// 재생 중인 효과음이 끝나면 대기 중인 풍선 효과음을 순서대로 재생한다.
  void playBalloonPopSfx() {
    if (_popSfxDisposed) return;
    _popSfxQueue = _popSfxQueue.then((_) => _playNextBalloonPopSfx());
  }

  Future<void> _playNextBalloonPopSfx() async {
    if (_popSfxDisposed || !mounted) return;
    StreamSubscription<void>? completionSubscription;
    final Completer<void> completion = Completer<void>();
    _activePopSfxCompletion = completion;
    try {
      await _popSfxReady;
      if (_popSfxDisposed || !mounted) return;
      completionSubscription = _popSfxPlayer.onPlayerComplete.listen((_) {
        if (!completion.isCompleted) completion.complete();
      });
      await _popSfxPlayer.play(AssetSource(AppConst.fileNameSfxPang));
      await completion.future;
    } catch (_) {
      // 효과음 재생 실패가 게임 진행을 막지 않도록 한다.
    } finally {
      await completionSubscription?.cancel();
      if (identical(_activePopSfxCompletion, completion)) {
        _activePopSfxCompletion = null;
      }
    }
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
  Future<void> showPauseDialog() async {
    if (_isDialogOpen) return;
    _isDialogOpen = true;

    final bool pausedByDialog = isPlaying && !_isPaused;
    if (pausedByDialog) _pauseGame();

    final navigator = _navigator;

    if (navigator == null || !navigator.mounted) {
      _isDialogOpen = false;
      if (pausedByDialog && mounted) {
        _resumeGame();
      }
      return;
    }

    final l10n = AppLocalizations.of(navigator.context)!;

    // 계속하기가 유도 버튼(메인 색), 게임 중단은 흰색 버튼.
    final bool? quit = await GameDialog.show<bool>(
      context: navigator.context,
      title: l10n.baseGameStatePauseTitle,
      message: l10n.baseGameStatePauseMessage,
      buttonsBuilder: (ctx) => [
        GameDialogButton(
          label: l10n.baseGameStateQuitButton,
          onPressed: () => Navigator.of(ctx).pop(true),
        ),
        GameDialogButton(
          label: l10n.baseGameStateContinueButton,
          isPrimary: true,
          onPressed: () => Navigator.of(ctx).pop(false),
        ),
      ],
    );

    _isDialogOpen = false;

    if (!mounted || !navigator.mounted) return;

    if (quit == true) {
      navigator.pop();
      return;
    }

    if (pausedByDialog) _resumeGame();
  }

  @override
  void dispose() {
    cancelAllTimers();
    _bgm.dispose();
    _popSfxDisposed = true;
    final completion = _activePopSfxCompletion;
    if (completion != null && !completion.isCompleted) completion.complete();
    unawaited(_popSfxPlayer.dispose());

    unawaited(saveBestScore());

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

  /// 게임 진행 중에는 시스템 뒤로가기를 일시정지로 처리한다.
  /// 게임이 종료되면 PopScope가 화면 이동을 허용한다.
  Widget withSystemBackPause(Widget child) {
    return PopScope<Object?>(
      canPop: !isPlaying,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        // 이미 화면 이동이 완료됐거나 게임이 종료된 경우 무시
        if (didPop || !isPlaying) return;

        // 게임 진행 중일 때만 일시정지 창 표시
        showPauseDialog();
      },
      child: child,
    );
  }

  /// 게임 화면 위에 띄우는 결과 다이얼로그.
  /// 배경은 항상 흰색/글자는 검은색이고, [primaryLabel] 버튼만 메인 색으로 채운다.
  /// [showQuitButton]이 false면 '게임 중단' 버튼 없이 확인 버튼 하나만 보여준다.
  Widget buildDialogCard({
    required String title,
    required String message,
    required String primaryLabel,
    required VoidCallback onPrimaryAction,
    bool showQuitButton = true,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return GameDialogOverlay(
      title: title,
      message: message,
      buttons: [
        if (showQuitButton)
          GameDialogButton(
            label: l10n.baseGameStateQuitButton,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        GameDialogButton(
          label: primaryLabel,
          isPrimary: true,
          onPressed: onPrimaryAction,
        ),
      ],
    );
  }

  Future<void> saveBestScore() async {
    await GameStorage.saveBestScoreIfHigher(bestScoreKey, currentScore);
  }
}

// ════════════════════════════════════════════════════════════════
// 공용 다이얼로그
// ════════════════════════════════════════════════════════════════

class GameDialogButton {
  final String label;
  final VoidCallback onPressed;

  /// true: 사용자가 눌렀으면 하는 버튼 (메인 색으로 채움)
  /// false: 그 외 버튼 (흰색 배경 + 테두리)
  final bool isPrimary;

  const GameDialogButton({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });
}

/// 앱 공용 다이얼로그 카드. 배경은 흰색, 글자는 검은색.
class GameDialog extends StatelessWidget {
  final String title;
  final String message;
  final List<GameDialogButton> buttons;

  const GameDialog({
    super.key,
    required this.title,
    required this.message,
    required this.buttons,
  });

  /// showDialog로 띄우는 형태 (일시정지, 광고 등)
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String message,
    required List<GameDialogButton> Function(BuildContext dialogContext)
    buttonsBuilder,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: GameDialog(
          title: title,
          message: message,
          buttons: buttonsBuilder(ctx),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 모든 다이얼로그 버튼은 같은 크기를 사용한다. 버튼 두 개가 나란히
    // 들어가도록 화면 너비에 맞춰 폭을 정하고, 한 개만 있어도 같은 폭을 쓴다.
    final double contentWidth =
        (MediaQuery.sizeOf(context).width - 136).clamp(0.0, 504.0);
    final double buttonWidth = ((contentWidth - 12) / 2).clamp(96.0, 160.0);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppConst.dialogBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppConst.dialogText,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: AppConst.dialogText),
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              for (final b in buttons) _buildButton(b, buttonWidth),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton(GameDialogButton b, double width) {
    return _PressableDialogButton(
      label: b.label,
      isPrimary: b.isPrimary,
      onPressed: b.onPressed,
      width: width,
    );
  }
}

class _PressableDialogButton extends StatefulWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onPressed;
  final double width;

  const _PressableDialogButton({
    required this.label,
    required this.isPrimary,
    required this.onPressed,
    required this.width,
  });

  @override
  State<_PressableDialogButton> createState() =>
      _PressableDialogButtonState();
}

class _PressableDialogButtonState extends State<_PressableDialogButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color faceColor = widget.isPrimary
        ? AppConst.dialogPrimaryButton
        : AppConst.dialogSecondaryButton;
    final Color textColor = widget.isPrimary
        ? AppConst.dialogPrimaryButtonText
        : AppConst.dialogSecondaryButtonText;

    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _pressed ? 4 : 0, 0),
          width: widget.width,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: faceColor,
            borderRadius: BorderRadius.circular(12),
            border: widget.isPrimary
                ? null
                : Border.all(
                    color: AppConst.dialogSecondaryButtonBorder,
                    width: 1.5,
                  ),
            boxShadow: [
              BoxShadow(
                color: widget.isPrimary
                    ? const Color(0xFF9C1748).withValues(alpha: 0.65)
                    : Colors.black.withValues(alpha: 0.22),
                offset: Offset(0, _pressed ? 1 : 5),
                blurRadius: _pressed ? 1 : 0,
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              widget.label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 게임 화면 위에 어두운 배경과 함께 [GameDialog]를 가운데 띄우는 오버레이.
class GameDialogOverlay extends StatelessWidget {
  final String title;
  final String message;
  final List<GameDialogButton> buttons;

  const GameDialogOverlay({
    super.key,
    required this.title,
    required this.message,
    required this.buttons,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppConst.dialogScrim,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: GameDialog(title: title, message: message, buttons: buttons),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// 공용 게임 화면 위젯
// ════════════════════════════════════════════════════════════════

/// 모든 게임 화면 공통 하늘색 그라데이션 배경
class GameBackground extends StatelessWidget {
  final Widget child;

  const GameBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppConst.skyTop, AppConst.skyBottom],
        ),
      ),
      child: child,
    );
  }
}

/// 게임 화면 상단 바: 왼쪽 일시정지 버튼, 오른쪽 정보 칩들, (선택) 아래에 문제판
class GameTopBar extends StatelessWidget {
  final Widget pauseButton;
  final List<Widget> chips;
  final Widget? bottom;

  const GameTopBar({
    super.key,
    required this.pauseButton,
    required this.chips,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> spacedChips = [];
    for (int i = 0; i < chips.length; i++) {
      if (i > 0) spacedChips.add(const SizedBox(width: 8));
      spacedChips.add(chips[i]);
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                pauseButton,
                Row(children: spacedChips),
              ],
            ),
            if (bottom != null) ...[const SizedBox(height: 14), bottom!],
          ],
        ),
      ),
    );
  }
}

/// 게임 시작 전 안내 + 시작 버튼
class StartOverlay extends StatelessWidget {
  final String message;
  final String buttonLabel;
  final VoidCallback onStart;

  const StartOverlay({
    super.key,
    required this.message,
    required this.buttonLabel,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.4),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                style: const TextStyle(fontSize: 16, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _PressableStartButton(
                label: buttonLabel,
                onPressed: onStart,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PressableStartButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const _PressableStartButton({
    required this.label,
    required this.onPressed,
  });

  @override
  State<_PressableStartButton> createState() => _PressableStartButtonState();
}

class _PressableStartButtonState extends State<_PressableStartButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _pressed ? 4 : 0, 0),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          decoration: BoxDecoration(
            color: AppConst.mainColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9C1748).withValues(alpha: 0.65),
                offset: Offset(0, _pressed ? 1 : 5),
                blurRadius: _pressed ? 1 : 0,
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// 딩동댕! / 땡! 메시지
class FeedbackOverlay extends StatelessWidget {
  final String text;
  final bool correct;

  const FeedbackOverlay({super.key, required this.text, required this.correct});

  @override
  Widget build(BuildContext context) {
    final Color color = correct
        ? AppConst.feedbackCorrect
        : AppConst.feedbackWrong;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// 숫자/기호 텍스트가 표시된 풍선
class LabeledBalloon extends StatelessWidget {
  final double size;
  final Color color;
  final String label;
  final bool withShadow;
  final Color labelShadowColor;

  const LabeledBalloon({
    super.key,
    required this.size,
    required this.color,
    required this.label,
    this.withShadow = false,
    this.labelShadowColor = Colors.black38,
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
            painter: BalloonPainter(color: color, withShadow: withShadow),
          ),
          Align(
            alignment: const Alignment(0, -0.35),
            child: Text(
              label,
              style: TextStyle(
                fontSize: size * 0.34,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: labelShadowColor,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
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
