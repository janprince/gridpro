import 'package:flutter/material.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';

/// The GRID Pro logo: a four-cell mark and the wordmark.
class GridMark extends StatelessWidget {
  const GridMark({super.key, this.light = false, this.compact = false});
  final bool light;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 22.0 : 28.0;
    final word = light ? Colors.white : AppColors.ink;
    return Semantics(
      label: 'GRID Pro',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GridGlyph(size: size, light: light),
          SizedBox(width: compact ? 8 : 10),
          Text(
            'GRID',
            style: TextStyle(
              fontSize: compact ? 17 : 21,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              height: 1,
              color: word,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: light ? AppColors.amber : AppColors.navy,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              'PRO',
              style: TextStyle(
                fontSize: compact ? 9.5 : 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                height: 1,
                color: light ? AppColors.navyDeep : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The four-cell mark on its own: three solid cells and one lit cell.
class GridGlyph extends StatelessWidget {
  const GridGlyph({super.key, this.size = 28, this.light = false});
  final double size;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final solid = light ? Colors.white : AppColors.navy;
    final gap = size * 0.12;
    final cell = (size - gap) / 2;
    Widget box(Color color) => Container(
      width: cell,
      height: cell,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(cell * 0.3),
      ),
    );
    return SizedBox.square(
      dimension: size,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [box(solid), box(solid)],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [box(solid), box(AppColors.amber)],
          ),
        ],
      ),
    );
  }
}
