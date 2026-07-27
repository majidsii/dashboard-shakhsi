import 'package:flutter/material.dart';

enum OriginalIconType { check, tasks, wallet, sun, moon }

/// Small line-icon painter using the exact geometry embedded in the original
/// HTML. This avoids Material glyph differences in the three topbar islands.
final class OriginalIcon extends StatelessWidget {
  const OriginalIcon(
    this.type, {
    required this.color,
    super.key,
    this.size = 18,
    this.strokeWidth = 2.2,
  });

  final OriginalIconType type;
  final Color color;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _OriginalIconPainter(
        type: type,
        color: color,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

final class _OriginalIconPainter extends CustomPainter {
  const _OriginalIconPainter({
    required this.type,
    required this.color,
    required this.strokeWidth,
  });

  final OriginalIconType type;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 24;
    final sy = size.height / 24;
    canvas.save();
    canvas.scale(sx, sy);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth / ((sx + sy) / 2)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (type) {
      case OriginalIconType.check:
        canvas.drawPath(
          Path()
            ..moveTo(4, 13)
            ..lineTo(9, 18)
            ..lineTo(20, 6),
          paint,
        );
        break;
      case OriginalIconType.tasks:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(3.5, 3.5, 17, 17),
            const Radius.circular(5),
          ),
          paint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(9, 11.5)
            ..lineTo(11.5, 14)
            ..lineTo(17, 8),
          paint,
        );
        break;
      case OriginalIconType.wallet:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(3, 6, 18, 13),
            const Radius.circular(4),
          ),
          paint,
        );
        canvas.drawLine(const Offset(3, 10), const Offset(21, 10), paint);
        canvas.drawLine(const Offset(16, 15), const Offset(18, 15), paint);
        break;
      case OriginalIconType.sun:
        canvas.drawCircle(const Offset(12, 12), 4.4, paint);
        for (final segment in const <(Offset, Offset)>[
          (Offset(12, 2.5), Offset(12, 4.9)),
          (Offset(12, 19.1), Offset(12, 21.5)),
          (Offset(2.5, 12), Offset(4.9, 12)),
          (Offset(19.1, 12), Offset(21.5, 12)),
          (Offset(5, 5), Offset(6.7, 6.7)),
          (Offset(17.3, 17.3), Offset(19, 19)),
          (Offset(19, 5), Offset(17.3, 6.7)),
          (Offset(6.7, 17.3), Offset(5, 19)),
        ]) {
          canvas.drawLine(segment.$1, segment.$2, paint);
        }
        break;
      case OriginalIconType.moon:
        final moon = Path()
          ..moveTo(20.5, 14.5)
          ..cubicTo(15.3, 16.6, 8.1, 11.9, 9.5, 3.5)
          ..cubicTo(4.3, 4.6, 1.1, 9.8, 2.5, 15)
          ..cubicTo(4, 20.6, 10.4, 23.2, 15.6, 20.5)
          ..cubicTo(18.1, 19.2, 19.8, 17.1, 20.5, 14.5)
          ..close();
        canvas.drawPath(moon, paint);
        break;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OriginalIconPainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
