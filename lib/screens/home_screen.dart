import 'package:balloon_game/screens/game_list_screen.dart';
import 'package:balloon_game/utils/app_bgm.dart';
import 'package:balloon_game/widgets/app_version_text.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    AppBgm.home.start(); // 이미 재생 중이면 무시됨

    // 애니메이션 컨트롤러 설정 (1초 단위로 왕복)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true); // 무한 반복 (투명해졌다가 다시 나타남)

    // 투명도 변화 비율 설정
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    // 위젯 파괴 시 컨트롤러 메모리 해제
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const GameListScreen()),
          );
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFFB8E3F3), // 남은 부분을 채울 배경 색상
          child: Stack(
            children: [
              Center(
                child: Image.asset(
                  'assets/home_001.png',
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: Center(
                  // FadeTransition으로 감싸 깜빡이는 효과 적용
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: const Text(
                      '터치하세요!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 4.0,
                            color: Color(0x80000000), // 텍스트 가독성을 위한 그림자
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: AppVersionText(
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        offset: Offset(0, 2),
                        blurRadius: 4.0,
                        color: Color(0x80000000),
                      ),
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