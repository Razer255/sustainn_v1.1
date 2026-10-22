import 'package:flutter/material.dart';
import '../../models/action_point_model.dart';
import '../../services/api_service.dart';
import '../../services/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/action_point_tile.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/summary_card.dart';
import '../dashboard/add_field_screen.dart';

/// Field Summary screen — displays details of a single field.
/// Shows: season selector, crops list, field summary, and field-level action points.
class FieldSummaryScreen extends StatefulWidget {
  final String fieldId;

  const FieldSummaryScreen({super.key, required this.fieldId});

  @override
  State<FieldSummaryScreen> createState() => _FieldSummaryScreenState();
}

class _FieldSummaryScreenState extends State<FieldSummaryScreen> {
  String _selectedSeason = 'Kharif 2026';

  Future<void> _editField() async {
    final field = MockData.fields.firstWhere((f) => f.id == widget.fieldId);
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddFieldScreen(existingField: field)),
    );
    if (updated == true && mounted) setState(() {});
  }

  Future<void> _deleteField() async {
    final field = MockData.fields.firstWhere((f) => f.id == widget.fieldId);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete field?'),
        content: Text(
          'This will permanently delete "${field.name}". This cannot be undone.',
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
      await ApiService().deleteField(field.id);
      MockData.fields.removeWhere((f) => f.id == field.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Field deleted'), backgroundColor: AppColors.primary),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete field: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fieldIndex = MockData.fields.indexWhere((f) => f.id == widget.fieldId);
    if (fieldIndex == -1) {
      // Reached via a stale card (e.g. the field was deleted from another
      // screen) — back out instead of crashing on firstWhere.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context, true);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final field = MockData.fields[fieldIndex];

    // Field-wide totals (acres used, total cost) always reflect every
    // crop ever grown here, regardless of the season filter below —
    // the farmer wants to see whole-field usage, not just one season's.
    final allCrops = MockData.getCropsForField(widget.fieldId);
    final totalCost = allCrops.fold<double>(
      0.0,
      (sum, crop) => sum + MockData.getTotalInputCostForCrop(crop.id),
    );
    final areaUsed = MockData.getOccupiedAreaForField(widget.fieldId);

    // The season dropdown only offers seasons that actually have crops on
    // this field (plus the default, so it's never empty for a brand-new
    // field). The crops list itself is filtered to the selected season —
    // picking a season with no crops correctly shows an empty state.
    final seasons = {'Kharif 2026', ...allCrops.map((c) => c.season)}.toList()
      ..sort();
    final selectedSeason = seasons.contains(_selectedSeason) ? _selectedSeason : seasons.first;
    final crops = allCrops.where((c) => c.season == selectedSeason).toList();

    final actionPoints = MockData.getActionPointsForScope(
      ActionScope.field,
      widget.fieldId,
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                tooltip: 'Edit field',
                onPressed: _editField,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                tooltip: 'Delete field',
                onPressed: _deleteField,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.headerGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(56, 10, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    field.name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${field.area} acres • ${field.soilType}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.85),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on,
                                      color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    field.locationString,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
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
                  // ── Season Selector ──
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedSeason,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: seasons
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          size: 16,
                                          color: AppColors.primary),
                                      const SizedBox(width: 10),
                                      Text(s,
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) => setState(
                            () => _selectedSeason = v ?? selectedSeason),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Field Summary Stats ──
                  SummaryStatRow(stats: [
                    SummaryStat(
                      value: '${areaUsed.toStringAsFixed(1)}/${field.area.toStringAsFixed(1)}',
                      label: 'Acres Used',
                      color: areaUsed > field.area ? AppColors.warning : null,
                    ),
                    SummaryStat(
                      value: '${crops.length}',
                      label: 'Crops',
                      color: AppColors.primary,
                    ),
                    SummaryStat(
                      value: '₹${totalCost.toStringAsFixed(0)}',
                      label: 'Cost',
                      color: Colors.green.shade700,
                    ),
                    SummaryStat(
                      value: '${field.pendingActions}',
                      label: 'Actions',
                      color: field.pendingActions > 4
                          ? AppColors.warning
                          : null,
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // ── Crops List ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Crops',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          await Navigator.pushNamed(context, '/add-crop',
                              arguments: widget.fieldId);
                          if (mounted) setState(() {});
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Crop'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ...crops.map((crop) => _CropCard(
                        crop: crop,
                        onTap: () async {
                          await Navigator.pushNamed(
                            context,
                            '/crop-summary',
                            arguments: crop.id,
                          );
                          setState(() {});
                        },
                      )),

                  if (crops.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.grass, size: 48, color: AppColors.primary),
                          const SizedBox(height: 12),
                          Text(
                            allCrops.isEmpty ? 'No crops yet' : 'No crops in $selectedSeason',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            allCrops.isEmpty
                                ? 'Add your first crop to start tracking'
                                : 'This field had no crops during this season',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // ── Action Points ──
                  if (actionPoints.isNotEmpty) ...[
                    const Text(
                      'Action Points',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
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
        onPressed: () async {
          await Navigator.pushNamed(context, '/add-crop',
              arguments: widget.fieldId);
          setState(() {});
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Crop'),
      ),
    );
  }
}

/// A card for displaying a crop within the field.
class _CropCard extends StatelessWidget {
  final dynamic crop; // CropModel
  final VoidCallback onTap;

  const _CropCard({required this.crop, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cropCost = MockData.getTotalInputCostForCrop(crop.id);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            // Crop icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('🌾', style: TextStyle(fontSize: 24)),
              ),
            ),

            const SizedBox(width: 14),

            // Crop info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    crop.cropName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${crop.variety} • ${crop.activityCount} activities • ₹${cropCost.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (crop.daysToHarvest > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${crop.daysToHarvest} days to harvest',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Health + arrow
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusChip(
                    status: crop.healthStatus ?? 'good', size: 8),
                const SizedBox(height: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
