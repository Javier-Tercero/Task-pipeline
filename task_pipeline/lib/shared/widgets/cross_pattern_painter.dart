import 'package:flutter/material.dart';

/// Paints a blueprint-style grid: small "+" crosses on a square grid, every
/// [_majorEvery]th row and column marked with a large cross, and faint lines
/// running through those major points.
class CrossPatternPainter extends CustomPainter {
  CrossPatternPainter({required this.color});

  final Color color;

  static const double _step = 48; // distance between grid points, both axes
  static const int _majorEvery = 4; // a major point every 4 steps (192)

  // Small crosses at every grid point.
  static const double _minorArm = 3; // half the length of each stroke
  static const double _minorStroke = 1;
  static const double _minorOpacity = 0.35;

  // Large crosses at the major points.
  static const double _majorArm = 10;
  static const double _majorStroke = 1.5;
  static const double _majorOpacity = 0.6;

  // Lines through the major points, drawn under the crosses.
  static const double _lineStroke = 1;
  static const double _lineOpacity = 0.12;

  @override
  void paint(Canvas canvas, Size size) {
    Paint pen(double stroke, double opacity) => Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.square;

    final minor = pen(_minorStroke, _minorOpacity);
    final major = pen(_majorStroke, _majorOpacity);
    final line = pen(_lineStroke, _lineOpacity);

    // Grid points sit half a step in from the top-left, then every step, so
    // no cross is cut in half by the edge. Both axes use the same spacing,
    // which is what keeps every cross aligned with its row and its column.
    List<double> positions(double length) => [
      for (var p = _step / 2; p < length + _majorArm; p += _step) p,
    ];
    final xs = positions(size.width);
    final ys = positions(size.height);

    // A point is major when its index is 3, 7, 11... (the 4th, 8th, 12th
    // point), so the first major line isn't hugging the edge.
    bool isMajor(int index) => index % _majorEvery == _majorEvery - 1;

    // 1. Faint lines through the major columns and rows.
    for (var i = 0; i < xs.length; i++) {
      if (isMajor(i)) {
        canvas.drawLine(Offset(xs[i], 0), Offset(xs[i], size.height), line);
      }
    }
    for (var j = 0; j < ys.length; j++) {
      if (isMajor(j)) {
        canvas.drawLine(Offset(0, ys[j]), Offset(size.width, ys[j]), line);
      }
    }

    // 2. A cross at every grid point: large where both its row and its column
    //    are major, small everywhere else.
    for (var j = 0; j < ys.length; j++) {
      for (var i = 0; i < xs.length; i++) {
        final isBig = isMajor(i) && isMajor(j);
        _drawCross(
          canvas,
          Offset(xs[i], ys[j]),
          isBig ? _majorArm : _minorArm,
          isBig ? major : minor,
        );
      }
    }
  }

  void _drawCross(Canvas canvas, Offset center, double arm, Paint paint) {
    canvas.drawLine(center.translate(-arm, 0), center.translate(arm, 0), paint);
    canvas.drawLine(center.translate(0, -arm), center.translate(0, arm), paint);
  }

  // The pattern only changes if the color does, so it's drawn once and reused.
  @override
  bool shouldRepaint(CrossPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}
