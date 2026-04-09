import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/schedule_service.dart';

class TunerScreen extends StatefulWidget {
  const TunerScreen({super.key});

  @override
  State<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends State<TunerScreen> {
  final ScheduleService _api = ScheduleService();
  bool _isSaving = false;
  bool _newspaperSync = true;
  bool _editorialDeepDive = false;
  double _zenFocusLevel = 3.0;
  double _revisionCadence = 2.0;
  int _writingMode = 0;
  int _cycleStyle = 1;

  // Premium Theme Colors will now use Theme.of(context)
  late Color primary;
  late Color primaryContainer;
  late Color secondary;
  late Color background;
  late Color surface;
  late Color onSurface;
  late Color outlineVariant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    primary = colorScheme.primary;
    primaryContainer = colorScheme.primaryContainer;
    secondary = theme.textTheme.bodyMedium?.color ?? const Color(0xFF515F74);
    background = colorScheme.surface;
    surface = theme.cardColor;
    onSurface = colorScheme.onSurface;
    outlineVariant = theme.dividerColor;

    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          // Background accents
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.03),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroSection(),
                        const SizedBox(height: 32),
                        _buildBentoGrid(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildStickyActionDock(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: 0.5),
        border: Border(bottom: BorderSide(color: outlineVariant.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: primary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            'UPSC Mode Tuner',
            style: TextStyle(fontFamily: 'Lexend', fontSize: 20, fontWeight: FontWeight.w700, color: onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [primary, primaryContainer]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 8))],
          ),
          child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 32),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UPSC Mode Tuner',
                style: GoogleFonts.lexend(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: onSurface,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Configuring study architecture for maximum performance.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: secondary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBentoGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(flex: 3, child: _buildGridCell(title: 'Newsroom Sync', icon: Icons.newspaper_rounded, child: _buildNewsToggles())),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: _buildGridCell(title: 'Focus Level', icon: Icons.psychology_rounded, dark: true, child: _buildZenSlider())),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildGridCell(title: 'Revision', icon: Icons.history_rounded, child: _buildRevisionConfig())),
            const SizedBox(width: 16),
            Expanded(child: _buildGridCell(title: 'Writing', icon: Icons.edit_note_rounded, child: _buildWritingConfig())),
          ],
        ),
        const SizedBox(height: 16),
        _buildGridCell(title: 'Study Architecture', icon: Icons.architecture_rounded, child: _buildCycleSelector()),
      ],
    );
  }

  Widget _buildGridCell({required String title, required IconData icon, required Widget child, bool dark = false}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? onSurface : surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: outlineVariant.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: onSurface.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: dark ? primaryContainer : primary, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title, 
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: dark ? (theme.brightness == Brightness.dark ? Colors.black : Colors.white) : onSurface)
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildNewsToggles() {
    return Column(
      children: [
        _buildCompactToggle('Daily Sync', _newspaperSync, (v) => setState(() => _newspaperSync = v)),
        const SizedBox(height: 12),
        _buildCompactToggle('Editorial Plus', _editorialDeepDive, (v) => setState(() => _editorialDeepDive = v)),
      ],
    );
  }

  Widget _buildCompactToggle(String label, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        // No-Line Rule: Tonal definition
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label, 
              style: GoogleFonts.inter(
                fontSize: 13, 
                fontWeight: FontWeight.w700, 
                color: onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value, 
              activeTrackColor: primary.withValues(alpha: 0.2),
              activeThumbColor: primary, 
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZenSlider() {
    return Column(
      children: [
        Slider(
          value: _zenFocusLevel,
          min: 1, max: 3, divisions: 2,
          activeColor: primaryContainer,
          thumbColor: primaryContainer,
          inactiveColor: Colors.white24,
          onChanged: (v) => setState(() => _zenFocusLevel = v),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _tinyLabel('LOW'),
            _tinyLabel('MID'),
            _tinyLabel('ZEN'),
          ],
        ),
      ],
    );
  }

  Widget _tinyLabel(String text) => Text(text, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: onSurface.withValues(alpha: 0.5), letterSpacing: 1));

  Widget _buildRevisionConfig() {
    return Column(
      children: [
        Slider(
          value: _revisionCadence,
          min: 1, max: 3, divisions: 2,
          activeColor: primary,
          onChanged: (v) => setState(() => _revisionCadence = v),
        ),
        Text(
          _revisionCadence == 1 ? 'Hyper (3D)' : (_revisionCadence == 2 ? 'Standard' : 'Periodic'),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: primary),
        ),
      ],
    );
  }

  Widget _buildWritingConfig() {
    return Column(
      children: [
        _buildMinibutton('Mains Focus', _writingMode == 0, () => setState(() => _writingMode = 0)),
        const SizedBox(height: 8),
        _buildMinibutton('PYQ Analysis', _writingMode == 1, () => setState(() => _writingMode = 1)),
      ],
    );
  }

  Widget _buildMinibutton(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? primary : background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: active ? Colors.white : onSurface.withValues(alpha: 0.6))),
        ),
      ),
    );
  }

  Widget _buildCycleSelector() {
    return Row(
      children: [
        Expanded(child: _buildCycleTile('Monolithic', '15 days focus', _cycleStyle == 0, () => setState(() => _cycleStyle = 0))),
        const SizedBox(width: 12),
        Expanded(child: _buildCycleTile('Iterative', '3 subjects/day', _cycleStyle == 1, () => setState(() => _cycleStyle = 1))),
      ],
    );
  }

  Widget _buildCycleTile(String title, String subtitle, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: active ? primary.withValues(alpha: 0.05) : background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? primary : Colors.transparent),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: onSurface)),
            Text(subtitle, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: onSurface.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyActionDock() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: onSurface.withValues(alpha: 0.1), blurRadius: 40, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: _isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('LOCK CONFIGURATION', style: TextStyle(fontFamily: 'Lexend', fontWeight: FontWeight.w800, letterSpacing: 1)),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _resetSettings,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(24)),
              child: Icon(Icons.restart_alt_rounded, color: secondary, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  void _resetSettings() {
    setState(() {
      _newspaperSync = true;
      _editorialDeepDive = false;
      _zenFocusLevel = 3.0;
      _revisionCadence = 2.0;
      _writingMode = 0;
      _cycleStyle = 1;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Protocol Defaults Restored'), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final studyStyle = _cycleStyle == 0 ? 'balanced' : 'aggressive';
    final focusLevel = _zenFocusLevel == 3.0 ? 'deep' : (_zenFocusLevel == 2.0 ? 'medium' : 'relaxed');
    final revisionPref = _revisionCadence == 1.0 ? 'daily' : (_revisionCadence == 2.0 ? 'weekly' : 'alternate');
    
    int caWeight = 20;
    if (_newspaperSync) caWeight += 30;
    if (_editorialDeepDive) caWeight += 30;

    try {
      final success = await _api.updatePreferences(
        studyStyle: studyStyle,
        focusLevel: focusLevel,
        revisionPreference: revisionPref,
        currentAffairsWeight: caWeight,
      );
      
      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('UPSC Protocol Locked'), backgroundColor: Color(0xFF006847), behavior: SnackBarBehavior.floating),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to lock configuration'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }
}
