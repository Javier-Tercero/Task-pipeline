import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A round floating button drawn like a poker chip: a disc in the theme's
/// primary color, a rim of evenly spaced light blocks, a thin inner ring, and
/// the icon in the middle.
class PokerChipButton extends StatelessWidget {
  const PokerChipButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 56,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  /// Diameter. 56 matches a regular floating action button, 40 a small one.
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        shape: const CircleBorder(),
        color: colors.primary,
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: CustomPaint(
            painter: _PokerChipPainter(markings: colors.onPrimary),
            child: SizedBox.square(
              dimension: size,
              child: Icon(icon, color: colors.onPrimary, size: size * 0.4),
            ),
          ),
        ),
      ),
    );
  }
}

class _PokerChipPainter extends CustomPainter {
  _PokerChipPainter({required this.markings});

  final Color markings;

  static const int _edgeSpots = 6; // light blocks around the rim
  static const double _rimFraction = 0.2; // rim width, as a share of the radius

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final rim = radius * _rimFraction;

    // 1. The patterned rim: short arcs as thick as the rim, one per spot,
    //    evenly spaced and each half as long as the gap it sits in.
    final spots = Paint()
      ..color = markings
      ..style = PaintingStyle.stroke
      ..strokeWidth = rim;
    final rimCircle = Rect.fromCircle(center: center, radius: radius - rim / 2);
    const step = 2 * math.pi / _edgeSpots;
    for (var i = 0; i < _edgeSpots; i++) {
      // Starts at the top (-pi/2), centred on each step.
      final start = -math.pi / 2 + i * step - step / 4;
      canvas.drawArc(rimCircle, start, step / 2, false, spots);
    }

    // 2. A thin ring just inside the rim, framing the icon.
    final ring = Paint()
      ..color = markings.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius - rim - 2, ring);
  }

  @override
  bool shouldRepaint(_PokerChipPainter oldDelegate) =>
      oldDelegate.markings != markings;
}
