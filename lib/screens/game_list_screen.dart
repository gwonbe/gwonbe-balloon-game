import 'package:balloon_game/l10n/app_localizations.dart';
import 'package:balloon_game/screens/game01_screen.dart';
import 'package:balloon_game/screens/game02_screen.dart';
import 'package:balloon_game/screens/game03_screen.dart';
import 'package:balloon_game/utils/game_storage.dart';
import 'package:balloon_game/widgets/app_version_text.dart';
import 'package:flutter/material.dart';

class GameItem {
  final String title;
  final String description;
  final IconData icon;
  final WidgetBuilder builder;
  final String bestScoreKey;
  final int gameNumber;

  const GameItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.builder,
    required this.bestScoreKey,
    required this.gameNumber,
  });
}

class GameListScreen extends StatefulWidget {
  const GameListScreen({super.key});

  @override
  State<GameListScreen> createState() => _GameListScreenState();
}

class _GameListScreenState extends State<GameListScreen> {
  late List<GameItem> _games;

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
    final l10n = AppLocalizations.of(context)!;

    _games = [
      GameItem(
        title: l10n.game01Title,
        description: l10n.game01Description,
        icon: Icons.bubble_chart,
        builder: (context) => const Game01Screen(),
        bestScoreKey: GameStorage.bestScoreGame01,
        gameNumber: 1,
      ),
      GameItem(
        title: l10n.game02Title,
        description: l10n.game02Description,
        icon: Icons.close,
        builder: (context) => const Game02Screen(),
        bestScoreKey: GameStorage.bestScoreGame02,
        gameNumber: 2,
      ),
      GameItem(
        title: l10n.game03Title,
        description: l10n.game03Description,
        icon: Icons.calculate,
        builder: (context) => const Game03Screen(),
        bestScoreKey: GameStorage.bestScoreGame03,
        gameNumber: 3,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.gameListScreenTitle),
      ),
      body: Stack(
        children: [
          ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
            itemCount: _games.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final game = _games[index];
              final int best = _bestScores[game.bestScoreKey] ?? 0;

              final String title;
              final String description;

              switch (game.gameNumber) {
                case 1:
                  title = l10n.game01Title;
                  description = l10n.game01Description;
                  break;
                case 2:
                  title = l10n.game02Title;
                  description = l10n.game02Description;
                  break;
                default:
                  title = l10n.game03Title;
                  description = l10n.game03Description;
              }

              final String bestText;

              if (best == 0) {
                bestText = l10n.gameListScreenNoRecord;
              } else {
                switch (game.gameNumber) {
                  case 1:
                    bestText = l10n.game01BestScore(best, 0);
                    break;
                  case 2:
                    bestText = l10n.game02BestScore(best);
                    break;
                  default:
                    bestText = l10n.game03BestScore(best);
                }
              }

              return _GameCard(
                game: game,
                title: title,
                description: description,
                bestText: bestText,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: game.builder),
                  );
                },
              );
            },
          ),
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(child: AppVersionText(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}

/// 게임 목록의 카드 한 칸. 높이가 고정이라 모든 카드의 크기가 같다.
class _GameCard extends StatelessWidget {
  final GameItem game;
  final String title;
  final String description;
  final String bestText;
  final VoidCallback onTap;

  const _GameCard({
    required this.game,
    required this.title,
    required this.description,
    required this.bestText,
    required this.onTap,
  });

  Color get _accentColor {
    switch (game.gameNumber) {
      case 1:
        return const Color(0xFF4A9FE8);
      case 2:
        return const Color(0xFF9270DB);
      default:
        return const Color(0xFF45AD87);
    }
  }

  Color get _backgroundColor {
    switch (game.gameNumber) {
      case 1:
        return const Color(0xFFF1F8FF);
      case 2:
        return const Color(0xFFF7F3FF);
      default:
        return const Color(0xFFF0FAF5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _accentColor;

    return SizedBox(
      height: 130,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 2,
        shadowColor: color.withValues(alpha: 0.12),
        color: _backgroundColor,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              Container(width: 5, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(15)),
                        child: Icon(game.icon, color: color, size: 25),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF263448)),
                            ),
                            const SizedBox(height: 4),
                            ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 36),
                              child: Text(
                                description,
                                style: TextStyle(fontSize: 13, height: 1.4, color: Colors.blueGrey.shade700),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(Icons.emoji_events_rounded, size: 17, color: color),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    bestText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right_rounded, color: color, size: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}