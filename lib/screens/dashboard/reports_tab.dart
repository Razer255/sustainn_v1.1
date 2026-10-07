import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/weather_service.dart';
import '../../theme/app_colors.dart';

/// Reports tab — currently a live weather section: today's conditions plus
/// the next 5 days. Weather data is fetched once by [DashboardScreen] and
/// passed in here, so switching tabs doesn't re-hit the network.
class ReportsTab extends StatelessWidget {
  final WeatherForecast? weather;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onRetry;

  const ReportsTab({
    super.key,
    required this.weather,
    required this.isLoading,
    required this.hasError,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
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
              'Reports',
              style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 20),
            ),
            background: Container(
              decoration: const BoxDecoration(gradient: AppColors.headerGradient),
            ),
          ),
        ),
        SliverToBoxAdapter(child: _buildBody(context)),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (hasError || weather == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            const Icon(Icons.cloud_off, size: 56, color: AppColors.textHint),
            const SizedBox(height: 16),
            const Text(
              "Couldn't load weather",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Check your connection and try again',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final current = weather!.current;
    final today = weather!.days.isNotEmpty ? weather!.days.first : null;
    final upcoming = weather!.days.skip(1).take(5).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TodayWeatherCard(current: current, today: today),
          const SizedBox(height: 24),
          const Text(
            'Next 5 Days',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          ...upcoming.map((day) => _ForecastDayRow(day: day)),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _TodayWeatherCard extends StatelessWidget {
  final CurrentWeather? current;
  final DayForecast? today;

  const _TodayWeatherCard({required this.current, required this.today});

  @override
  Widget build(BuildContext context) {
    final condition = current?.condition ?? today?.condition;
    final temp = current?.temperature ?? today?.tempMax;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Weather",
            style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(condition?.emoji ?? '🌡️', style: const TextStyle(fontSize: 48)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      temp != null ? '${temp.round()}°C' : '--°C',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      condition?.label ?? 'Unavailable',
                      style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (today != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _TodayStat(
                  icon: Icons.arrow_upward,
                  label: '${today!.tempMax.round()}°',
                ),
                const SizedBox(width: 20),
                _TodayStat(
                  icon: Icons.arrow_downward,
                  label: '${today!.tempMin.round()}°',
                ),
                const SizedBox(width: 20),
                _TodayStat(
                  icon: Icons.water_drop_outlined,
                  label: '${today!.precipitationProbability.round()}%',
                ),
                const SizedBox(width: 20),
                _TodayStat(
                  icon: Icons.air,
                  label: '${today!.windSpeedMax.round()} km/h',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TodayStat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TodayStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.white70),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _ForecastDayRow extends StatelessWidget {
  final DayForecast day;

  const _ForecastDayRow({required this.day});

  @override
  Widget build(BuildContext context) {
    final condition = day.condition;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              DateFormat('EEE, d MMM').format(day.date),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
          Text(condition.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              condition.label,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (day.precipitationProbability > 0) ...[
            const Icon(Icons.water_drop_outlined, size: 13, color: AppColors.info),
            const SizedBox(width: 2),
            Text(
              '${day.precipitationProbability.round()}%',
              style: const TextStyle(fontSize: 12, color: AppColors.info, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 10),
          ],
          Text(
            '${day.tempMax.round()}° / ${day.tempMin.round()}°',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
