import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class CoinIllustration extends StatelessWidget {
  final double size;
  const CoinIllustration({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CoinPainter()),
    );
  }
}

class _CoinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.42;

    // Outer coin
    final outerPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFD54F), Color(0xFFFFA726)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawCircle(Offset(cx, cy), r, outerPaint);

    // Inner ring
    final ringPaint = Paint()
      ..color = const Color(0xFFFFE082)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(cx, cy), r * 0.75, ringPaint);

    // Dollar sign
    final textPainter = TextPainter(
      text: TextSpan(
        text: '\$',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: size.width * 0.35,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
    );

    // Small growth arrow
    final arrowPaint = Paint()
      ..color = AppColors.progress
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final arrowPath = Path()
      ..moveTo(cx + r * 0.3, cy + r * 0.5)
      ..lineTo(cx + r * 0.6, cy - r * 0.1)
      ..lineTo(cx + r * 0.9, cy + r * 0.2);
    canvas.drawPath(arrowPath, arrowPaint);

    // Arrow head
    final headPaint = Paint()..color = AppColors.progress;
    final headPath = Path()
      ..moveTo(cx + r * 0.9, cy + r * 0.2)
      ..lineTo(cx + r * 0.75, cy + r * 0.05)
      ..lineTo(cx + r * 0.85, cy + r * 0.35)
      ..close();
    canvas.drawPath(headPath, headPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
