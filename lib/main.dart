import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'routes/app_router.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

/// Sustainn Farmer App — Farm management and advisory platform.
///
/// Entry point: configures providers, theme, routing, and launches
/// the correct initial screen based on authentication and first launch status.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // ── Hive initialization ──
  await Hive.initFlutter();
  final prefsBox = await Hive.openBox('prefs');
  
  // Check flags
  final isFirstLaunch = prefsBox.get('first_launch', defaultValue: true);

  // ── Status bar styling ──
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // ── Preferred orientations ──
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('hi')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: SustainnApp(
        isFirstLaunch: isFirstLaunch,
      ),
    ),
  );
}

class SustainnApp extends StatelessWidget {
  final bool isFirstLaunch;

  const SustainnApp({
    super.key,
    required this.isFirstLaunch,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: Consumer<AuthService>(
        builder: (context, auth, _) {
          
          String initialRoute;
          if (auth.isAuthenticated) {
            initialRoute = AppRouter.dashboard;
          } else {
            if (isFirstLaunch) {
              initialRoute = AppRouter.languageSelection;
            } else {
              initialRoute = AppRouter.login;
            }
          }

          return MaterialApp(
            title: 'Sustainn Farmer',
            debugShowCheckedModeBanner: false,

            // ── Theme ──
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,

            // ── Routing ──
            initialRoute: initialRoute,
            onGenerateRoute: AppRouter.generateRoute,

            // ── Localization ──
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            locale: context.locale,
          );
        },
      ),
    );
  }
}
