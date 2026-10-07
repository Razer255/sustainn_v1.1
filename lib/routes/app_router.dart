import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/language_selection_screen.dart';

import '../screens/dashboard/dashboard_screen.dart';
import '../screens/dashboard/add_field_screen.dart';
import '../screens/field/field_summary_screen.dart';
import '../screens/field/add_crop_screen.dart';
import '../screens/crop/crop_summary_screen.dart';
import '../screens/crop/add_activity_screen.dart';

/// Centralized app routing configuration.
/// Maps named routes to screens and handles argument passing.
class AppRouter {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String languageSelection = '/language-selection';

  static const String dashboard = '/dashboard';
  static const String addField = '/add-field';
  static const String fieldSummary = '/field-summary';
  static const String addCrop = '/add-crop';
  static const String cropSummary = '/crop-summary';
  static const String addActivity = '/add-activity';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return _buildRoute(const LoginScreen(), settings);

      case signup:
        return _buildRoute(const SignupScreen(), settings);

      case languageSelection:
        return _buildRoute(const LanguageSelectionScreen(), settings);



      case dashboard:
        return _buildRoute(const DashboardScreen(), settings);

      case addField:
        return _buildRoute(const AddFieldScreen(), settings);

      case fieldSummary:
        final fieldId = settings.arguments as String?;
        if (fieldId == null) return _buildRoute(const DashboardScreen(), settings);
        return _buildRoute(
          FieldSummaryScreen(fieldId: fieldId),
          settings,
        );

      case addCrop:
        final fieldId = settings.arguments as String?;
        if (fieldId == null) return _buildRoute(const DashboardScreen(), settings);
        return _buildRoute(
          AddCropScreen(fieldId: fieldId),
          settings,
        );

      case cropSummary:
        final cropId = settings.arguments as String?;
        if (cropId == null) return _buildRoute(const DashboardScreen(), settings);
        return _buildRoute(
          CropSummaryScreen(cropId: cropId),
          settings,
        );

      case addActivity:
        final cropId = settings.arguments as String?;
        if (cropId == null) return _buildRoute(const DashboardScreen(), settings);
        return _buildRoute(
          AddActivityScreen(cropId: cropId),
          settings,
        );

      default:
        return _buildRoute(
          Scaffold(
            body: Center(
              child: Text('Route not found: ${settings.name}'),
            ),
          ),
          settings,
        );
    }
  }

  static MaterialPageRoute _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }
}
