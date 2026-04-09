import 'package:flutter/material.dart';

import 'screens/profile_screen.dart';
import 'screens/report_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/library_screen.dart';
import 'screens/buddy_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/tuner_screen.dart';
import 'screens/recovery_screen.dart';
import 'main.dart';

/// App router for the UPSC app.
class AppRouter {
  Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/signup':
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case '/onboarding':
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case '/home':
        return MaterialPageRoute(builder: (_) => const MainNavigation());
      case '/schedule':
        return MaterialPageRoute(builder: (_) => ScheduleScreen());
      case '/report':
        return MaterialPageRoute(builder: (_) => const ReportScreen());
      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case '/library':
        return MaterialPageRoute(builder: (_) => LibraryScreen());
      case '/buddy':
        return MaterialPageRoute(builder: (_) => BuddyScreen());
      case '/insights':
        return MaterialPageRoute(builder: (_) => InsightsScreen());
      case '/tuner':
        return MaterialPageRoute(builder: (_) => TunerScreen());
      case '/recovery':
        return MaterialPageRoute(builder: (_) => const RecoveryScreen());
      default:
        // Fallback route for unknown paths.
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: const Text('UPSC Architect'),
            ),
            body: const Center(
              child: Text('Unknown route'),
            ),
          ),
        );
    }
  }
}

