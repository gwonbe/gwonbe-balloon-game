import 'package:balloon_game/game01.dart';
import 'package:balloon_game/game02.dart';
import 'package:balloon_game/game03.dart';
import 'package:balloon_game/utils/game_storage.dart';
import 'package:flutter/material.dart';

class GameItem {
  final String title;
  final String description;
  final IconData icon;
  final WidgetBuilder builder;
  final String bestScoreKey;
  final String Function(int score) bestScoreLabel;

  const GameItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.builder,
    required this.bestScoreKey,
    required this.bestScoreLabel,
  });
}

class GameListScreen extends StatefulWidget {
  const GameListScreen({super.key});

  @override
  State<GameListScreen> createState() => _GameListScreenState();
}

class _GameListScreenState extends State<GameListScreen> {
  static final List<GameItem> _games = [
    GameItem(
      title: '둥실둥실',
      description: '풍선이 하늘로 올라가기 전에 터뜨리세요!',
      icon: Icons.bubble_chart,
      builder: (context) => const Game01Screen(),
      bestScoreKey: GameStorage.bestScoreGame01,
      bestScoreLabel: (score) => '$score / $kLevelCount 단계 클리어',
    ),
    GameItem(
      title: '구구단을 외자',
      description: '구구단 정답 풍선을 터뜨리세요!\n',
      icon: Icons.close,
      builder: (context) => const Game02Screen(),
      bestScoreKey: GameStorage.bestScoreGame02,
      bestScoreLabel: (score) => '$score개 정답',
    ),
    GameItem(
      title: '사칙연산',
      description: '사칙연산 정답 풍선을 터뜨리세요!\n',
      icon: Icons.calculate,
      builder: (context) => const Game03Screen(),
      bestScoreKey: GameStorage.bestScoreGame03,
      bestScoreLabel: (score) => '$score개 정답',
    ),
  ];

  /// 게임별 최고 기록 (key: SharedPreferences 키)
  final Map<String, int> _bestScores = {};

  @override
  void initState() {
    super.initState();
    GameStorage.bestScoreChanged.addListener(_loadBestScores);
    _loadBestScores();
  }

  @override
  void dispose() {
    GameStorage.bestScoreChanged.removeListener(_loadBestScores);
    super.dispose();
  }

  Future<void> _loadBestScores() async {
    final Map<String, int> loaded = {};
    for (final game in _games) {
      loaded[game.bestScoreKey] = await GameStorage.getBestScore(game.bestScoreKey);
    }
    if (!mounted) return;
    setState(() {
      _bestScores
        ..clear()
        ..addAll(loaded);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게임 목록'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _games.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final game = _games[index];
          final int best = _bestScores[game.bestScoreKey] ?? 0;
          final String bestText =
          best > 0 ? game.bestScoreLabel(best) : '기록 없음';

          return _GameCard(
            game: game,
            bestText: bestText,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: game.builder),
              );
            },
          );
        },
      ),
    );
  }
}

/// 게임 목록의 카드 한 칸. 높이가 고정이라 모든 카드의 크기가 같다.
class _GameCard extends StatelessWidget {
  static const double height = 96;

  final GameItem game;
  final String bestText;
  final VoidCallback onTap;

  const _GameCard({
    required this.game,
    required this.bestText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 2,
        clipBehavior: Clip.antiAlias, // 물결 효과가 둥근 모서리 밖으로 나가지 않게
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(game.icon, color: Colors.blue.shade700),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        game.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.emoji_events,
                              size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '최고 기록 : $bestText',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}