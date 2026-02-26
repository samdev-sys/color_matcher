import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/scanner_page.dart';
import 'pages/color_detail_page.dart';
import 'pages/register.dart';
import 'pages/config.dart';
import 'pages/profile_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  // Ensure you add .env to pubspec assets
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Warning: .env file not found. Gemini API features may not work.");
  }

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
    
    if (!isAuth && !isAuthPath) return '/';
    if (isAuth && isAuthPath) return '/dashboard';
    
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
      path: '/color/:hex',
      builder: (context, state) {
        final hex = state.pathParameters['hex']!;
        return ColorDetailPage(hex: hex);
      },
    ),
  ],
);
