import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class ScanOverlayPainter extends CustomPainter {
  final double animationValue; // 0.0 – 1.0 for corner pulse

  const ScanOverlayPainter({this.animationValue = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final maskPaint = Paint()..color = AppColors.scanMask;
    const frameSize = AppDimensions.scannerFrameSize;
    final left = (size.width - frameSize) / 2;
    final top = (size.height - frameSize) / 2;
    final rect = Rect.fromLTWH(left, top, frameSize, frameSize);

    // Draw dark mask around the frame
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, maskPaint);

    // Draw corner brackets
    final bracketPaint = Paint()
      ..color = AppColors.scanBracket
          .withValues(alpha: 0.6 + 0.4 * animationValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppDimensions.scannerCornerWidth
      ..strokeCap = StrokeCap.round;

    const cl = AppDimensions.scannerCornerLength;
    const r = 12.0;

    // Top-left
    canvas.drawPath(
        Path()
          ..moveTo(left, top + cl)
          ..lineTo(left, top + r)
          ..quadraticBezierTo(left, top, left + r, top)
          ..lineTo(left + cl, top),
        bracketPaint);
    // Top-right
    canvas.drawPath(
        Path()
          ..moveTo(left + frameSize - cl, top)
          ..lineTo(left + frameSize - r, top)
          ..quadraticBezierTo(
              left + frameSize, top, left + frameSize, top + r)
          ..lineTo(left + frameSize, top + cl),
        bracketPaint);
    // Bottom-left
    canvas.drawPath(
        Path()
          ..moveTo(left, top + frameSize - cl)
          ..lineTo(left, top + frameSize - r)
          ..quadraticBezierTo(
              left, top + frameSize, left + r, top + frameSize)
          ..lineTo(left + cl, top + frameSize),
        bracketPaint);
    // Bottom-right
    canvas.drawPath(
        Path()
          ..moveTo(left + frameSize - cl, top + frameSize)
          ..lineTo(left + frameSize - r, top + frameSize)
          ..quadraticBezierTo(left + frameSize, top + frameSize,
              left + frameSize, top + frameSize - r)
          ..lineTo(left + frameSize, top + frameSize - cl),
        bracketPaint);
  }

  @override
  bool shouldRepaint(ScanOverlayPainter old) =>
      old.animationValue != animationValue;
}
