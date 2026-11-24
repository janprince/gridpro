import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Concentric, broken arcs anchored in a corner of a card — the quiet
/// signature on service cards. Purely decorative.
class CornerArcs extends StatelessWidget {
  const CornerArcs({
    super.key,
    required this.color,
    this.size = 150,
    this.alignment = Alignment.bottomRight,
  });

  final Color color;
  final double size;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: IgnorePointer(
      child: ExcludeSemantics(
        child: Align(
          alignment: alignment,
          child: SizedBox.square(
            dimension: size,
            child: CustomPaint(
              painter: _ArcsPainter(color: color, alignment: alignment),
            ),
          ),
        ),
      ),
    ),
  );
}

class _ArcsPainter extends CustomPainter {
  _ArcsPainter({required this.color, required this.alignment});
  final Color color;
  final Alignment alignment;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round;
    // The centre sits just outside the corner so only the arcs' inner sweep
    // shows, like a thumbprint pressed into the card's edge.
    final centre = Offset(
      size.width * (0.5 + alignment.x * 0.55),
      size.height * (0.5 + alignment.y * 0.55),
    );
    final start = math.atan2(-alignment.y, -alignment.x) - math.pi / 2;
    const gaps = [
      [0.0, 1.0],
      [0.0, 0.42, 0.55, 1.0],
      [0.0, 0.18, 0.3, 0.7, 0.8, 1.0],
      [0.0, 0.5, 0.62, 1.0],
    ];
    for (var ring = 0; ring < gaps.length; ring++) {
      final radius = size.width * (0.18 + ring * 0.2);
      final rect = Rect.fromCircle(center: centre, radius: radius);
      final segments = gaps[ring];
      for (var i = 0; i < segments.length; i += 2) {
        canvas.drawArc(
          rect,
          start + segments[i] * math.pi,
          (segments[i + 1] - segments[i]) * math.pi,
          false,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ArcsPainter old) =>
      old.color != color || old.alignment != alignment;
}

/// A fine grid with a few filled cells, fading towards the bottom-left.
/// Used on navy surfaces — the GRID name, drawn.
class GridTexture extends StatelessWidget {
  const GridTexture({super.key, this.opacity = 1, this.cell = 26});
  final double opacity;
  final double cell;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: IgnorePointer(
      child: ExcludeSemantics(
        child: CustomPaint(
          painter: _GridPainter(opacity: opacity, cell: cell),
        ),
      ),
    ),
  );
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.opacity, required this.cell});
  final double opacity;
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    Shader fade(double alpha) => LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        Colors.white.withValues(alpha: alpha * opacity),
        Colors.white.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.8],
    ).createShader(Offset.zero & size);
    final line = Paint()
      ..shader = fade(0.08)
      ..strokeWidth = 1;
    for (var x = size.width; x > 0; x -= cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (var y = 0.0; y < size.height; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    final fill = Paint()..shader = fade(0.07);
    // A few lit cells near the top-right corner, stepping down diagonally.
    const lit = [(0, 1), (1, 2), (2, 0), (3, 3)];
    for (final (col, row) in lit) {
      final rect = Rect.fromLTWH(
        size.width - (col + 1) * cell + 3,
        row * cell + 3,
        cell - 6,
        cell - 6,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) =>
      old.opacity != opacity || old.cell != cell;
}
