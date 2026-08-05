import 'package:flutter/material.dart';
import '../models/action_point_model.dart';
import '../theme/app_colors.dart';

/// A list tile for displaying an action point with priority indicator,
/// due date, and resolve action.
class ActionPointTile extends StatelessWidget {
  final ActionPointModel actionPoint;
  final VoidCallback? onResolve;
  final VoidCallback? onTap;

  const ActionPointTile({
    super.key,
    required this.actionPoint,
    this.onResolve,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = actionPoint.isOverdue;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isOverdue
              ? AppColors.dangerLight.withOpacity(0.5)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOverdue
                ? AppColors.danger.withOpacity(0.3)
                : AppColors.border.withOpacity(0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Priority indicator
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _priorityColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  _priorityIcon,
                  size: 18,
                  color: _priorityColor,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message
                  Text(
                    actionPoint.message,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      decoration: actionPoint.resolved
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Meta row: category + due date
                  Row(
                    children: [
                      if (actionPoint.category != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            actionPoint.category!.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      if (actionPoint.dueDate != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 12,
                              color: isOverdue
                                  ? AppColors.danger
                                  : AppColors.textHint,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _formatDueDate(actionPoint.dueDate!),
                              style: TextStyle(
                                fontSize: 11,
                                color: isOverdue
                                    ? AppColors.danger
                                    : AppColors.textHint,
                                fontWeight: isOverdue
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Resolve button
            if (!actionPoint.resolved && onResolve != null)
              IconButton(
                onPressed: onResolve,
                icon: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.primary,
                  size: 22,
                ),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.only(left: 8),
                tooltip: 'Mark as resolved',
              ),
          ],
        ),
      ),
    );
  }

  Color get _priorityColor {
    switch (actionPoint.priority) {
      case ActionPriority.high:
        return AppColors.danger;
      case ActionPriority.medium:
        return AppColors.warning;
      case ActionPriority.low:
        return AppColors.primary;
    }
  }

  IconData get _priorityIcon {
    switch (actionPoint.priority) {
      case ActionPriority.high:
        return Icons.warning_amber_rounded;
      case ActionPriority.medium:
        return Icons.info_outline;
      case ActionPriority.low:
        return Icons.lightbulb_outline;
    }
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;

    if (diff < 0) return '${-diff}d overdue';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return 'Due in ${diff}d';
  }
}
