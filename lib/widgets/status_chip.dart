import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A colored chip indicating health status: good (green), moderate (yellow), poor (red).
class StatusChip extends StatelessWidget {
  final String status; // 'good', 'moderate', 'poor'
  final double size;

  const StatusChip({
    super.key,
    required this.status,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _statusColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: _statusColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _statusColor.withOpacity(0.4),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Color get _statusColor {
    switch (status) {
      case 'good':
        return AppColors.healthGood;
      case 'moderate':
        return AppColors.healthModerate;
      case 'poor':
        return AppColors.healthPoor;
      default:
        return AppColors.textSecondary;
    }
  }

  Color get _backgroundColor {
    switch (status) {
      case 'good':
        return AppColors.successLight;
      case 'moderate':
        return AppColors.warningLight;
      case 'poor':
        return AppColors.dangerLight;
      default:
        return AppColors.surfaceVariant;
    }
  }

  String get _label {
    switch (status) {
      case 'good':
        return 'Healthy';
      case 'moderate':
        return 'Moderate';
      case 'poor':
        return 'Needs Attention';
      default:
        return 'Unknown';
    }
  }
}
