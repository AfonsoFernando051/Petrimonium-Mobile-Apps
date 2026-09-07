import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Contorno tracejado com cantos arredondados.
///
/// O Flutter não desenha tracejado em `Border`/`OutlinedButton`: o
/// `BorderSide` só tem estilo sólido. Os artboards `Settings*` do canvas
/// distinguem assim a acção destrutiva ("Excluir minha conta") do logout —
/// mesma cor de erro, mas tracejada e esbatida, para não se clicar por engano.
class DashedOutline extends StatelessWidget {
  const DashedOutline({
    super.key,
    required this.child,
    required this.color,
    this.radius = 12,
    this.strokeWidth = 1.5,
    this.dashLength = 5,
    this.gapLength = 4,
  });

  final Widget child;
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRoundedRectPainter(
        color: color,
        radius: radius,
        strokeWidth: strokeWidth,
        dashLength: dashLength,
        gapLength: gapLength,
      ),
      child: child,
    );
  }
}

class _DashedRoundedRectPainter extends CustomPainter {
  const _DashedRoundedRectPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // O traço é centrado no caminho, por isso encolhe-se meia espessura para
    // o contorno não sair fora da caixa.
    final inset = strokeWidth / 2;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(inset, inset, size.width - strokeWidth, size.height - strokeWidth),
          Radius.circular(radius),
        ),
      );

    for (final ui.PathMetric metric in outline.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashLength;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0.0, metric.length)),
          paint,
        );
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRoundedRectPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth ||
      old.dashLength != dashLength ||
      old.gapLength != gapLength;
}
