import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/logger_service.dart';
import 'theme.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/scanner_page.dart';
import 'pages/color_detail_page.dart';
import 'pages/register.dart';
import 'pages/config.dart';
import 'pages/profile_page.dart';
import 'pages/edit_profile_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/email_preferences_page.dart';
import 'pages/history_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LoggerService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConfig.appName,
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}

// Router Configuration
final GoRouter _router = GoRouter(
  initialLocation: '/dashboard',
  redirect: (context, state) async {
    // Basic Auth Check
    final prefs = await SharedPreferences.getInstance();
    final isAuth = prefs.getBool(AppConfig.authKey) ?? false;

    final location = state.matchedLocation;
    final isAuthPath = location == '/' || location == '/register';

    if (!isAuth && !isAuthPath) {
      LoggerService.logger
          .i("User not authenticated. Redirecting to login page.");
      return '/';
    }
    if (isAuth && isAuthPath) {
      LoggerService.logger
          .i("User already authenticated. Redirecting to dashboard.");
      return '/dashboard';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final colorHex = extra?['color'] as String?;
        final pantoneName = extra?['pantone'] as String?;
        return DashboardPage(colorHex: colorHex, pantoneName: pantoneName);
      },
    ),
    GoRoute(
      path: '/scanner',
      builder: (context, state) => const ScannerPage(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: '/profile/edit',
      builder: (context, state) => const EditProfilePage(),
    ),
    GoRoute(
      path: '/profile/history',
      builder: (context, state) => const HistoryPage(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    GoRoute(
      path: '/profile/email-preferences',
      builder: (context, state) => const EmailPreferencesPage(),
    ),
    GoRoute(
      path: '/color/:hex',
      builder: (context, state) {
        final hex = state.pathParameters['hex']!;
        return ColorDetailPage(hex: hex);
      },
    ),
  ],
);
