import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'privacy_settings_screen.dart';
import 'help_support_screen.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _auth = AuthService();
  
  bool _isLoading = true;
  String _name = 'Loading...';
  String _email = '';
  int _hours = 6;
  int _xp = 0;
  int _streak = 0;

  late Color primary;
  late Color surface;
  late Color onSurface;
  late Color outlineVariant;


  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await _auth.getProfile();
    if (data != null && mounted) {
      setState(() {
        _name = data['name'] ?? 'Aspirant';
        _email = data['email'] ?? '';
        _hours = data['daily_study_hours'] ?? 6;
        _xp = data['xp'] ?? 0;
        _streak = data['streak_days'] ?? 0;
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _signOut() async {
    await _auth.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _updateHours(int delta) async {
    final newHours = _hours + delta;
    if (newHours < 1 || newHours > 16) return;
    
    // Optimistic Update
    final oldHours = _hours;
    setState(() => _hours = newHours);
    
    try {
      final success = await _auth.updateProfile(hours: newHours);
      if (!success && mounted) {
        // We only revert if it's a critical failure, but for hours, 
        // let's keep it locally updated to avoid "shifting back" flickers.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Syncing with Command Center...', style: TextStyle(fontSize: 10)), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hours = oldHours);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sync Error. Reverting goals.')));
      }
    }
  }

  Future<void> _goToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    if (result == true) {
      _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final background = theme.scaffoldBackgroundColor;
    primary = colorScheme.primary;
    surface = theme.cardColor;
    onSurface = colorScheme.onSurface;
    outlineVariant = colorScheme.outlineVariant;
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: background,
        body: Center(child: CircularProgressIndicator(color: colorScheme.primary)),
      );
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: onSurface, size: 20),
        ),
        title: Text(
          'PROFILE',
          style: TextStyle(
            fontFamily: 'Lexend',
            fontWeight: FontWeight.w800,
            color: primary,
            fontSize: 12,
            letterSpacing: 4.0,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              _buildModernProfileHeader(colorScheme),
              const SizedBox(height: 48),
              _buildExamPreferences(theme, colorScheme),
              const SizedBox(height: 32),
              _buildDailyGoals(theme, colorScheme),
              const SizedBox(height: 48),
              _buildSettingsList(theme, colorScheme),
              const SizedBox(height: 48),
              _buildSignOutButton(colorScheme),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildModernProfileHeader(ColorScheme colorScheme) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1), width: 4),
          ),
          child: Icon(Icons.person_rounded, size: 50, color: colorScheme.primary),
        ),
        const SizedBox(height: 20),
        Text(
          _name,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: colorScheme.onSurface, letterSpacing: -0.5),
        ),
        const SizedBox(height: 4),
        Text(
          _email.isEmpty ? 'candidate@upsc.gov.in' : _email,
          style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 14),
              SizedBox(width: 6),
              Text(
                'PREMIUM ACCESS',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF10B981), letterSpacing: 1.0),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBadge(Icons.local_fire_department_rounded, '$_streak Day Streak', const Color(0xFFF97316), colorScheme),
            const SizedBox(width: 16),
            _buildBadge(Icons.auto_awesome, '$_xp XP', Colors.amber, colorScheme),
          ],
        ),
      ],
    );
  }

  Widget _buildBadge(IconData icon, String text, Color color, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13, fontFamily: 'Lexend')),
        ],
      ),
    );
  }

  Widget _buildExamPreferences(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Target Exam', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colorScheme.onSurface, fontFamily: 'Lexend')),
              IconButton(
                onPressed: _goToEditProfile,
                icon: Icon(Icons.edit_note_rounded, color: colorScheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.flag_rounded, color: colorScheme.primary, size: 20),
                const SizedBox(width: 12),
                Text('UPSC CSE 2025', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colorScheme.primary, fontFamily: 'Lexend')),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDailyGoals(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily Goal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colorScheme.onSurface, fontFamily: 'Lexend')),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => _updateHours(-1),
                icon: Icon(Icons.remove_circle_outline_rounded, color: colorScheme.primary),
                iconSize: 32,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(_hours.toString().padLeft(2, '0'), style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: colorScheme.onSurface, letterSpacing: -1.0, fontFamily: 'Lexend')),
                  const SizedBox(width: 4),
                  Text('HRS', style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.3), fontWeight: FontWeight.w800, fontFamily: 'Lexend')),
                ],
              ),
              IconButton(
                onPressed: () => _updateHours(1),
                icon: Icon(Icons.add_circle_rounded, color: colorScheme.primary),
                iconSize: 32,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsList(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        _buildSettingItem(Icons.lock_person_rounded, 'Privacy & Security', () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()));
        }, theme, colorScheme),
        _buildSettingItem(Icons.help_center_rounded, 'Help & Support', () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
        }, theme, colorScheme),
        _buildDarkModeTile(theme, colorScheme),
        const SizedBox(height: 24),
        _buildSettingItem(Icons.delete_sweep_rounded, 'Clear All Study Data', () async {
          final confirm = await _showConfirmDialog('Clear Data', 'Are you sure you want to clear all your study progress? This cannot be undone.');
          if (confirm) {
            final success = await _auth.clearData();
            if (success && mounted) {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All study data has been wiped.')));
            }
          }
        }, theme, colorScheme, isDestructive: true),
        _buildSettingItem(Icons.person_remove_rounded, 'Delete Account Data', () async {
          final confirm = await _showConfirmDialog('Delete Account', 'This will permanently delete your account and all data. Proceed?');
          if (confirm) {
            final success = await _auth.deleteAccount();
            if (success && mounted) {
               _signOut();
            }
          }
        }, theme, colorScheme, isDestructive: true),
      ],
    );
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('PROCEED', style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;
  }

  Widget _buildSettingItem(IconData icon, String title, VoidCallback onTap, ThemeData theme, ColorScheme colorScheme, {bool isDestructive = false}) {
    final textColor = isDestructive ? const Color(0xFFEF4444) : colorScheme.onSurface;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (isDestructive ? const Color(0xFFEF4444) : colorScheme.primary).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: isDestructive ? const Color(0xFFEF4444) : colorScheme.primary),
        ),
        title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor, fontFamily: 'Lexend')),
        trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.onSurface.withValues(alpha: 0.2)),
      ),
    );
  }

  Widget _buildDarkModeTile(ThemeData theme, ColorScheme colorScheme) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.dark_mode_rounded, color: colorScheme.primary),
        ),
        title: Text('Dark Mode', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colorScheme.onSurface, fontFamily: 'Lexend')),
        trailing: Switch(
          value: themeProvider.isDarkMode,
          onChanged: (val) => themeProvider.toggleTheme(),
          activeTrackColor: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSignOutButton(ColorScheme colorScheme) {
    return TextButton.icon(
      onPressed: _signOut,
      icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
      label: const Text(
        'SIGN OUT',
        style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1.0),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
