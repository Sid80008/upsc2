import 'package:flutter/material.dart';
import 'dart:ui';
import 'command_center_screen.dart';
import 'news_screen.dart';
import 'library_screen.dart';
import 'tuner_screen.dart';
import 'home_screen.dart';
import 'schedule_screen.dart';

class MenuScreen extends StatelessWidget {
  final VoidCallback? onBackHome;
  const MenuScreen({super.key, this.onBackHome});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Gradient Orbs
          Positioned(
            top: -100,
            right: -100,
            child: _buildBlurOrb(colorScheme.primary.withValues(alpha: 0.1), 300),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _buildBlurOrb(const Color(0xFF10B981).withValues(alpha: 0.05), 250),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, colorScheme),
                Expanded(
                  child: GridView.count(
                    padding: const EdgeInsets.all(24),
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    children: [
                      _buildMenuCard(context, 'WAR ROOM', 'Daily Schedule', Icons.grid_view_rounded, colorScheme.primary, const HomeScreen()),
                      _buildMenuCard(context, 'STUDY AI', 'Gemini Architect', Icons.psychology_rounded, const Color(0xFF8B5CF6), const CommandCenterScreen()),
                      _buildMenuCard(context, 'HUB', 'Library & Assets', Icons.all_inclusive_rounded, const Color(0xFF10B981), LibraryScreen()),
                      _buildMenuCard(context, 'THE READER', 'Daily Dispatch', Icons.newspaper_rounded, const Color(0xFFF59E0B), const NewsScreen()),
                      _buildMenuCard(context, 'TUNER', 'UPSC Mode', Icons.tune_rounded, const Color(0xFFEF4444), TunerScreen()),
                      _buildMenuCard(context, 'BACKLOG', 'Recovery', Icons.history_rounded, const Color(0xFF6366F1), ScheduleScreen()),
                    ],
                  ),
                ),
                _buildFooter(context, colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SYSTEM',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                  color: colorScheme.primary,
                ),
              ),
              const Text(
                'Mission Control',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: onBackHome ?? () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, size: 28),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.onSurface.withValues(alpha: 0.05),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, String subtitle, IconData icon, Color color, Widget target) {
    // ignore: unused_local_variable
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: color.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => target));
          },
          borderRadius: BorderRadius.circular(32),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield_rounded, size: 16, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                Text(
                  'ENCRYPTED ECOSYSTEM ACTIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'ACADEMIC ARCHITECT V2.5',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: colorScheme.onSurface.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }
}
