import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';

class TimelineRuler extends StatelessWidget {
  final DateTime originDate;
  final double pixelsPerDay;
  final double width;

  const TimelineRuler({
    super.key,
    required this.originDate,
    required this.pixelsPerDay,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppConstants.timelineRulerHeight,
      width: width,
      child: CustomPaint(
        painter: _RulerPainter(
          originDate: originDate,
          pixelsPerDay: pixelsPerDay,
          width: width,
        ),
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  final DateTime originDate;
  final double pixelsPerDay;
  final double width;

  _RulerPainter({
    required this.originDate,
    required this.pixelsPerDay,
    required this.width,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF141420);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFF2A2A40)
      ..strokeWidth = 1;
    canvas.drawLine(
        Offset(0, size.height), Offset(size.width, size.height), borderPaint);

    final tickPaint = Paint()
      ..color = const Color(0xFF3A3A54)
      ..strokeWidth = 1;
    final majorTickPaint = Paint()
      ..color = const Color(0xFF4A4A68)
      ..strokeWidth = 1;

    final dayFmt = DateFormat('M/d');
    final monthFmt = DateFormat('yyyy年M月');

    // Calculate how many days fit
    final daysVisible = (width / pixelsPerDay).ceil() + 2;
    final startDay = originDate;

    for (var i = 0; i <= daysVisible; i++) {
      final day = startDay.add(Duration(days: i));
      final x = i * pixelsPerDay;

      final isFirstOfMonth = day.day == 1;
      final isMajor = isFirstOfMonth || pixelsPerDay > 100;

      if (isMajor) {
        canvas.drawLine(
            Offset(x, size.height - 16),
            Offset(x, size.height),
            isFirstOfMonth ? majorTickPaint : tickPaint);

        final text = isFirstOfMonth
            ? monthFmt.format(day)
            : (pixelsPerDay > 60 ? dayFmt.format(day) : '');

        if (text.isNotEmpty) {
          final tp = TextPainter(
            text: TextSpan(
              text: text,
              style: TextStyle(
                color: isFirstOfMonth
                    ? const Color(0xFFB0B0C8)
                    : const Color(0xFF606080),
                fontSize: isFirstOfMonth ? 11 : 9,
                fontWeight: isFirstOfMonth
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
            textDirection: ui.TextDirection.ltr,
          )..layout();
          tp.paint(
              canvas, Offset(x + 3, size.height - 14 - tp.height));
        }
      } else {
        // Minor tick every day
        canvas.drawLine(
            Offset(x, size.height - 6),
            Offset(x, size.height),
            tickPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_RulerPainter old) =>
      old.pixelsPerDay != pixelsPerDay ||
      old.originDate != originDate ||
      old.width != width;
}
