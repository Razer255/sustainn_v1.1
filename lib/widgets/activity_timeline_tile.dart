import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/activity_model.dart';
import '../theme/app_colors.dart';

/// A timeline tile for displaying a farming activity entry.
class ActivityTimelineTile extends StatelessWidget {
  final ActivityModel activity;
  final bool isFirst;
  final bool isLast;

  const ActivityTimelineTile({
    super.key,
    required this.activity,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline line + dot
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Top line
                if (!isFirst)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.border,
                    ),
                  )
                else
                  const Expanded(child: SizedBox()),

                // Dot
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _typeColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _typeColor.withOpacity(0.3),
                      width: 3,
                    ),
                  ),
                ),

                // Bottom line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.border,
                    ),
                  )
                else
                  const Expanded(child: SizedBox()),
              ],
            ),
          ),

          // Content card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12, left: 4),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.border.withOpacity(0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: type + date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Activity type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _typeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              activity.type.emoji,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              activity.type.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _typeColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Date
                      Text(
                        DateFormat('dd MMM yyyy').format(activity.date),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Notes
                  if (activity.notes.isNotEmpty)
                    Text(
                      activity.notes,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),

                  // Cost + Quantity row
                  if (activity.cost != null || activity.quantity != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (activity.cost != null) ...[
                          const Icon(Icons.currency_rupee,
                              size: 13, color: AppColors.textSecondary),
                          Text(
                            NumberFormat('#,##0').format(activity.cost),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (activity.cost != null && activity.quantity != null)
                          const SizedBox(width: 16),
                        if (activity.quantity != null) ...[
                          Icon(
                            _quantityIcon,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${NumberFormat('#,##0').format(activity.quantity)} ${activity.unit ?? ''}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color get _typeColor {
    switch (activity.type) {
      case ActivityType.irrigation:
        return Colors.blue;
      case ActivityType.fertilizer:
        return AppColors.primary;
      case ActivityType.pesticide:
        return Colors.orange;
      case ActivityType.harvest:
        return Colors.amber.shade700;
      case ActivityType.sowing:
        return Colors.teal;
      case ActivityType.weeding:
        return Colors.green.shade700;
      case ActivityType.soilTesting:
        return Colors.purple;
      case ActivityType.other:
        return AppColors.textSecondary;
    }
  }

  IconData get _quantityIcon {
    switch (activity.type) {
      case ActivityType.irrigation:
        return Icons.water_drop_outlined;
      case ActivityType.fertilizer:
        return Icons.science_outlined;
      case ActivityType.pesticide:
        return Icons.science_outlined;
      default:
        return Icons.straighten;
    }
  }
}
