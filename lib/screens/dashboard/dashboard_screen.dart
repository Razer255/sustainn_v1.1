import 'package:flutter/material.dart';
import '../../models/action_point_model.dart';
import '../../models/crop_model.dart';
import '../../services/mock_data.dart';
import '../../services/weather_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/action_point_tile.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/summary_card.dart';
import 'profile_tab.dart';
import 'reports_tab.dart';

/// Main dashboard screen — the farmer's home view.
/// Shows: greeting, farmer summary stats, fields list, and action points feed.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentNavIndex = 0;

  WeatherForecast? _weather;
  bool _weatherLoading = true;
  bool _weatherError = false;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _weatherLoading = true;
      _weatherError = false;
    });

    // Weather is anchored to the farmer's first field — no device GPS yet.
    final fields = MockData.fields;
    final lat = fields.isNotEmpty ? fields.first.latitude : null;
    final lng = fields.isNotEmpty ? fields.first.longitude : null;

    if (lat == null || lng == null) {
      setState(() {
        _weatherLoading = false;
        _weatherError = true;
      });
      return;
    }

    final forecast = await WeatherService().getForecast(
      latitude: lat,
      longitude: lng,
    );

    if (!mounted) return;
    setState(() {
      _weather = forecast;
      _weatherLoading = false;
      _weatherError = forecast == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = MockData.currentUser;
    final fields = MockData.fields;
    final actionPoints = MockData.getAllUnresolvedActionPoints();

    return Scaffold(
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          // ── Tab 0: Home ──
          CustomScrollView(
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
                          value: _weatherLoading
                              ? '--°C'
                              : (_weather?.current != null
                                  ? '${_weather!.current!.temperature.round()}°C'
                                  : '--°C'),
                          subtitle: _weatherLoading
                              ? 'Loading...'
                              : (_weather?.current?.condition.label ??
                                  'Unavailable'),
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
                      onPressed: () async {
                        await Navigator.pushNamed(context, '/add-field');
                        setState(() {});
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Field'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...fields.map((field) => _FieldCard(
                        field: field,
                        onTap: () async {
                          await Navigator.pushNamed(
                            context,
                            '/field-summary',
                            arguments: field.id,
                          );
                          setState(() {});
                        },
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
          // ── Tab 1: Fields ──
          _buildFieldsTab(context, fields),
          // ── Tab 2: Reports ──
          ReportsTab(
            weather: _weather,
            isLoading: _weatherLoading,
            hasError: _weatherError,
            onRetry: _fetchWeather,
          ),
          // ── Tab 3: Profile ──
          ProfileTab(user: user),
        ],
      ),

      // ── FAB: Add Activity / Add Field ──
      floatingActionButton: _currentNavIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showAddActivityCropSelection(context),
              tooltip: 'Add Activity',
              child: const Icon(Icons.add_task),
            )
          : _currentNavIndex == 1
              ? FloatingActionButton(
                  onPressed: () async {
                    await Navigator.pushNamed(context, '/add-field');
                    setState(() {});
                  },
                  tooltip: 'Add Field',
                  child: const Icon(Icons.add),
                )
              : null,

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

  Widget _buildFieldsTab(BuildContext context, List<dynamic> fields) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 80,
          floating: false,
          pinned: true,
          backgroundColor: AppColors.primary,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            title: const Text(
              'My Fields',
              style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 20),
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.headerGradient,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final field = fields[index];
                return _FieldCard(
                  field: field,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/field-summary',
                    arguments: field.id,
                  ),
                );
              },
              childCount: fields.length,
            ),
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 🌅';
    if (hour < 17) return 'Good Afternoon ☀️';
    return 'Good Evening 🌙';
  }

  void _showAddActivityCropSelection(BuildContext context) {
    final crops = MockData.crops.where((c) => c.status == CropStatus.active).toList();

    if (crops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active crops found. Please add a crop first.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Crop for Activity',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: crops.length,
                    itemBuilder: (context, index) {
                      final crop = crops[index];
                      final field = MockData.fields.firstWhere(
                        (f) => f.id == crop.fieldId,
                        orElse: () => MockData.fields.first,
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: AppColors.border.withOpacity(0.5),
                          ),
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.primaryLight,
                            child: Text('🌱'),
                          ),
                          title: Text(
                            crop.cropName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('${crop.variety} • ${field.name}'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                          onTap: () async {
                            Navigator.pop(context);
                            await Navigator.pushNamed(
                              context,
                              '/add-activity',
                              arguments: crop.id,
                            );
                            setState(() {});
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
