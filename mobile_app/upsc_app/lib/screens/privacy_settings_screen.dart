import 'package:flutter/material.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  static const Color primary = Color(0xFF005AAB);
  static const Color primaryFixed = Color(0xFFD5E3FF);
  static const Color tertiary = Color(0xFF006847);
  static const Color surface = Color(0xFFF7F9FB);
  static const Color surfaceLowest = Color(0xFFFFFFFF);
  static const Color surfaceLow = Color(0xFFF2F4F6);
  static const Color onSurface = Color(0xFF191C1E);
  static const Color secondary = Color(0xFF515F74);
  static const Color error = Color(0xFFBA1A1A);

  bool _appLock = true;
  bool _trackPerformance = true;
  bool _storeLocal = false;
  bool _syncServer = true;
  bool _aiAdapt = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        backgroundColor: surfaceLow,
        elevation: 0,
        scrolledUnderElevation: 4,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: secondary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text('Privacy Settings', style: TextStyle(color: Color(0xFF1173D4), fontWeight: FontWeight.bold)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 32,
            height: 32,
            decoration: const BoxDecoration(color: primaryFixed, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Text('JD', style: TextStyle(color: Color(0xFF001b3c), fontWeight: FontWeight.bold, fontSize: 12)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel('SECURITY'),
            _buildCard([
              _buildToggleRow(Icons.fingerprint, 'App lock (PIN / biometric)', 'Secure your study vault with device security', _appLock, (v) => setState(() => _appLock = v), isAppLock: true),
            ]),
            const SizedBox(height: 32),
            _buildSectionLabel('DATA CONTROL'),
            _buildCard([
              _buildToggleRow(Icons.query_stats, 'Allow performance tracking', null, _trackPerformance, (v) => setState(() => _trackPerformance = v)),
              _buildDivider(),
              _buildToggleRow(Icons.storage, 'Store study history locally', null, _storeLocal, (v) => setState(() => _storeLocal = v)),
              _buildDivider(),
              _buildToggleRow(Icons.cloud_sync, 'Sync data with server', null, _syncServer, (v) => setState(() => _syncServer = v)),
            ]),
            const SizedBox(height: 32),
            _buildSectionLabel('AI & PERSONALIZATION'),
            _buildCard([
              _buildToggleRow(Icons.psychology, 'Allow AI-based schedule adaptation', null, _aiAdapt, (v) => setState(() => _aiAdapt = v), isAi: true),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: surfaceLow, borderRadius: BorderRadius.circular(12)),
                child: const Text(
                  'Our AI engine analyzes your study patterns, peak performance hours, and syllabus coverage to dynamically reorganize your UPSC roadmap. Your data is encrypted and used only for your personal planning.',
                  style: TextStyle(fontSize: 12, color: secondary, height: 1.5),
                ),
              ),
            ]),
            const SizedBox(height: 32),
            _buildSectionLabel('ACCOUNT ACTIONS'),
            _buildCard([
              _buildActionRow(Icons.delete_sweep, 'Clear all study data'),
              _buildDivider(),
              _buildActionRow(Icons.person_remove, 'Delete account data'),
            ]),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: Text(
                'All data deletions are permanent and cannot be undone. Please ensure you have backed up any necessary study notes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: secondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: secondary, letterSpacing: 1.5)),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x0F191C1E), offset: Offset(0, 12), blurRadius: 32, spreadRadius: -4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Divider(color: surfaceLow, height: 1),
    );
  }

  Widget _buildToggleRow(IconData icon, String title, String? subtitle, bool value, ValueChanged<bool> onChanged, {bool isAppLock = false, bool isAi = false}) {
    Color iconColor = secondary;
    Color iconBg = Colors.transparent;
    
    if (isAppLock) {
      iconColor = primary;
      iconBg = primaryFixed.withValues(alpha: 0.5);
    } else if (isAi) {
      iconColor = tertiary;
      iconBg = tertiary.withValues(alpha: 0.1);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurface)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: secondary)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: primary,
          inactiveTrackColor: const Color(0xFFC1C6D4).withValues(alpha: 0.3),
        ),
      ],
    );
  }

  Widget _buildActionRow(IconData icon, String title) {
    return InkWell(
      onTap: () {},
      child: Row(
        children: [
          Icon(icon, color: error),
          const SizedBox(width: 16),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: error)),
        ],
      ),
    );
  }
}
