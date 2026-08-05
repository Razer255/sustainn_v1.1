import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'routes/app_router.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

/// Sustainn Farmer App — Farm management and advisory platform.
///
/// Entry point: configures providers, theme, routing, and launches
/// the login screen (or dashboard if already authenticated).
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase initialization (uncomment when google-services.json is added) ──
  // await Firebase.initializeApp();

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

  runApp(const SustainnApp());
}

class SustainnApp extends StatelessWidget {
  const SustainnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: Consumer<AuthService>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'Sustainn Farmer',
            debugShowCheckedModeBanner: false,

            // ── Theme ──
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,

            // ── Routing ──
            initialRoute: auth.isAuthenticated
                ? AppRouter.dashboard
                : AppRouter.login,
            onGenerateRoute: AppRouter.generateRoute,

            // ── Localization (uncomment when easy_localization is set up) ──
            // supportedLocales: context.supportedLocales,
            // localizationsDelegates: context.localizationDelegates,
            // locale: context.locale,
          );
        },
      ),
    );
  }
}
