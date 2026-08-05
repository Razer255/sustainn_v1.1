import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Weather service using the free Open-Meteo API.
/// No API key required. Used to generate weather-based action points.
class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  /// Fetch 7-day weather forecast for given coordinates.
  Future<WeatherForecast?> getForecast({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl?latitude=$latitude&longitude=$longitude'
        '&daily=temperature_2m_max,temperature_2m_min,'
        'precipitation_sum,precipitation_probability_max,'
        'windspeed_10m_max'
        '&timezone=auto&forecast_days=7',
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherForecast.fromJson(data);
      }

      debugPrint('Weather API error: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Weather fetch error: $e');
      return null;
    }
  }

  /// Check if heavy rain is expected in the next N days.
  Future<bool> isHeavyRainExpected({
    required double latitude,
    required double longitude,
    int withinDays = 3,
  }) async {
    final forecast = await getForecast(
      latitude: latitude,
      longitude: longitude,
    );

    if (forecast == null) return false;

    for (int i = 0; i < withinDays && i < forecast.days.length; i++) {
      if (forecast.days[i].precipitationSum > 20) {
        return true;
      }
    }
    return false;
  }
}

/// Parsed weather forecast.
class WeatherForecast {
  final List<DayForecast> days;

  const WeatherForecast({required this.days});

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    final daily = json['daily'] as Map<String, dynamic>;
    final dates = (daily['time'] as List).cast<String>();
    final maxTemps = (daily['temperature_2m_max'] as List).cast<num>();
    final minTemps = (daily['temperature_2m_min'] as List).cast<num>();
    final precip = (daily['precipitation_sum'] as List).cast<num>();
    final precipProb =
        (daily['precipitation_probability_max'] as List).cast<num>();
    final wind = (daily['windspeed_10m_max'] as List).cast<num>();

    final days = <DayForecast>[];
    for (int i = 0; i < dates.length; i++) {
      days.add(DayForecast(
        date: DateTime.parse(dates[i]),
        tempMax: maxTemps[i].toDouble(),
        tempMin: minTemps[i].toDouble(),
        precipitationSum: precip[i].toDouble(),
        precipitationProbability: precipProb[i].toDouble(),
        windSpeedMax: wind[i].toDouble(),
      ));
    }

    return WeatherForecast(days: days);
  }
}

/// Single day forecast data.
class DayForecast {
  final DateTime date;
  final double tempMax;
  final double tempMin;
  final double precipitationSum; // mm
  final double precipitationProbability; // %
  final double windSpeedMax; // km/h

  const DayForecast({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.precipitationSum,
    required this.precipitationProbability,
    required this.windSpeedMax,
  });

  bool get isRainy => precipitationProbability > 60;
  bool get isHeavyRain => precipitationSum > 20;
  bool get isWindy => windSpeedMax > 40;
}
