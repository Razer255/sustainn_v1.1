import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Weather service using the free Open-Meteo API.
/// No API key required. Used to generate weather-based action points and
/// to power the live weather shown on the Home card and Reports tab.
class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  /// Fetch current conditions + 7-day weather forecast for given coordinates.
  Future<WeatherForecast?> getForecast({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl?latitude=$latitude&longitude=$longitude'
        '&current_weather=true'
        '&daily=temperature_2m_max,temperature_2m_min,'
        'precipitation_sum,precipitation_probability_max,'
        'windspeed_10m_max,weathercode'
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

/// Parsed weather forecast, including today's current conditions.
class WeatherForecast {
  final CurrentWeather? current;
  final List<DayForecast> days;

  const WeatherForecast({this.current, required this.days});

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    final daily = json['daily'] as Map<String, dynamic>;
    final dates = (daily['time'] as List).cast<String>();
    final maxTemps = (daily['temperature_2m_max'] as List).cast<num>();
    final minTemps = (daily['temperature_2m_min'] as List).cast<num>();
    final precip = (daily['precipitation_sum'] as List).cast<num>();
    final precipProb =
        (daily['precipitation_probability_max'] as List).cast<num>();
    final wind = (daily['windspeed_10m_max'] as List).cast<num>();
    final codes = (daily['weathercode'] as List?)?.cast<num>();

    final days = <DayForecast>[];
    for (int i = 0; i < dates.length; i++) {
      days.add(DayForecast(
        date: DateTime.parse(dates[i]),
        tempMax: maxTemps[i].toDouble(),
        tempMin: minTemps[i].toDouble(),
        precipitationSum: precip[i].toDouble(),
        precipitationProbability: precipProb[i].toDouble(),
        windSpeedMax: wind[i].toDouble(),
        weatherCode: codes != null ? codes[i].toInt() : 0,
      ));
    }

    final currentJson = json['current_weather'] as Map<String, dynamic>?;
    final current = currentJson != null
        ? CurrentWeather.fromJson(currentJson)
        : null;

    return WeatherForecast(current: current, days: days);
  }
}

/// Current (right-now) conditions from Open-Meteo's `current_weather` block.
class CurrentWeather {
  final double temperature;
  final double windSpeed;
  final int weatherCode;
  final bool isDay;

  const CurrentWeather({
    required this.temperature,
    required this.windSpeed,
    required this.weatherCode,
    required this.isDay,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      temperature: (json['temperature'] as num).toDouble(),
      windSpeed: (json['windspeed'] as num).toDouble(),
      weatherCode: (json['weathercode'] as num).toInt(),
      isDay: json['is_day'] == 1,
    );
  }

  WeatherCondition get condition => weatherConditionFor(weatherCode);
}

/// Single day forecast data.
class DayForecast {
  final DateTime date;
  final double tempMax;
  final double tempMin;
  final double precipitationSum; // mm
  final double precipitationProbability; // %
  final double windSpeedMax; // km/h
  final int weatherCode;

  const DayForecast({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.precipitationSum,
    required this.precipitationProbability,
    required this.windSpeedMax,
    this.weatherCode = 0,
  });

  bool get isRainy => precipitationProbability > 60;
  bool get isHeavyRain => precipitationSum > 20;
  bool get isWindy => windSpeedMax > 40;

  WeatherCondition get condition => weatherConditionFor(weatherCode);
}

/// A human-readable label + emoji for a WMO weather code.
/// https://open-meteo.com/en/docs — WMO Weather interpretation codes.
class WeatherCondition {
  final String label;
  final String emoji;

  const WeatherCondition(this.label, this.emoji);
}

WeatherCondition weatherConditionFor(int code) {
  if (code == 0) return const WeatherCondition('Clear sky', '☀️');
  if (code <= 2) return const WeatherCondition('Partly cloudy', '⛅');
  if (code == 3) return const WeatherCondition('Overcast', '☁️');
  if (code == 45 || code == 48) return const WeatherCondition('Fog', '🌫️');
  if (code >= 51 && code <= 57) {
    return const WeatherCondition('Drizzle', '🌦️');
  }
  if (code >= 61 && code <= 67) return const WeatherCondition('Rain', '🌧️');
  if (code >= 71 && code <= 77) return const WeatherCondition('Snow', '❄️');
  if (code >= 80 && code <= 82) {
    return const WeatherCondition('Rain showers', '🌧️');
  }
  if (code >= 85 && code <= 86) {
    return const WeatherCondition('Snow showers', '🌨️');
  }
  if (code >= 95) return const WeatherCondition('Thunderstorm', '⛈️');
  return const WeatherCondition('Unknown', '🌡️');
}
