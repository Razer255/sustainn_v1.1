import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/action_point_model.dart';
import '../../models/activity_model.dart';
import '../../services/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/action_point_tile.dart';
import '../../widgets/activity_timeline_tile.dart';
import '../../widgets/summary_card.dart';

/// Crop Summary screen — detailed view of a single crop.
/// Shows: health summary, activities timeline, financial data, and action points.
class CropSummaryScreen extends StatelessWidget {
  final String cropId;

  const CropSummaryScreen({super.key, required this.cropId});

  @override
  Widget build(BuildContext context) {
    final crop = MockData.crops.firstWhere((c) => c.id == cropId);
    final activities = MockData.getActivitiesForCrop(cropId);
    final financials = MockData.getFinancialsForCrop(cropId);
    final actionPoints = MockData.getActionPointsForScope(
      ActionScope.crop,
      cropId,
    );
    final totalInputCost = MockData.getTotalInputCostForCrop(cropId);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.headerGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(56, 10, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            // Crop emoji
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Center(
                                child:
                                    Text('🌾', style: TextStyle(fontSize: 28)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    crop.cropName,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${crop.variety} • ${crop.season}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.85),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Status chips row
                        Row(
                          children: [
                            _HeaderChip(
                              icon: Icons.calendar_today,
                              text: '${crop.daysSinceSowing}d since sowing',
                            ),
                            const SizedBox(width: 8),
                            if (crop.daysToHarvest > 0)
                              _HeaderChip(
                                icon: Icons.timer_outlined,
                                text: '${crop.daysToHarvest}d to harvest',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Crop Health Summary ──
                  _buildSectionTitle('Health Summary'),
                  const SizedBox(height: 12),
                  _CropHealthCard(crop: crop),

                  const SizedBox(height: 24),

                  // ── Financial Data ──
                  _buildSectionTitle('Financial Overview'),
                  const SizedBox(height: 12),
                  _FinancialCard(
                    totalInputCost: totalInputCost,
                    financials: financials,
                  ),

                  const SizedBox(height: 24),

                  // ── Activities Timeline ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('Activities'),
                      TextButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/add-activity',
                          arguments: cropId,
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Log Activity'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (activities.isNotEmpty)
                    ...activities.asMap().entries.map((entry) {
                      return ActivityTimelineTile(
                        activity: entry.value,
                        isFirst: entry.key == 0,
                        isLast: entry.key == activities.length - 1,
                      );
                    })
                  else
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.history,
                              size: 40, color: AppColors.textHint),
                          SizedBox(height: 8),
                          Text(
                            'No activities logged yet',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // ── Action Points ──
                  if (actionPoints.isNotEmpty) ...[
                    _buildSectionTitle('Action Points'),
                    const SizedBox(height: 12),
                    ...actionPoints.map((ap) => ActionPointTile(
                          actionPoint: ap,
                          onResolve: () {},
                        )),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.pushNamed(context, '/add-activity', arguments: cropId),
        icon: const Icon(Icons.add),
        label: const Text('Log Activity'),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

/// A chip used in the header area.
class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeaderChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Health summary card for the crop.
class _CropHealthCard extends StatelessWidget {
  final dynamic crop;

  const _CropHealthCard({required this.crop});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(crop.healthStatus);
    final statusLabel = _getStatusLabel(crop.healthStatus);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Health indicator
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getStatusIcon(crop.healthStatus),
                  size: 28,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _getStatusDescription(crop.healthStatus),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Quick stats
          SummaryStatRow(stats: [
            SummaryStat(
              value: '${crop.daysSinceSowing}',
              label: 'Days Old',
            ),
            SummaryStat(
              value: '${crop.activityCount}',
              label: 'Activities',
              color: AppColors.primary,
            ),
            SummaryStat(
              value: crop.status.value.toUpperCase(),
              label: 'Status',
              color: AppColors.primary,
            ),
          ]),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
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

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'good':
        return 'Healthy Growth 🌿';
      case 'moderate':
        return 'Needs Attention ⚠️';
      case 'poor':
        return 'At Risk 🚨';
      default:
        return 'Unknown';
    }
  }

  String _getStatusDescription(String? status) {
    switch (status) {
      case 'good':
        return 'Crop is growing well. Continue current practices.';
      case 'moderate':
        return 'Some issues detected. Review action points below.';
      case 'poor':
        return 'Immediate attention needed. Check recommendations.';
      default:
        return '';
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'good':
        return Icons.check_circle;
      case 'moderate':
        return Icons.warning_amber;
      case 'poor':
        return Icons.error;
      default:
        return Icons.help_outline;
    }
  }
}

/// Financial overview card.
class _FinancialCard extends StatelessWidget {
  final double totalInputCost;
  final dynamic financials;

  const _FinancialCard({
    required this.totalInputCost,
    required this.financials,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,##0');
    final expectedRevenue = financials?.expectedRevenue ?? 0.0;
    final expectedProfit = expectedRevenue - totalInputCost;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          // Financial stats
          Row(
            children: [
              Expanded(
                child: _FinStat(
                  label: 'Input Cost',
                  value: '₹${numberFormat.format(totalInputCost)}',
                  icon: Icons.arrow_downward,
                  iconColor: AppColors.danger,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: AppColors.divider,
              ),
              Expanded(
                child: _FinStat(
                  label: 'Expected Revenue',
                  value: '₹${numberFormat.format(expectedRevenue)}',
                  icon: Icons.arrow_upward,
                  iconColor: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Profit/Loss
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                expectedProfit >= 0 ? Icons.trending_up : Icons.trending_down,
                color: expectedProfit >= 0 ? AppColors.primary : AppColors.danger,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Expected Profit: ₹${numberFormat.format(expectedProfit)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color:
                      expectedProfit >= 0 ? AppColors.primary : AppColors.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _FinStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
