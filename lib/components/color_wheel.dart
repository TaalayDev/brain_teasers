import 'dart:math';
import 'package:flutter/material.dart';

class ColorWheel extends StatefulWidget {
  final double size;
  final ValueChanged<Color>? onColorSelected;

  const ColorWheel({
    super.key,
    this.size = 200,
    this.onColorSelected,
  });

  @override
  State<ColorWheel> createState() => _ColorWheelState();
}

class _ColorWheelState extends State<ColorWheel> {
  Color _selectedColor = Colors.red;
  Offset? _currentPosition;

  void _updateColor(Offset localPosition) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final delta = localPosition - center;
    final radius = widget.size / 2;

    // Calculate distance from center
    final distance = delta.distance;
    if (distance > radius) return;

    // Calculate angle
    final angle = atan2(delta.dy, delta.dx);
    final hue = ((angle / pi) * 180) % 360;

    // Calculate saturation based on distance from center
    final saturation = distance / radius;

    final color = HSVColor.fromAHSV(1.0, hue, saturation, 1.0).toColor();

    setState(() {
      _selectedColor = color;
      _currentPosition = localPosition;
    });

    widget.onColorSelected?.call(color);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: (details) => _updateColor(details.localPosition),
      onPanUpdate: (details) => _updateColor(details.localPosition),
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _ColorWheelPainter(
          selectedPosition: _currentPosition,
          selectedColor: _selectedColor,
        ),
      ),
    );
  }
}

class _ColorWheelPainter extends CustomPainter {
  final Offset? selectedPosition;
  final Color selectedColor;

  _ColorWheelPainter({
    this.selectedPosition,
    required this.selectedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw filled color wheel
    for (double angle = 0; angle < 360; angle += 1) {
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.5,
          colors: [
            Colors.white,
            HSVColor.fromAHSV(1.0, angle, 1.0, 1.0).toColor(),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          (angle - 0.5) * pi / 180,
          1.0 * pi / 180,
          false,
        )
        ..close();

      canvas.drawPath(path, paint);
    }

    // Draw border
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.grey
        ..strokeWidth = 1,
    );

    // Draw selected position indicator
    if (selectedPosition != null) {
      final paint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(selectedPosition!, 10, paint);
      canvas.drawCircle(
        selectedPosition!,
        8,
        Paint()..color = selectedColor,
      );
    }
  }

  @override
  bool shouldRepaint(_ColorWheelPainter oldDelegate) {
    return oldDelegate.selectedPosition != selectedPosition ||
        oldDelegate.selectedColor != selectedColor;
  }
}
