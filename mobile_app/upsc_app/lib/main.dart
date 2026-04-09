import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/buddy_screen.dart';
import 'screens/library_screen.dart';
import 'screens/tuner_screen.dart';
import 'screens/menu_screen.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/theme_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  final isLoggedIn = token != null;
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: UPSCPlannerApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class UPSCPlannerApp extends StatelessWidget {
  final bool isLoggedIn;
  const UPSCPlannerApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UPSC Planner',
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1173D4), // Lumina Indigo
          primary: const Color(0xFF005AAB),
          primaryContainer: const Color(0xFF1173D4),
          secondary: const Color(0xFF515F74),
          surface: const Color(0xFFF7F9FB),
          onSurface: const Color(0xFF191C1E),
        ),
        textTheme: GoogleFonts.interTextTheme().copyWith(
          displayLarge: GoogleFonts.lexend(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF191C1E),
          ),
          headlineMedium: GoogleFonts.lexend(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1173D4),
          ),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F9FB),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          color: Colors.white,
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF0F172A),
          elevation: 0,
          centerTitle: false,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF005AAB),
          brightness: Brightness.dark,
          primary: const Color(0xFF005AAB), // Academic Architect Primary
          surface: const Color(0xFF0F172A), // Slate 900
          // background: const Color(0xFF020617), // Deprecated
          onSurface: const Color(0xFFF8FAFC), // Slate 50
        ),
        fontFamily: 'Lexend',
        scaffoldBackgroundColor: const Color(0xFF020617),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          color: const Color(0xFF0F172A),
          margin: EdgeInsets.zero,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: isLoggedIn ? const MainNavigation() : const LoginScreen(),
    );
  }
}

// --- NAVIGATION WRAPPER ---
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      LibraryScreen(onBackHome: () => setState(() => _currentIndex = 0)),
      MenuScreen(onBackHome: () => setState(() => _currentIndex = 0)),
      InsightsScreen(onBackHome: () => setState(() => _currentIndex = 0)),
      BuddyScreen(onBackHome: () => setState(() => _currentIndex = 0)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() {
          _currentIndex = 0;
        });
      },
      child: Scaffold(
        body: _screens[_currentIndex],
        floatingActionButton: (_currentIndex == 3 || _currentIndex == 4) ? null : FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TunerScreen()),
            );
          },
          backgroundColor: const Color(0xFF005AAB),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: GNav(
                rippleColor: Colors.grey[300]!,
                hoverColor: Colors.grey[100]!,
                gap: 4,
                activeColor: const Color(0xFF005AAB),
                iconSize: 22,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                duration: const Duration(milliseconds: 400),
                tabBackgroundColor: const Color(0xFF005AAB).withValues(alpha: 0.1),
                color: Colors.grey[600]!,
                tabs: const [
                  GButton(icon: Icons.home_rounded, text: 'War Room'),
                  GButton(icon: Icons.library_books_rounded, text: 'Library'),
                  GButton(icon: Icons.menu_rounded, text: 'Menu'),
                  GButton(icon: Icons.insights_rounded, text: 'Insights'),
                  GButton(icon: Icons.chat_bubble_rounded, text: 'Buddy'),
                ],
                selectedIndex: _currentIndex,
                onTabChange: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
