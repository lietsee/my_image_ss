import 'package:flutter/material.dart';

/// スクリーンショット領域外を暗くするペインター
class OverlayPainter extends CustomPainter {
  final Rect holeRect;
  final Color overlayColor;

  OverlayPainter({
    required this.holeRect,
    this.overlayColor = const Color(0x80000000),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    // 全体を覆うパス
    final fullPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // 穴（キャプチャ領域）のパス
    final holePath = Path()..addRect(holeRect);

    // 穴を除いた領域を描画
    final overlayPath = Path.combine(PathOperation.difference, fullPath, holePath);
    canvas.drawPath(overlayPath, paint);

    // キャプチャ領域の枠線
    final borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(holeRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant OverlayPainter oldDelegate) {
    return oldDelegate.holeRect != holeRect ||
        oldDelegate.overlayColor != overlayColor;
  }
}
