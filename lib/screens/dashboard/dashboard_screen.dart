import 'package:flutter/material.dart';
import '../../models/action_point_model.dart';
import '../../services/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/action_point_tile.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/summary_card.dart';

/// Main dashboard screen — the farmer's home view.
/// Shows: greeting, farmer summary stats, fields list, and action points feed.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = MockData.currentUser;
    final fields = MockData.fields;
    final actionPoints = MockData.getAllUnresolvedActionPoints();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.headerGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getGreeting(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.85),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            // Profile avatar
                            GestureDetector(
                              onTap: () {
                                // TODO: Navigate to profile
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    user.name.isNotEmpty
                                        ? user.name[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
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

          // ── Body ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Farmer Summary Cards ──
                  const _SectionHeader(title: 'Farm Overview'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          icon: Icons.landscape,
                          title: 'Total Fields',
                          value: '${fields.length}',
                          subtitle: '${fields.fold<double>(0, (s, f) => s + f.area).toStringAsFixed(1)} acres',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SummaryCard(
                          icon: Icons.grass,
                          title: 'Active Crops',
                          value: '${fields.fold<int>(0, (s, f) => s + f.activeCrops)}',
                          subtitle: 'Kharif 2026',
                          iconColor: Colors.green.shade700,
                          iconBackgroundColor: Colors.green.shade50,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          icon: Icons.notifications_active_outlined,
                          title: 'Action Points',
                          value: '${actionPoints.length}',
                          subtitle: '${actionPoints.where((a) => a.priority == ActionPriority.high).length} urgent',
                          iconColor: AppColors.warning,
                          iconBackgroundColor: AppColors.warningLight,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SummaryCard(
                          icon: Icons.wb_sunny_outlined,
                          title: 'Weather',
                          value: '28°C',
                          subtitle: 'Partly cloudy',
                          iconColor: Colors.orange,
                          iconBackgroundColor: Colors.orange.shade50,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── Fields List ──
                  _SectionHeader(
                    title: 'My Fields',
                    trailing: TextButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/add-field'),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Field'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...fields.map((field) => _FieldCard(
                        field: field,
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/field-summary',
                          arguments: field.id,
                        ),
                      )),

                  const SizedBox(height: 28),

                  // ── Action Points Feed ──
                  const _SectionHeader(title: 'Action Points'),
                  const SizedBox(height: 12),

                  ...actionPoints.map((ap) => ActionPointTile(
                        actionPoint: ap,
                        onResolve: () {
                          // TODO: resolve action point
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Action point resolved ✓'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                      )),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── FAB: Add Field ──
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-field'),
        child: const Icon(Icons.add),
      ),

      // ── Bottom Navigation ──
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentNavIndex,
        onDestinationSelected: (i) => setState(() => _currentNavIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.landscape_outlined),
            selectedIcon: Icon(Icons.landscape),
            label: 'Fields',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 🌅';
    if (hour < 17) return 'Good Afternoon ☀️';
    return 'Good Evening 🌙';
  }
}

/// Section header with optional trailing widget.
class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// A card displaying a field with its health status and key stats.
class _FieldCard extends StatelessWidget {
  final dynamic field; // FieldModel
  final VoidCallback onTap;

  const _FieldCard({required this.field, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Field name + icon
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.landscape,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              field.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${field.area} acres • ${field.soilType}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Health chip
                StatusChip(status: field.healthStatus ?? 'good'),
              ],
            ),

            const SizedBox(height: 14),

            // Stats row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.backgroundAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    icon: Icons.grass,
                    value: '${field.activeCrops}',
                    label: 'Crops',
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: AppColors.border,
                  ),
                  _StatItem(
                    icon: Icons.notifications_outlined,
                    value: '${field.pendingActions}',
                    label: 'Actions',
                    color: field.pendingActions > 4
                        ? AppColors.warning
                        : null,
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: AppColors.border,
                  ),
                  _StatItem(
                    icon: Icons.location_on_outlined,
                    value: field.locationString.split(',').first,
                    label: 'Location',
                  ),
                ],
              ),
            ),

            // Arrow indicator
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'View Details',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color ?? AppColors.textSecondary),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color ?? AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }
}
