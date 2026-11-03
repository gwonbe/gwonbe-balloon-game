import 'package:balloon_game/l10n/app_localizations.dart';
import 'package:balloon_game/screens/game01_screen.dart';
import 'package:balloon_game/screens/game02_screen.dart';
import 'package:balloon_game/screens/game03_screen.dart';
import 'package:balloon_game/utils/app_const.dart';
import 'package:balloon_game/utils/game_storage.dart';
import 'package:balloon_game/widgets/app_version_text.dart';
import 'package:flutter/material.dart';

class GameItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final WidgetBuilder builder;
  final String bestScoreKey;

  /// 최고 기록(0 초과)을 받아 목록에 보여줄 문구를 만든다.
  final String Function(int best) bestTextBuilder;

  const GameItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.builder,
    required this.bestScoreKey,
    required this.bestTextBuilder,
  });
}

class GameListScreen extends StatefulWidget {
  const GameListScreen({super.key});

  @override
  State<GameListScreen> createState() => _GameListScreenState();
}

class _GameListScreenState extends State<GameListScreen> {
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
    final keys = [
      GameStorage.bestScoreGame01,
      GameStorage.bestScoreGame02,
      GameStorage.bestScoreGame03,
    ];

    final scores = await Future.wait(
      keys.map((key) async => MapEntry(key, await GameStorage.getBestScore(key))),
    );

    if (!mounted) return;

    setState(() {
      _bestScores
        ..clear()
        ..addEntries(scores);
    });
  }

  List<GameItem> _buildGames(AppLocalizations l10n) {
    return [
      GameItem(
        title: l10n.game01Title,
        description: l10n.game01Description,
        icon: Icons.bubble_chart,
        color: AppConst.game01Color,
        backgroundColor: AppConst.game01Background,
        builder: (context) => const Game01Screen(),
        bestScoreKey: GameStorage.bestScoreGame01,
        bestTextBuilder: (best) => l10n.game01BestScore(best, 0),
      ),
      GameItem(
        title: l10n.game02Title,
        description: l10n.game02Description,
        icon: Icons.close,
        color: AppConst.game02Color,
        backgroundColor: AppConst.game02Background,
        builder: (context) => const Game02Screen(),
        bestScoreKey: GameStorage.bestScoreGame02,
        bestTextBuilder: (best) => l10n.game02BestScore(best),
      ),
      GameItem(
        title: l10n.game03Title,
        description: l10n.game03Description,
        icon: Icons.calculate,
        color: AppConst.game03Color,
        backgroundColor: AppConst.game03Background,
        builder: (context) => const Game03Screen(),
        bestScoreKey: GameStorage.bestScoreGame03,
        bestTextBuilder: (best) => l10n.game03BestScore(best),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final List<GameItem> games = _buildGames(l10n);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.gameListScreenTitle)),
      body: Stack(
        children: [
          ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
            itemCount: games.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final game = games[index];
              final int best = _bestScores[game.bestScoreKey] ?? 0;

              return _GameCard(
                game: game,
                bestText: best == 0
                    ? l10n.gameListScreenNoRecord
                    : game.bestTextBuilder(best),
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

/// 게임 목록 카드: 고정된 높이와 정보 배치로 각 항목을 한눈에 읽을 수 있다.
class _GameCard extends StatelessWidget {
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
    final Color color = game.color;
    final Color softColor = Color.lerp(game.backgroundColor, Colors.white, 0.42)!;

    return Container(
      height: 148,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.13),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(26),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, softColor],
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: color.withValues(alpha: 0.13)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: onTap,
            child: Stack(
              children: [
                Positioned(
                  right: -24,
                  top: -34,
                  child: Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.055),
                    ),
                  ),
                ),
                Positioned(
                  right: 32,
                  bottom: -43,
                  child: Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.045),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color.withValues(alpha: 0.20),
                              color.withValues(alpha: 0.09),
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color.withValues(alpha: 0.16),
                          ),
                        ),
                        child: Icon(game.icon, color: color, size: 28),
                      ),
                      const SizedBox(width: 15),
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
                                height: 1.15,
                                fontWeight: FontWeight.w800,
                                color: AppConst.cardTitleColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 40,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  game.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.35,
                                    color: Colors.blueGrey.shade700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 7),
                            Row(
                              children: [
                                Icon(
                                  Icons.emoji_events_rounded,
                                  size: 16,
                                  color: color,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    bestText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: color.withValues(alpha: 0.75),
                        size: 21,
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
