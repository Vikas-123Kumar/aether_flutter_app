import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
class ThermostatDial extends StatelessWidget {
  final String temperature;
  final Color solidColor;
  final List<Color> gradientColors;

  const ThermostatDial({
    super.key,
    required this.temperature,
    required this.solidColor,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: CustomPaint(
        painter: ThermostatPainter(temperature, solidColor, gradientColors),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "MAINTAINING",
                style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 3),
              ),
              const SizedBox(height: 10),
              // Optional: You can use a ShaderMask here if you want the text itself to be a gradient
              // For now, we use the solid bright color so it stays readable
              Text(
                "${temperature}°C",
                style: TextStyle(color: solidColor, fontSize: 54, fontWeight: FontWeight.bold,),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class ThermostatPainter extends CustomPainter {
  final String value;
  final Color solidColor;
  final List<Color> gradientColors;

  ThermostatPainter(this.value, this.solidColor, this.gradientColors);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 25;

    // 1. Draw the Dark Background Circle
    final bgCircle = Paint()
      ..color = const Color(0xff09182F)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 20, bgCircle);

    // 2. Draw the Grey Background Track
    final trackPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // The track starts at 2.5 radians and sweeps for 4.6 radians
    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius), 2.5, 4.6, false, trackPaint);

    double numericTemp = double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    double sweep = (numericTemp / 100) * 4.6;

    // 3. Setup the Glow Paint
    final glowPaint = Paint()
      ..color = gradientColors.isNotEmpty ? gradientColors.first.withOpacity(0.4) : solidColor.withOpacity(0.4)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    // 4. THE FIX: Setup SweepGradient
    // SweepGradient perfectly follows the curve of the circular arc
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 2.5, // Matches the start of your arc
        endAngle: 2.5 + 4.6, // Matches the end of your arc track
        colors: gradientColors.length >= 2 ? gradientColors : [solidColor, solidColor],
        // Transform rotates the sweep to start at the right position
        transform: GradientRotation(0),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 5. Draw the Colored Arcs
    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius), 2.5, sweep, false, glowPaint);
    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius), 2.5, sweep, false, progressPaint);

    // 6. Draw the Tick Marks
    for (int i = 0; i < 22; i++) {
      double angle = -0.3 + (i * 0.12);
      final p1 = Offset(
        center.dx + (radius + 10) * cos(angle),
        center.dy + (radius + 10) * sin(angle),
      );
      final p2 = Offset(
        center.dx + (radius + 18) * cos(angle),
        center.dy + (radius + 18) * sin(angle),
      );
      canvas.drawLine(p1, p2, Paint()..color = Colors.white24..strokeWidth = 2);
    }

    // 7. Draw the White Knob
    final knobAngle = 2.5 + sweep;
    final knob = Offset(
      center.dx + radius * cos(knobAngle),
      center.dy + radius * sin(knobAngle),
    );
    canvas.drawCircle(knob, 12, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}