import 'dart:async';
import 'dart:math';
import 'package:balloon_game/utils/base_game_state.dart';
import 'package:balloon_game/utils/game_storage.dart';
import 'package:balloon_game/widgets/balloon_painter.dart';
import 'package:balloon_game/widgets/info_chip.dart';
import 'package:flutter/material.dart';

class Game02Screen extends StatefulWidget {
  const Game02Screen({super.key});

  @override
  State<Game02Screen> createState() => _Game02ScreenState();
}

// ───────── 상수 ─────────

/// 제한 시간(초)
const int kGame02Duration = 60;

/// 3x3 그리드
const int _kGridColumns = 3;
const int _kGridCount = 9;

/// 구구단 단 범위 (문제: 단 × 1~9)
const int _kMinDan = 2;
const int _kMaxDan = 9;

/// 정답/오답 메시지 표시 시간
const Duration _kFeedbackDuration = Duration(milliseconds: 700);

/// 풍선이 터지는 애니메이션 시간
const Duration _kPopDuration = Duration(milliseconds: 180);

const List<Color> _kBalloonPalette = [
  Colors.red,
  Colors.pink,
  Colors.orange,
  Colors.amber,
  Colors.green,
  Colors.teal,
  Colors.blue,
  Colors.indigo,
  Colors.purple,
];

/// 구구단에 나올 수 있는 모든 곱셈 결과 (오답 후보 풀)
final List<int> _kAllProducts = {
  for (int i = 1; i <= 9; i++)
    for (int j = 1; j <= 9; j++) i * j,
}.toList();

enum _GameStatus {
  ready, // 시작 전
  playing, // 진행 중 (일시정지는 부모의 isPaused로 관리)
  gameOver, // 시간 종료
}

// ───────── 모델 ─────────

/// 구구단 문제 하나: dan × multiplier
class _Question {
  final int dan;
  final int multiplier;

  const _Question(this.dan, this.multiplier);

  int get answer => dan * multiplier;

  factory _Question.random(Random random) {
    return _Question(
      _kMinDan + random.nextInt(_kMaxDan - _kMinDan + 1),
      1 + random.nextInt(9),
    );
  }

  /// 정답 1개 + 오답 8개를 섞어서 반환한다.
  /// 오답은 헷갈리기 쉬운 값(옆 단/옆 곱)을 먼저 넣고, 부족하면 구구단 결과에서 채운다.
  List<int> buildChoices(Random random) {
    final Set<int> wrong = {};

    final List<int> near = [
      if (multiplier > 1) dan * (multiplier - 1),
      if (multiplier < 9) dan * (multiplier + 1),
      if (dan > 1) (dan - 1) * multiplier,
      if (dan < 9) (dan + 1) * multiplier,
    ]..shuffle(random);
    wrong.addAll(near.where((v) => v != answer));

    final List<int> pool = _kAllProducts
        .where((v) => v != answer && !wrong.contains(v))
        .toList()
      ..shuffle(random);
    wrong.addAll(pool.take(_kGridCount - 1 - wrong.length));

    return [answer, ...wrong.take(_kGridCount - 1)]..shuffle(random);
  }
}

/// 그리드 한 칸의 풍선
class _Cell {
  final int value;
  final Color color;
  bool popped = false;

  _Cell({required this.value, required this.color});
}

// ───────── State ─────────

class _Game02ScreenState extends BaseGameState<Game02Screen> {
  final Random _random = Random();

  Timer? _gameTimer; // 1초마다 남은 시간 감소
  Timer? _feedbackTimer; // 정답/오답 메시지 자동으로 사라지게

  _GameStatus _status = _GameStatus.ready;
  int _score = 0;
  int _timeLeft = kGame02Duration;

  _Question _question = const _Question(2, 1);
  List<_Cell> _cells = const [];

  // 정답을 맞혀서 메시지가 끝나면 새 문제로 넘어가야 하는 상태
  bool _pendingNext = false;

  // 정답/오답 피드백 메시지
  String? _feedbackText;
  bool _feedbackCorrect = false;

  // ───────── BaseGameState 구현부 ─────────

  @override
  bool get isPlaying => _status == _GameStatus.playing;

  @override
  String get bestScoreKey => GameStorage.bestScoreGame02;

  @override
  int get currentScore => _score;

  @override
  void cancelAllTimers() {
    _gameTimer?.cancel();
    _feedbackTimer?.cancel();
  }

  @override
  void startTimers() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_status != _GameStatus.playing) return;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) _endGame();
    });
  }

  @override
  void onPause() {
    // 피드백 타이머가 취소되므로 메시지를 미리 지우고, 넘어갈 문제가 있으면 처리한다.
    _feedbackText = null;
    if (_pendingNext) _prepareNextQuestion();
  }

  // ───────── 게임 로직 ─────────

  /// 새 문제와 새 풍선 9개를 만든다. (setState 없음: setState 안이나 직전에 호출)
  void _prepareNextQuestion() {
    _question = _Question.random(_random);

    final List<int> values = _question.buildChoices(_random);
    final List<Color> colors = List<Color>.from(_kBalloonPalette)
      ..shuffle(_random);

    _cells = List.generate(
      _kGridCount,
          (i) => _Cell(value: values[i], color: colors[i]),
    );
    _pendingNext = false;
  }

  void _startGame() {
    cancelAllTimers();
    registerGameStart();
    _prepareNextQuestion();
    setState(() {
      _score = 0;
      _timeLeft = kGame02Duration;
      _status = _GameStatus.playing;
      _feedbackText = null;
    });

    startBgm(); // 이미 재생 중이면 무시된다.
    startTimers();
  }

  void _endGame() {
    cancelAllTimers();
    stopBgm(); // 게임 종료 다이얼로그에 머무는 동안 음악 정지
    setState(() {
      _status = _GameStatus.gameOver;
      _feedbackText = null;
      _pendingNext = false;
    });
  }

  void _showFeedback(bool correct) {
    _feedbackTimer?.cancel();
    setState(() {
      _feedbackCorrect = correct;
      _feedbackText = correct ? '딩동댕!' : '땡!';
    });
    _feedbackTimer = Timer(_kFeedbackDuration, () {
      if (!mounted) return;
      setState(() {
        _feedbackText = null;
        // 정답이었다면 메시지가 끝난 뒤 새 문제와 새 풍선을 만든다.
        if (_pendingNext) _prepareNextQuestion();
      });
    });
  }

  void _onTapCell(int index) {
    if (_status != _GameStatus.playing || isPaused) return;
    if (_feedbackText != null) return; // 메시지 표시 중 중복 탭 방지
    if (_cells[index].popped) return;

    if (_cells[index].value == _question.answer) {
      // 정답: 점수 +1, 모든 풍선 터뜨리기
      setState(() {
        _score++;
        for (final cell in _cells) {
          cell.popped = true;
        }
        _pendingNext = true;
      });
      _showFeedback(true);
    } else {
      // 오답: 누른 풍선만 터뜨리기
      setState(() => _cells[index].popped = true);
      _showFeedback(false);
    }
  }

  // ───────── UI ─────────

  @override
  Widget build(BuildContext context) {
    // 일시정지 중에는 문제/보기를 가려서 시간이 멈춘 채 답을 찾지 못하게 한다.
    final bool showBoard = _status == _GameStatus.playing && !isPaused;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF87CEEB), Color(0xFFE0F7FA)],
          ),
        ),
        child: Stack(
          children: [
            if (showBoard)
              Positioned.fill(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 140),
                    child: Center(child: _buildGrid()),
                  ),
                ),
              ),
            _buildTopBar(showBoard),
            if (_feedbackText != null)
              _FeedbackOverlay(
                text: _feedbackText!,
                correct: _feedbackCorrect,
              ),
            if (_status == _GameStatus.ready)
              _StartOverlay(onStart: _startGame),
            if (_status == _GameStatus.gameOver) _buildGameOverOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double gap = 16;
        final double gridWidth = min(constraints.maxWidth * 0.85, 340);
        final double cellSize =
            (gridWidth - gap * (_kGridColumns - 1)) / _kGridColumns;

        return SizedBox(
          width: gridWidth,
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (int i = 0; i < _cells.length; i++)
                _PoppableBalloon(
                  size: cellSize,
                  cell: _cells[i],
                  onTap: () => _onTapCell(i),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(bool showBoard) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                buildPauseButton(),
                Row(
                  children: [
                    InfoChip(
                      icon: Icons.star,
                      value: '$_score',
                      unit: '점',
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
            if (showBoard) ...[
              const SizedBox(height: 14),
              _QuestionBoard(question: _question),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return buildDialogCard(
      title: '시간 종료! ⏰',
      message: '맞힌 개수 : $_score',
      titleColor: Colors.black87,
      onPrimaryAction: () => Navigator.of(context).maybePop(), // 게임 목록으로
      primaryLabel: '확인',
      primaryColor: Colors.blue,
      showQuitButton: false,
    );
  }
}

// ───────── 위젯 ─────────

/// 상단 문제 표시: [단] × [곱]
class _QuestionBoard extends StatelessWidget {
  final _Question question;

  const _QuestionBoard({required this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LabeledBalloon(
            size: 56,
            color: Colors.blueAccent,
            label: '${question.dan}',
          ),
          const SizedBox(width: 10),
          const _LabeledBalloon(
            size: 56,
            color: Colors.redAccent,
            label: '×',
          ),
          const SizedBox(width: 10),
          _LabeledBalloon(
            size: 56,
            color: Colors.blueAccent,
            label: '${question.multiplier}',
          ),
        ],
      ),
    );
  }
}

/// 터지면(커지면서 투명해짐) 탭이 막히는 그리드 풍선.
/// 자리는 그대로 유지되므로 나머지 풍선의 위치가 밀리지 않는다.
class _PoppableBalloon extends StatelessWidget {
  final double size;
  final _Cell cell;
  final VoidCallback onTap;

  const _PoppableBalloon({
    required this.size,
    required this.cell,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool popped = cell.popped;
    return IgnorePointer(
      ignoring: popped,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: popped ? 1.4 : 1.0,
          duration: _kPopDuration,
          child: AnimatedOpacity(
            opacity: popped ? 0.0 : 1.0,
            duration: _kPopDuration,
            child: _LabeledBalloon(
              size: size,
              color: cell.color,
              label: '${cell.value}',
            ),
          ),
        ),
      ),
    );
  }
}

/// 딩동댕! / 땡! 메시지
class _FeedbackOverlay extends StatelessWidget {
  final String text;
  final bool correct;

  const _FeedbackOverlay({required this.text, required this.correct});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        decoration: BoxDecoration(
          color: (correct ? Colors.green : Colors.red).withValues(alpha: 0.9),
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

/// 게임 시작 전 안내
class _StartOverlay extends StatelessWidget {
  final VoidCallback onStart;

  const _StartOverlay({required this.onStart});

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
              const Text(
                '구구단의 정답을 찾아 터뜨리세요!\n'
                    '$kGame02Duration초 동안 최대한 많이 맞혀보세요!',
                style: TextStyle(fontSize: 16, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onStart,
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
}

/// 숫자/기호 텍스트가 표시된 풍선 (그리드와 상단 문제 풍선 공용)
class _LabeledBalloon extends StatelessWidget {
  final double size;
  final Color color;
  final String label;

  const _LabeledBalloon({
    required this.size,
    required this.color,
    required this.label,
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
            painter: BalloonPainter(color: color),
          ),
          Align(
            alignment: const Alignment(0, -0.35),
            child: Text(
              label,
              style: TextStyle(
                fontSize: size * 0.34,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: const [
                  Shadow(
                    color: Colors.black38,
                    blurRadius: 3,
                    offset: Offset(0, 1),
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