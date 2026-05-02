import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Status pill badge with preset colors for safe/warning/alert.
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusType type;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.label,
    this.type = StatusType.safe,
    this.fontSize = 10,
  });

  Color get _color {
    switch (type) {
      case StatusType.safe:
        return AppColors.safe;
      case StatusType.warning:
        return AppColors.warning;
      case StatusType.alert:
        return AppColors.danger;
      case StatusType.info:
        return AppColors.blueFg;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: _color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

enum StatusType { safe, warning, alert, info }
