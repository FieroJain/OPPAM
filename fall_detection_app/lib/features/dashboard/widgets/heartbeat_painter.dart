import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Custom painter for the animated heartbeat line.
class HeartbeatPainter extends CustomPainter {
  final double animationValue;

  HeartbeatPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final w = size.width;
    final h = size.height;
    final mid = h / 2;

    path.moveTo(0, mid);

    // Flat line
    path.lineTo(w * 0.2, mid);

    // Heartbeat spike
    path.lineTo(w * 0.25, mid - h * 0.1);
    path.lineTo(w * 0.28, mid);
    path.lineTo(w * 0.30, mid - h * 0.6);
    path.lineTo(w * 0.33, mid + h * 0.35);
    path.lineTo(w * 0.36, mid);

    // Another smaller spike
    path.lineTo(w * 0.40, mid - h * 0.15);
    path.lineTo(w * 0.43, mid);

    // Flat to end
    path.lineTo(w, mid);

    // Clip to animated position
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(0, 0, w * animationValue, h),
    );
    canvas.drawPath(path, paint);
    canvas.restore();

    // Gradient fade on the right
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          AppColors.backgroundDark,
        ],
      ).createShader(
        Rect.fromLTWH(w * 0.8, 0, w * 0.2, h),
      );
    canvas.drawRect(Rect.fromLTWH(w * 0.8, 0, w * 0.2, h), gradientPaint);
  }

  @override
  bool shouldRepaint(covariant HeartbeatPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
