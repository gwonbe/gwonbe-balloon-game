import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences 저장/조회 모음
class GameStorage {
  GameStorage._();

  static const String adCountKey = 'adCount';
  static const String bestScoreGame01 = 'bestScoreGame01';
  static const String bestScoreGame02 = 'bestScoreGame02';

  /// 최고 기록이 저장될 때마다 값이 바뀐다. 목록 화면이 이를 듣고 다시 읽는다.
  static final ValueNotifier<int> bestScoreChanged = ValueNotifier<int>(0);

  // ───────── 광고 카운트 ─────────

  static Future<int> getAdCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(adCountKey) ?? 0;
  }

  static Future<void> setAdCount(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(adCountKey, value);
  }

  /// 1 증가시키고 증가된 값을 반환
  static Future<int> incrementAdCount() async {
    final prefs = await SharedPreferences.getInstance();
    final int next = (prefs.getInt(adCountKey) ?? 0) + 1;
    await prefs.setInt(adCountKey, next);
    return next;
  }

  // ───────── 최고 기록 ─────────

  static Future<int> getBestScore(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key) ?? 0;
  }

  /// 기존 최고 기록보다 높을 때만 덮어쓴다. 갱신했으면 true.
  static Future<bool> saveBestScoreIfHigher(String key, int score) async {
    if (score <= 0) return false;
    final prefs = await SharedPreferences.getInstance();
    final int best = prefs.getInt(key) ?? 0;
    if (score <= best) return false;
    await prefs.setInt(key, score);
    bestScoreChanged.value++;
    return true;
  }
}