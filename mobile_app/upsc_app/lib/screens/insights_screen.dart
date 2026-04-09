import 'package:flutter/material.dart';
import '../services/insights_service.dart';
import '../services/schedule_service.dart';
import '../services/auth_service.dart';
import '../models/user_signals.dart';

class InsightsScreen extends StatefulWidget {
  final VoidCallback? onBackHome;
  const InsightsScreen({super.key, this.onBackHome});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final InsightsService _insights = InsightsService();
  final ScheduleService _api = ScheduleService();
  final AuthService _auth = AuthService();

  Map<String, dynamic>? _summary;
  Map<String, dynamic>? _subjectStats;
  UserSignals? _signals;
  List<double> _weeklyRhythm = [];
  bool _isLoading = true;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    try {
      _userId ??= await _auth.getUserId();
      if (_userId == null) {
        final profile = await _auth.getProfile();
        _userId = profile?['id'];
      }

      if (_userId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final finalUserId = _userId!;
      final results = await Future.wait([
        _insights.fetchSummary(finalUserId),
        _insights.fetchSubjectStats(finalUserId),
        _api.fetchSignals(finalUserId),
        _insights.fetchWeeklyRhythm(finalUserId),
      ]);

      if (mounted) {
        setState(() {
          _summary = results[0] as Map<String, dynamic>;
          _subjectStats = results[1] as Map<String, dynamic>;
          _signals = results[2] as UserSignals;
          _weeklyRhythm = results[3] as List<double>;
          _isLoading = false;
        });
      }
    } catch (e) {
      // debugPrint("Insights Load Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }
  // Premium Theme Colors will now use Theme.of(context)
  late Color primary;
  late Color primaryContainer;
  late Color secondary;
  late Color background;
  late Color surface;
  late Color onSurface;
  late Color success;
  late Color outlineVariant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    primary = colorScheme.primary;
    primaryContainer = colorScheme.primaryContainer;
    secondary = theme.textTheme.bodyMedium?.color ?? const Color(0xFF515F74);
    background = theme.scaffoldBackgroundColor;
    surface = theme.cardColor;
    onSurface = colorScheme.onSurface;
    success = const Color(0xFF10B981);
    outlineVariant = colorScheme.outlineVariant;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfessionalHeader(),
                  const SizedBox(height: 32),
                  _buildModernSummaryCard(),
                  const SizedBox(height: 24),
                  if (_signals?.weakSubjects.isNotEmpty ?? false)
                    _buildTrajectoryWarning(),
                  if (_weeklyRhythm.any((v) => v > 0)) ...[
                    const SizedBox(height: 48),
                    _buildSectionHeader(context, 'Weekly Rhythm', 'Full Report'),
                    const SizedBox(height: 16),
                    _buildWeeklyChart(),
                  ],
                  const SizedBox(height: 48),
                  _buildSectionHeader(context, 'Subject Performance', 'View All'),
                  const SizedBox(height: 16),
                  _buildSubjectStats(),
                  const SizedBox(height: 48),
                  _buildSectionHeader(context, 'Intelligence Briefing', 'History'),
                  const SizedBox(height: 16),
                  _buildCognitiveReview(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildProfessionalHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.onBackHome != null)
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: primary),
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            onPressed: widget.onBackHome,
          ),
        Text(
          'ANALYTICS',
          style: TextStyle(
            fontFamily: 'Lexend',
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 4.0,
            color: primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Performance Insights',
          style: TextStyle(
            fontFamily: 'Lexend',
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
            color: onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildModernSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: outlineVariant.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: onSurface.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildCompactIndicator('Accuracy', '${((_summary?['consistency_score'] ?? 0.0) * 100).toInt()}%', Icons.auto_awesome, success),
          ),
          Container(height: 40, width: 1, color: outlineVariant.withValues(alpha: 0.1)),
          Expanded(
            child: _buildCompactIndicator('Streak', '${_summary?['current_streak_days'] ?? 0}d', Icons.local_fire_department_rounded, const Color(0xFFF97316)),
          ),
          Container(height: 40, width: 1, color: outlineVariant.withValues(alpha: 0.1)),
          Expanded(
            child: _buildCompactIndicator('XP Rank', 'Top 5%', Icons.bolt_rounded, Colors.amber),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Lexend',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: onSurface,
          ),
        ),
        TextButton(
          onPressed: () {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Cognitive Report: Data Synthesis in Progress...'), backgroundColor: primary)
            );
          },
          child: Text(
            action,
            style: TextStyle(
              color: primary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactIndicator(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: onSurface)),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: secondary.withValues(alpha: 0.4))),
      ],
    );
  }

  Widget _buildWeeklyChart() {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final values = _weeklyRhythm;
    if (values.length < 7) return const SizedBox();
    
    // Find max to scale relatively
    double maxVal = values.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) maxVal = 1;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) => Column(
              children: [
                Container(
                  width: 32,
                  height: 120 * (values[i] / maxVal),
                  decoration: BoxDecoration(
                    color: i == 3 ? primary : primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  days[i],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: i == 3 ? onSurface : secondary.withValues(alpha: 0.4),
                  ),
                ),
              ],
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectStats() {
    final stats = _subjectStats ?? {};
    if (stats.isEmpty) return const SizedBox();
    
    return Column(
      children: stats.entries.map((e) {
        final double score = (e.value as num).toDouble();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildSubjectRow(e.key, score, _getColorForScore(score)),
        );
      }).toList(),
    );
  }

  Color _getColorForScore(double score) {
    if (score >= 0.8) return success;
    if (score >= 0.6) return primary;
    return const Color(0xFFF97316);
  }

  Widget _buildTrajectoryWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF97316).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFF97316)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Drift Detected: ${_signals?.weakSubjects.join(", ")} needs attention to maintain trajectory.',
              style: const TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCognitiveReview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_rounded, color: primary, size: 28),
              const SizedBox(width: 12),
              const Text('Cognitive Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Your behavioral fingerprint shows high ${(_signals?.consistencyScore ?? 0) > 0.8 ? "resilience" : "variability"} in evening slots. '
            'The engine suggests focusing on ${_signals?.weakSubjects.first ?? "Current Subjects"} to balance week-over-week performance.',
            style: TextStyle(color: onSurface.withValues(alpha: 0.7), fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectRow(String title, double progress, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: onSurface)),
              Text('${(progress * 100).toInt()}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  // _buildBadgesRow used to be here, but was removed as it was unreferenced in the UI.
}
