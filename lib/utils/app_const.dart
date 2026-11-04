import 'package:flutter/material.dart';

/// 앱 전체에서 쓰는 정적 상수 모음. (동심 가득한 원색 컨셉)
/// 색상은 홈 이미지(풍선/타이틀)와 앱 아이콘(분홍 풍선)에서 따왔다.
class AppConst {
  AppConst._();

  // ───────── 메인 색상 ─────────
  // 앱 아이콘의 분홍 풍선(#E62169)에서 따온 색.
  // 흰색 글자와 함께 쓰이므로 명도 대비 4.5:1 이상이 되도록 아주 조금만 진하게 했다. (약 4.6:1)
  static const Color mainColor = Color(0xFFE01F66);

  // ───────── 풍선 색상 (홈 이미지의 풍선 색 6개 + 구분용 3개) ─────────
  static const List<Color> balloonColors = [
    Color(0xFFE62169), // 분홍 (홈 이미지)
    Color(0xFFF68028), // 주황 (홈 이미지)
    Color(0xFFF9DE37), // 노랑 (홈 이미지)
    Color(0xFF50B356), // 초록 (홈 이미지)
    Color(0xFF3096D8), // 파랑 (홈 이미지)
    Color(0xFF86489D), // 보라 (홈 이미지)
    Color(0xFF1BB3A6), // 청록
    Color(0xFF2B4C9B), // 남색 (타이틀 테두리 톤)
    Color(0xFF9ACD32), // 연두
  ];

  // ───────── 게임 목록 카드 ─────────
  // 글자(최고 기록)로도 쓰이므로 흰색과의 대비 4.5:1 이상으로 맞춘 진한 톤을 쓴다.
  static const Color game01Color = mainColor; // 분홍
  static const Color game01Background = Color(0xFFFFF0F5);
  static const Color game02Color = Color(0xFF2279C2); // 파랑
  static const Color game02Background = Color(0xFFEEF6FD);
  static const Color game03Color = Color(0xFF86489D); // 보라
  static const Color game03Background = Color(0xFFF7F0FA);
  static const Color game04Color = Color(0xFF008C82);
  static const Color game04Background = Color(0xFFE9F8F6);
  static const Color cardTitleColor = Color(0xFF263448);

  // ───────── 정보 칩 ─────────
  static const Color infoChipIcon = mainColor;
  static const Color infoChipValue = mainColor;
  static const Color infoChipUnit = Colors.black54;

  // ───────── 다이얼로그 ─────────
  // 배경은 항상 흰색, 글자는 항상 검은색.
  // 사용자가 눌렀으면 하는 버튼(계속/다음/확인/재도전)만 메인 색으로 채우고,
  // 나머지 버튼은 흰색 배경 + 얇은 테두리로 둔다.
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

  // ───────── game02 문제판 풍선 ─────────
  static const Color questionNumberColor = Color(0xFF3096D8); // 숫자: 파랑
  static const Color questionOperatorColor = mainColor; // ×: 분홍

  // ───────── 피드백(딩동댕/땡) ─────────
  static const Color feedbackCorrect = Color(0xFF2E8B40);
  static const Color feedbackWrong = Color(0xFFE53935);
}
