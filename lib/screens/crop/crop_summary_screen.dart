import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/action_point_model.dart';
import '../../models/activity_model.dart';
import '../../services/api_service.dart';
import '../../services/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/action_point_tile.dart';
import '../../widgets/activity_timeline_tile.dart';
import '../../widgets/summary_card.dart';
import '../field/add_crop_screen.dart';
import 'add_activity_screen.dart';

/// Crop Summary screen — detailed view of a single crop.
/// Shows: health summary, activities timeline, financial data, and action points.
class CropSummaryScreen extends StatefulWidget {
  final String cropId;

  const CropSummaryScreen({super.key, required this.cropId});

  @override
  State<CropSummaryScreen> createState() => _CropSummaryScreenState();
}

class _CropSummaryScreenState extends State<CropSummaryScreen> {
  String get cropId => widget.cropId;

  Future<void> _resolveActionPoint(dynamic actionPoint) async {
    try {
      await ApiService().resolveActionPoint(actionPoint.id);
      MockData.actionPoints.removeWhere((ap) => ap.id == actionPoint.id);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Action point resolved ✓'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not resolve: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _editCrop() async {
    final crop = MockData.crops.firstWhere((c) => c.id == cropId);
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddCropScreen(fieldId: crop.fieldId, existingCrop: crop),
      ),
    );
    if (updated == true && mounted) setState(() {});
  }

  Future<void> _deleteCrop() async {
    final crop = MockData.crops.firstWhere((c) => c.id == cropId);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete crop?'),
        content: Text(
          'This will permanently delete "${crop.cropName}" (${crop.variety}). '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ApiService().deleteCrop(crop.id);
      MockData.crops.removeWhere((c) => c.id == crop.id);

      final fieldIndex = MockData.fields.indexWhere((f) => f.id == crop.fieldId);
      if (fieldIndex != -1) {
        final f = MockData.fields[fieldIndex];
        MockData.fields[fieldIndex] =
            f.copyWith(activeCrops: (f.activeCrops - 1).clamp(0, 1 << 30));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Crop deleted'), backgroundColor: AppColors.primary),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete crop: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _editActivity(ActivityModel activity) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddActivityScreen(cropId: cropId, existingActivity: activity),
      ),
    );
    if (updated == true && mounted) setState(() {});
  }

  Future<void> _deleteActivity(ActivityModel activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete activity?'),
        content: Text('This will remove "${activity.displayLabel}" logged on '
            '${DateFormat('dd MMM yyyy').format(activity.date)}. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ApiService().deleteActivity(activity.id);

      MockData.activities.removeWhere((a) => a.id == activity.id);

      final cropIndex = MockData.crops.indexWhere((c) => c.id == cropId);
      if (cropIndex != -1) {
        final c = MockData.crops[cropIndex];
        MockData.crops[cropIndex] =
            c.copyWith(activityCount: (c.activityCount - 1).clamp(0, 1 << 30));
      }

      if (activity.cost != null && activity.cost! > 0) {
        final finIndex = MockData.financials.indexWhere((f) => f.cropId == cropId);
        if (finIndex != -1) {
          final f = MockData.financials[finIndex];
          MockData.financials[finIndex] = f.copyWith(
            inputCost: f.inputCost - activity.cost!,
            updatedAt: DateTime.now(),
          );
        }
      }

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activity deleted'), backgroundColor: AppColors.primary),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete activity: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cropIndex = MockData.crops.indexWhere((c) => c.id == cropId);
    if (cropIndex == -1) {
      // Reached via a stale card (e.g. the crop was deleted from another
      // screen) — back out instead of crashing on firstWhere.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context, true);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final crop = MockData.crops[cropIndex];
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
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                tooltip: 'Edit crop',
                onPressed: _editCrop,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                tooltip: 'Delete crop',
                onPressed: _deleteCrop,
              ),
            ],
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
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _HeaderChip(
                              icon: Icons.calendar_today,
                              text: '${crop.daysSinceSowing}d since sowing',
                            ),
                            if (crop.daysToHarvest > 0)
                              _HeaderChip(
                                icon: Icons.timer_outlined,
                                text: '${crop.daysToHarvest}d to harvest',
                              ),
                            if (crop.isIntercrop)
                              const _HeaderChip(
                                icon: Icons.grass,
                                text: 'Intercrop',
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
                  // ── Crop Details ──
                  _buildSectionTitle('Crop Details'),
                  const SizedBox(height: 12),
                  _CropDetailsCard(crop: crop),

                  const SizedBox(height: 24),

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
                        onPressed: () async {
                          final added = await Navigator.pushNamed(
                            context,
                            '/add-activity',
                            arguments: cropId,
                          );
                          if (added == true && mounted) setState(() {});
                        },
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
                        onEdit: () => _editActivity(entry.value),
                        onDelete: () => _deleteActivity(entry.value),
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
                          onResolve: () => _resolveActionPoint(ap),
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
        onPressed: () async {
          final added = await Navigator.pushNamed(context, '/add-activity', arguments: cropId);
          if (added == true && mounted) setState(() {});
        },
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

/// Plain attribute listing for the crop — name, variety, season, dates,
/// area covered and intercrop status.
class _CropDetailsCard extends StatelessWidget {
  final dynamic crop; // CropModel

  const _CropDetailsCard({required this.crop});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          _DetailRow(label: 'Crop', value: crop.cropName),
          _DetailRow(label: 'Variety', value: crop.variety),
          _DetailRow(label: 'Season', value: crop.season),
          _DetailRow(label: 'Sown Date', value: dateFormat.format(crop.sownDate)),
          _DetailRow(
            label: 'Expected Harvest',
            value: crop.expectedHarvestDate != null
                ? dateFormat.format(crop.expectedHarvestDate)
                : 'Not set',
          ),
          _DetailRow(
            label: 'Area Covered',
            value: '${(crop.areaCovered as double).toStringAsFixed(1)} acres',
          ),
          _DetailRow(
            label: 'Intercrop',
            value: crop.isIntercrop ? 'Yes' : 'No',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
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
