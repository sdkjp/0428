import 'package:flutter/material.dart';

class LayerClipPainter extends CustomPainter {
  final Color baseColor;
  final int stackIndex;
  final bool isHovered;
  final bool isDragging;

  const LayerClipPainter({
    required this.baseColor,
    this.stackIndex = 0,
    this.isHovered = false,
    this.isDragging = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const radius = Radius.circular(10);
    final rect = Offset.zero & size;
    final rRect = RRect.fromRectAndRadius(rect, radius);

    // --- Shadow copies behind to simulate physical stacking ---
    for (var i = stackIndex; i > 0; i--) {
      final shadowOffset = Offset(i * 3.0, i * 3.0);
      final shadowRect =
          Rect.fromLTWH(shadowOffset.dx, shadowOffset.dy, size.width, size.height);
      final shadowRRect = RRect.fromRectAndRadius(shadowRect, radius);
      canvas.drawRRect(
        shadowRRect,
        Paint()
          ..color = baseColor.withOpacity(0.08 + i * 0.03)
          ..style = PaintingStyle.fill,
      );
    }

    // --- Base fill (glass effect) ---
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          baseColor.withOpacity(isHovered ? 0.32 : 0.20),
          baseColor.withOpacity(isHovered ? 0.18 : 0.10),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rRect, fillPaint);

    // --- Top-edge highlight (simulates light on glass) ---
    final topHighlight = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.center,
        colors: [
          Colors.white.withOpacity(0.22),
          Colors.transparent,
        ],
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height * 0.5),
        radius,
      ),
      topHighlight,
    );

    // --- Left-edge highlight ---
    final leftHighlight = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.center,
        colors: [
          Colors.white.withOpacity(0.10),
          Colors.transparent,
        ],
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width * 0.5, size.height),
        radius,
      ),
      leftHighlight,
    );

    // --- Border ---
    canvas.drawRRect(
      rRect,
      Paint()
        ..color = baseColor.withOpacity(isHovered ? 0.75 : 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // --- Hover: inner glow ---
    if (isHovered) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.deflate(2),
          const Radius.circular(8),
        ),
        Paint()
          ..color = baseColor.withOpacity(0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    // --- Dragging: dashed outline ---
    if (isDragging) {
      canvas.drawRRect(
        rRect,
        Paint()
          ..color = Colors.white.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(LayerClipPainter old) =>
      old.isHovered != isHovered ||
      old.isDragging != isDragging ||
      old.stackIndex != stackIndex ||
      old.baseColor != baseColor;
}
