import 'dart:math';
import 'package:flutter/material.dart';

class ThermostatDial extends StatelessWidget {
  final String temperature;

  const ThermostatDial({
    super.key,
    required this.temperature,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: CustomPaint(
        painter: ThermostatPainter(temperature),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "MAINTAINING",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  letterSpacing: 3,
                ),
              ),

              const SizedBox(height: 10),
              Text(
                "${temperature}°C",
                style: const TextStyle(
                  color: Color(0xff4FD1FF),
                  fontSize: 54,
                  fontWeight: FontWeight.w300,
                ),
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

  ThermostatPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius = size.width / 2 - 25;

    final bgCircle = Paint()
      ..color = const Color(0xff09182F)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius - 20, bgCircle);

    final trackPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.5,
      4.6,
      false,
      trackPaint,
    );

    final glowPaint = Paint()
      ..color = const Color(0xff53D6FF)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter =
      const MaskFilter.blur(BlurStyle.normal, 12);

    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xff7AE8FF),
          Color(0xff22AFFF),
        ],
      ).createShader(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
      )
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double sweep = double.parse(value) / 100 * 4.6;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.5,
      sweep,
      false,
      glowPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.5,
      sweep,
      false,
      progressPaint,
    );

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

      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = Colors.white24
          ..strokeWidth = 2,
      );
    }

    final knobAngle = 2.5 + sweep;

    final knob = Offset(
      center.dx + radius * cos(knobAngle),
      center.dy + radius * sin(knobAngle),
    );

    canvas.drawCircle(
      knob,
      12,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      true;
}