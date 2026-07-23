import 'package:flutter/material.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';

class GridMark extends StatelessWidget {
  const GridMark({super.key, this.light = false, this.compact = false});
  final bool light;
  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: compact ? 30 : 42,
        height: compact ? 30 : 42,
        decoration: BoxDecoration(
          color: light ? Colors.white : AppColors.forest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.grid_view_rounded,
          color: light ? AppColors.forest : Colors.white,
          size: compact ? 18 : 24,
        ),
      ),
      const SizedBox(width: 10),
      Text(
        'GRID',
        style: TextStyle(
          fontSize: compact ? 18 : 24,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: light ? Colors.white : AppColors.ink,
        ),
      ),
      const SizedBox(width: 5),
      Text(
        'PRO',
        style: TextStyle(
          fontSize: compact ? 10 : 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
          color: light ? AppColors.mint : AppColors.teal,
        ),
      ),
    ],
  );
}
