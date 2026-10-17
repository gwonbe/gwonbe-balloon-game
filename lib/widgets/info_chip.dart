import 'package:flutter/material.dart';

/// 상단 정보 칩 (아이콘 + 값 + 단위).
class InfoChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final double width;

  const InfoChip({
    super.key,
    required this.icon,
    required this.value,
    required this.unit,
    this.width = 105,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 왼쪽: 아이콘 고정
          SizedBox(
            width: 22,
            child: Icon(icon, size: 18, color: Colors.deepOrange),
          ),

          // 가운데: 숫자만 가운데 정렬
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),

          // 오른쪽: 단위 고정
          Text(
            unit,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}