import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  // New Theme Colors
  static const Color primary = Color(0xFF005AAB);
  static const Color primaryFixed = Color(0xFFD5E3FF);
  static const Color secondary = Color(0xFF515F74);
  static const Color surface = Color(0xFFF7F9FB);
  static const Color surfaceLowest = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF191C1E);
  static const Color outlineVariant = Color(0xFFC1C6D4);

  // Form Data
  String _selectedExam = 'UPSC CSE 2025';
  double _hoursPerDay = 6.0;
  String _targetYear = '2025';
  String _proficiency = 'Beginner';
  final Set<String> _coveredSubjects = {};
  
  final List<String> _allSubjects = [
    'Polity', 'Modern History', 'Ancient & Medieval History', 
    'Geography', 'Economy', 'Environment', 'Science & Tech', 'Art & Culture'
  ];

  void _completeOnboarding() async {
    setState(() => _isLoading = true);
    
    final payload = {
      'name': 'UPSC Aspirant', // Placeholder or fetch from profile
      'exam_date': '$_targetYear-06-01', // Defaulting to June for UPSC
      'daily_study_hours': _hoursPerDay.toInt(),
      'selected_subjects': _coveredSubjects.toList(),
      'preferred_study_time': 'morning', // Default, could be made selectable
      'difficulty_preference': _proficiency == 'Beginner' ? 'light' : (_proficiency == 'Advanced' ? 'heavy' : 'medium'),
    };

    final success = await AuthService().setupUser(payload);
    
    setState(() => _isLoading = false);
    
    if (success && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
        (route) => false
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save profile. Please try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressBar(),
            Expanded(
              child: IndexedStack(
                index: _currentStep,
                children: [
                  _buildStep1Welcome(),
                  _buildStep2Goals(),
                  _buildStep3Background(),
                ],
              ),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(child: _buildProgressSegment(0)),
          const SizedBox(width: 8),
          Expanded(child: _buildProgressSegment(1)),
          const SizedBox(width: 8),
          Expanded(child: _buildProgressSegment(2)),
        ],
      ),
    );
  }

  Widget _buildProgressSegment(int stepIndex) {
    bool isCompleted = _currentStep > stepIndex;
    bool isActive = _currentStep == stepIndex;
    
    Color color = surfaceLowest;
    if (isCompleted || isActive) {
      color = primary;
    } else {
      color = outlineVariant.withValues(alpha: 0.3);
    }
    
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceLowest,
        border: Border(top: BorderSide(color: outlineVariant.withValues(alpha: 0.2))),
        boxShadow: const [BoxShadow(color: Color(0x05191C1E), offset: Offset(0, -4), blurRadius: 16)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            TextButton(
              onPressed: () => setState(() => _currentStep--),
              child: const Text('Back', style: TextStyle(color: secondary, fontWeight: FontWeight.bold)),
            )
          else
            const SizedBox(width: 64), // Invisible placeholder
          
          ElevatedButton(
            onPressed: _isLoading ? null : () {
              if (_currentStep < 2) {
                setState(() => _currentStep++);
              } else {
                _completeOnboarding();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            child: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_currentStep < 2 ? 'Continue' : 'Start Journey', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1Welcome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: primaryFixed, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.account_balance, color: primary, size: 32),
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to Academic Architect', 
            style: GoogleFonts.lexend(
              fontSize: 32, 
              fontWeight: FontWeight.w800, 
              color: onSurface, 
              height: 1.2, 
              letterSpacing: -1.0,
            )
          ),
          const SizedBox(height: 12),
          Text(
            'Your journey to LBSNAA begins here. Let\'s set up your personalized study environment.', 
            style: GoogleFonts.inter(
              fontSize: 16, 
              color: secondary, 
              height: 1.5,
            )
          ),
          const SizedBox(height: 48),
          const Text('SELECT YOUR PRIMARY GOAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: secondary, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          _buildRadioCard('UPSC CSE 2025', 'Targeting the Preliminary Exam in 2025', Icons.flag),
          const SizedBox(height: 12),
          _buildRadioCard('UPSC CSE 2026', 'Long-term comprehensive preparation', Icons.timeline),
          const SizedBox(height: 12),
          _buildRadioCard('State PSC', 'Targeting state-level civil services', Icons.map),
        ],
      ),
    );
  }

  Widget _buildRadioCard(String title, String subtitle, IconData icon) {
    bool isSelected = _selectedExam == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedExam = title),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? primaryFixed.withValues(alpha: 0.3) : surfaceLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? primary : outlineVariant.withValues(alpha: 0.3), width: isSelected ? 2 : 1),
          boxShadow: isSelected ? [BoxShadow(color: primary.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: isSelected ? primary : surface, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: isSelected ? Colors.white : secondary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isSelected ? primary : onSurface)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: secondary, fontSize: 13)),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? primary : outlineVariant, width: 2),
                color: isSelected ? primary : Colors.transparent,
              ),
              child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2Goals() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'Define Your Commitment', 
            style: GoogleFonts.lexend(
              fontSize: 32, 
              fontWeight: FontWeight.w800, 
              color: onSurface, 
              height: 1.2, 
              letterSpacing: -1.0,
            )
          ),
          const SizedBox(height: 12),
          Text(
            'Consistency is key to clearing UPSC. Tell us how much time you can realistically dedicate each day.', 
            style: GoogleFonts.inter(
              fontSize: 16, 
              color: secondary, 
              height: 1.5,
            )
          ),
          const SizedBox(height: 48),
          
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: surfaceLowest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: outlineVariant.withValues(alpha: 0.2)),
              boxShadow: const [BoxShadow(color: Color(0x0F191C1E), offset: Offset(0, 12), blurRadius: 32)],
            ),
            child: Column(
              children: [
                const Text('I can study', style: TextStyle(fontSize: 16, color: secondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('${_hoursPerDay.toInt()}', style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: primary, letterSpacing: -2)),
                    const SizedBox(width: 8),
                    const Text('Hours/Day', style: TextStyle(fontSize: 20, color: primary, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 32),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: primary,
                    inactiveTrackColor: primaryFixed,
                    thumbColor: primary,
                    overlayColor: primary.withValues(alpha: 0.1),
                    trackHeight: 8,
                  ),
                  child: Slider(
                    value: _hoursPerDay,
                    min: 2,
                    max: 14,
                    divisions: 12,
                    onChanged: (val) => setState(() => _hoursPerDay = val),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('2 hrs', style: TextStyle(color: secondary, fontWeight: FontWeight.bold)),
                    Text('14 hrs', style: TextStyle(color: secondary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Target Year', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: secondary, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => setState(() => _targetYear = v),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'e.g. 2025',
              filled: true,
              fillColor: surfaceLowest,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: outlineVariant.withValues(alpha: 0.3))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: outlineVariant.withValues(alpha: 0.3))),
              prefixIcon: const Icon(Icons.calendar_month, color: secondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Background() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'Your Study Background', 
            style: GoogleFonts.lexend(
              fontSize: 32, 
              fontWeight: FontWeight.w800, 
              color: onSurface, 
              height: 1.2, 
              letterSpacing: -1.0,
            )
          ),
          const SizedBox(height: 12),
          Text(
            'Help us understand your current standing so we can tailor the initial phase of your schedule.', 
            style: GoogleFonts.inter(
              fontSize: 16, 
              color: secondary, 
              height: 1.5,
            )
          ),
          const SizedBox(height: 48),
          
          const Text('WHAT LIKELY BEST DESCRIBES YOU?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: secondary, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildProficiencyCard('Beginner', 'Starting fresh'),
              const SizedBox(width: 12),
              _buildProficiencyCard('Intermediate', 'Basics cleared'),
              const SizedBox(width: 12),
              _buildProficiencyCard('Advanced', 'Revision mode'),
            ],
          ),
          
          const SizedBox(height: 40),
          const Text('SUBJECTS YOU HAVE COVERED', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: secondary, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _allSubjects.map((s) {
              final isSelected = _coveredSubjects.contains(s);
              return FilterChip(
                label: Text(s, style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? primary : secondary)),
                selected: isSelected,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _coveredSubjects.add(s);
                    } else {
                      _coveredSubjects.remove(s);
                    }
                  });
                },
                backgroundColor: surfaceLowest,
                selectedColor: primaryFixed,
                checkmarkColor: primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: isSelected ? primary : outlineVariant.withValues(alpha: 0.5)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProficiencyCard(String title, String subtitle) {
    bool isSelected = _proficiency == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _proficiency = title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? primary : surfaceLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? primary : outlineVariant.withValues(alpha: 0.3)),
            boxShadow: isSelected ? [BoxShadow(color: primary.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))] : [],
          ),
          child: Column(
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isSelected ? Colors.white : onSurface)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white.withValues(alpha: 0.8) : secondary), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
