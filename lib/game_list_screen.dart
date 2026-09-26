import 'package:flutter/material.dart';
import 'game01.dart';

/// 게임 목록에 들어갈 항목 하나를 표현하는 모델.
/// 새 게임을 추가하려면 아래 _games 리스트에 항목만 추가하면 됩니다.
class GameItem {
  final String title;
  final IconData icon;
  final WidgetBuilder builder;

  const GameItem({
    required this.title,
    required this.icon,
    required this.builder,
  });
}

class GameListScreen extends StatelessWidget {
  const GameListScreen({super.key});

  static final List<GameItem> _games = [
    GameItem(
      title: '터뜨리기',
      icon: Icons.bubble_chart,
      builder: (context) => const Game01Screen(),
    ),
    // 예) GameItem(title: '두번째 게임', icon: Icons.videogame_asset, builder: (context) => const Game02Screen()),
  ];

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
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Icon(game.icon, color: Colors.blue.shade700),
              ),
              title: Text(
                game.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: game.builder),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
