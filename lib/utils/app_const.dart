import 'package:flutter/material.dart';

/// 앱 전체에서 쓰는 정적 상수 모음
class AppConst {
  AppConst._();

  // ───────── 메인 색상 ─────────
  static const Color mainColor = Color(0xFFE01F66);
  static const Color bgColor = Color(0xFFB8E3F3);

  // ───────── 풍선 색상 (게임 공통 10색 팔레트) ─────────
  static const List<Color> balloonColors = [
    Color(0xFFE62169),
    Color(0xFFF68028),
    Color(0xFFF9DE37),
    Color(0xFF50B356),
    Color(0xFF3096D8),
    Color(0xFF86489D),
    Color(0xFF1BB3A6),
    Color(0xFF2B4C9B),
    Color(0xFF9ACD32),
    Color(0xFF795548),
  ];

  // ───────── 게임 목록 카드 ─────────
  // 글자(최고 기록)로도 쓰이므로 흰색과의 대비 4.5:1 이상으로 맞춘 진한 톤을 쓴다.
  static const Color game01Color = mainColor;
  static const Color game01Background = Color(0xFFFFF0F5);
  static const Color game02Color = Color(0xFF2279C2);
  static const Color game02Background = Color(0xFFEEF6FD);
  static const Color game03Color = Color(0xFF86489D);
  static const Color game03Background = Color(0xFFF7F0FA);
  static const Color game04Color = Color(0xFF008C82);
  static const Color game04Background = Color(0xFFE9F8F6);
  static const Color cardTitleColor = Color(0xFF263448);

  // ───────── 정보 칩 ─────────
  static const Color infoChipIcon = mainColor;
  static const Color infoChipValue = mainColor;
  static const Color infoChipUnit = Colors.black54;

  // ───────── 다이얼로그 ─────────
  static const Color dialogBackground = Colors.white;
  static const Color dialogText = Colors.black;
  static const Color dialogPrimaryButton = mainColor;
  static const Color dialogPrimaryButtonText = Colors.white;
  static const Color dialogSecondaryButton = Colors.white;
  static const Color dialogSecondaryButtonText = Colors.black;
  static const Color dialogSecondaryButtonBorder = Color(0xFFBDBDBD);
  // 다이얼로그 뒤 어두운 배경
  static const Color dialogScrim = Color(0x80000000);

  // ───────── 게임 화면 배경(하늘) ─────────
  static const Color skyTop = Color(0xFF87CEEB);
  static const Color skyBottom = Color(0xFFE0F7FA);

  // ───────── 피드백(딩동댕/땡) ─────────
  static const Color feedbackCorrect = Color(0xFF2E8B40);
  static const Color feedbackWrong = Color(0xFFE53935);
}
