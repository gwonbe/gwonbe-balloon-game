import 'dart:async';
import 'dart:math';

import 'package:balloon_game/l10n/app_localizations.dart';
import 'package:balloon_game/utils/app_const.dart';
import 'package:balloon_game/utils/base_game_state.dart';
import 'package:balloon_game/utils/game_storage.dart';
import 'package:balloon_game/widgets/info_chip.dart';
import 'package:flutter/material.dart';

class Game04Screen extends StatefulWidget {
  const Game04Screen({super.key});

  @override
  State<Game04Screen> createState() => _Game04ScreenState();
}

const int _kBalloonCount = 100;
const int _kBalloonBatchSize = 10;
const double _kBalloonSize = 74;
const double _kBalloonHeight = _kBalloonSize * 1.3;
const List<String> _kLetters = [
  'A',
  'B',
  'C',
  'D',
  'E',
  'F',
  'G',
  'H',
  'I',
  'J',
];
const Duration _kClockRefresh = Duration(milliseconds: 50);
const Duration _kRuleFeedbackDuration = Duration(milliseconds: 650);

enum _GameStatus { ready, playing, complete }

class _TargetRule {
  final Color? color;
  final String? letter;

  const _TargetRule.color(this.color) : letter = null;
  const _TargetRule.letter(this.letter) : color = null;

  bool matches(_Balloon balloon) =>
      color != null ? balloon.color == color : balloon.letter == letter;
}

class _Balloon {
  final int id;
  final double x;
  final double y;
  final Color color;
  final String letter;
  bool popped = false;

  _Balloon({
    required this.id,
    required this.x,
    required this.y,
    required this.color,
    required this.letter,
  });
}

class _Game04ScreenState extends BaseGameState<Game04Screen> {
  late AppLocalizations l10n;
  final Random _random = Random();
  final Stopwatch _stopwatch = Stopwatch();

  Timer? _clockTimer;
  Timer? _ruleMessageTimer;
  _GameStatus _status = _GameStatus.ready;
  List<_TargetRule> _rules = [];
  List<_Balloon> _balloons = [];
  int _poppedCount = 0;
  int _elapsedMilliseconds = 0;
  String? _feedbackText;
  bool _bestSaveTriggered = false;

  @override
  bool get isPlaying => _status == _GameStatus.playing;

  @override
  String get bestScoreKey => GameStorage.bestScoreGame04;

  @override
  int get currentScore => _stopwatch.elapsedMilliseconds;

  @override
  void cancelAllTimers() {
    _clockTimer?.cancel();
    _ruleMessageTimer?.cancel();
    _stopwatch.stop();
  }

  @override
  void startTimers() {
    _stopwatch.start();
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(_kClockRefresh, (_) {
      if (_status != _GameStatus.playing || isPaused) return;
      final int elapsed = _stopwatch.elapsedMilliseconds;
      if (elapsed ~/ 50 != _elapsedMilliseconds ~/ 50) {
        setState(() => _elapsedMilliseconds = elapsed);
      }
    });
  }

  @override
  Future<void> saveBestScore() async {
    if (_status != _GameStatus.complete || _bestSaveTriggered) return;
    _bestSaveTriggered = true;
    await GameStorage.saveBestTimeIfLower(bestScoreKey, currentScore);
  }

  void _startGame() {
    cancelAllTimers();
    registerGameStart();
    _stopwatch.reset();
    _bestSaveTriggered = false;
    _createGame();

    setState(() {
      _poppedCount = 0;
      _elapsedMilliseconds = 0;
      _status = _GameStatus.playing;
    });

    startBgm();
    startTimers();
  }

  void _createGame() {
    final List<Color> targetColors = [...AppConst.balloonColors]
      ..shuffle(_random);
    final List<Color> chosenColors = targetColors.take(5).toList();
    final List<String> targetLetters = [..._kLetters]..shuffle(_random);
    final List<String> chosenLetters = targetLetters.take(5).toList();

    final bool startWithColor = _random.nextBool();
    _rules = List.generate(_kBalloonCount ~/ _kBalloonBatchSize, (index) {
      final bool isColorRule = index.isEven == startWithColor;
      final int targetIndex = index ~/ 2;
      return isColorRule
          ? _TargetRule.color(chosenColors[targetIndex])
          : _TargetRule.letter(chosenLetters[targetIndex]);
    });

    final List<Color> nonTargetColors = AppConst.balloonColors
        .where((color) => !chosenColors.contains(color))
        .toList();
    final List<String> nonTargetLetters = _kLetters
        .where((letter) => !chosenLetters.contains(letter))
        .toList();

    // 현재 단계의 풍선 묶음이 나머지 묶음보다 위에 쌓이도록 순서를 뒤집어 배치한다.
    final List<List<_Balloon>> batches = [];
    int id = 0;
    for (final rule in _rules) {
      batches.add([
        for (int i = 0; i < _kBalloonBatchSize; i++)
          _Balloon(
            id: id++,
            x: _random.nextDouble(),
            y: _random.nextDouble(),
            color:
                rule.color ??
                nonTargetColors[_random.nextInt(nonTargetColors.length)],
            letter:
                rule.letter ??
                nonTargetLetters[_random.nextInt(nonTargetLetters.length)],
          ),
      ]);
    }
    _balloons = batches.reversed.expand((batch) => batch).toList();
  }

  void _onTapBalloon(_Balloon balloon) {
    if (_status != _GameStatus.playing || isPaused || balloon.popped) return;
    final _TargetRule rule = _rules[_poppedCount ~/ _kBalloonBatchSize];
    if (!rule.matches(balloon)) return;

    setState(() {
      balloon.popped = true;
      _poppedCount++;
    });

    if (_poppedCount == _kBalloonCount) {
      _finishGame();
    } else if (_poppedCount % _kBalloonBatchSize == 0) {
      _showRuleChangeMessage();
    }
  }

  void _showRuleChangeMessage() {
    _ruleMessageTimer?.cancel();
    setState(() => _feedbackText = l10n.game04ScreenRuleChangeFeedback);
    _ruleMessageTimer = Timer(_kRuleFeedbackDuration, () {
      if (!mounted) return;
      setState(() => _feedbackText = null);
    });
  }

  @override
  void onPause() {
    _ruleMessageTimer?.cancel();
    _feedbackText = null;
  }

  void _finishGame() {
    cancelAllTimers();
    _elapsedMilliseconds = _stopwatch.elapsedMilliseconds;
    stopBgm();
    setState(() => _status = _GameStatus.complete);
    unawaited(saveBestScore());
  }

  String _formatTime(int milliseconds) =>
      (milliseconds / 1000).toStringAsFixed(2);

  Widget _buildRuleBoard(_TargetRule rule) {
    final bool isColorRule = rule.color != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppConst.mainColor.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isColorRule ? Icons.palette_rounded : Icons.text_fields_rounded,
            color: AppConst.mainColor,
            size: 22,
          ),
          const SizedBox(width: 9),
          Text(
            isColorRule
                ? l10n.game04ScreenColorRule
                : l10n.game04ScreenLetterRule,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppConst.cardTitleColor,
            ),
          ),
          const SizedBox(width: 12),
          if (isColorRule)
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: rule.color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black12, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: 34,
              height: 34,
              child: Center(
                child: Text(
                  rule.letter!,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: AppConst.cardTitleColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBalloonBox() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxLeft = max(
          0.0,
          constraints.maxWidth - _kBalloonSize,
        ).toDouble();
        final double maxTop = max(
          0.0,
          constraints.maxHeight - _kBalloonHeight,
        ).toDouble();

        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.40),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 3,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Stack(
              children: [
                for (final balloon in _balloons)
                  Positioned(
                    key: ValueKey(balloon.id),
                    left: balloon.x * maxLeft,
                    top: balloon.y * maxTop,
                    child: IgnorePointer(
                      ignoring: balloon.popped,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _onTapBalloon(balloon),
                        child: AnimatedScale(
                          scale: balloon.popped ? 1.35 : 1,
                          duration: const Duration(milliseconds: 140),
                          child: AnimatedOpacity(
                            opacity: balloon.popped ? 0 : 1,
                            duration: const Duration(milliseconds: 140),
                            child: LabeledBalloon(
                              size: _kBalloonSize,
                              color: balloon.color,
                              label: balloon.letter,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompleteOverlay() {
    return buildDialogCard(
      title: l10n.game04ScreenCompleteTitle,
      message: l10n.game04ScreenCompleteMessage(
        _formatTime(_elapsedMilliseconds),
      ),
      primaryLabel: l10n.game04ScreenReplayButton,
      onPrimaryAction: _startGame,
    );
  }

  @override
  Widget build(BuildContext context) {
    l10n = AppLocalizations.of(context)!;
    final bool showBoard = _status == _GameStatus.playing && !isPaused;
    final _TargetRule? currentRule = _status == _GameStatus.playing
        ? _rules[_poppedCount ~/ _kBalloonBatchSize]
        : null;

    return withSystemBackPause(
      Scaffold(
        body: GameBackground(
          child: Stack(
            children: [
              if (showBoard)
                Positioned.fill(
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 142, 14, 18),
                      child: _buildBalloonBox(),
                    ),
                  ),
                ),
              GameTopBar(
                pauseButton: buildPauseButton(),
                chips: [
                  InfoChip(
                    icon: Icons.bubble_chart_rounded,
                    value: '$_poppedCount',
                    unit: '/$_kBalloonCount',
                    width: 110,
                  ),
                  InfoChip(
                    icon: Icons.timer_rounded,
                    value: _formatTime(_elapsedMilliseconds),
                    unit: l10n.game04ScreenSecondsUnit,
                    width: 110,
                  ),
                ],
                bottom: showBoard && currentRule != null
                    ? _buildRuleBoard(currentRule)
                    : null,
              ),
              if (_feedbackText != null)
                IgnorePointer(
                  child: FeedbackOverlay(text: _feedbackText!, correct: true),
                ),
              if (_status == _GameStatus.ready)
                StartOverlay(
                  message: l10n.game04ScreenStartMessage,
                  buttonLabel: l10n.game04ScreenStartButton,
                  onStart: _startGame,
                ),
              if (_status == _GameStatus.complete) _buildCompleteOverlay(),
            ],
          ),
        ),
      ),
    );
  }
}
