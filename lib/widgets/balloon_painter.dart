import 'package:flutter/material.dart';

/// 풍선 그리기 (몸통 + 하이라이트 + 줄).
class BalloonPainter extends CustomPainter {
  final Color color;
  final bool withShadow;

  BalloonPainter({required this.color, this.withShadow = false});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final Rect balloonRect = Rect.fromLTWH(0, 0, size.width, size.height * 0.8);
    final RRect rect = RRect.fromRectAndCorners(
      balloonRect,
      topLeft: Radius.circular(size.width / 2),
      topRight: Radius.circular(size.width / 2),
      bottomLeft: Radius.circular(size.width / 2.5),
      bottomRight: Radius.circular(size.width / 2.5),
    );
    if (withShadow) {
      final Paint shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
      canvas.drawRRect(rect.shift(const Offset(1.5, 3)), shadowPaint);
    }
    canvas.drawRRect(rect, paint);

    // 하이라이트(반짝임)
    final Paint highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4);
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.2,
        size.height * 0.15,
        size.width * 0.2,
        size.height * 0.15,
      ),
      highlightPaint,
    );

    // 풍선 줄
    final Paint stringPaint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final Path path = Path()
      ..moveTo(size.width / 2, size.height * 0.8)
      ..lineTo(size.width / 2, size.height);
    canvas.drawPath(path, stringPaint);
  }

  @override
  bool shouldRepaint(covariant BalloonPainter oldPainter) {
    return oldPainter.color != color || oldPainter.withShadow != withShadow;
  }
}
