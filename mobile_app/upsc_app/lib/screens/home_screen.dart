import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/schedule_service.dart';
import '../services/auth_service.dart';
import '../services/insights_service.dart';
import '../models/study_block.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';
import 'focus_mode_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScheduleService _api = ScheduleService();
  final AuthService _auth = AuthService();
  final InsightsService _insights = InsightsService();
  bool _isLoading = true;
  int? _userId; // Added
  List<StudyBlock> _blocks = [];
  StudyBlock? _upNext;
  int _completedMinutes = 0;
  int _totalMinutes = 420;
  Map<String, dynamic>? _summary;
  List<dynamic> _news = []; // Added

  // Premium Theme Colors
  // Premium Theme Colors will now use Theme.of(context) for dynamic switching
  late Color primary;
  late Color primaryContainer;
  late Color secondary;
  late Color surface;
  late Color onSurface;
  late Color outlineVariant;

  @override
  void initState() {
    super.initState();
    _loadProfile(); // Added
    _loadData();
  }

  Future<void> _loadProfile() async {
    final profile = await _auth.getProfile();
    if (profile != null && mounted) {
       setState(() {
         _userId = profile['id'];
       });
    }
  }

  Future<void> _loadData() async {
    try {
      _userId ??= await _auth.getUserId();
      if (_userId == null) {
        final profile = await _auth.getProfile();
        _userId = profile?['id'];
      }

      if (_userId == null && mounted) {
        setState(() => _isLoading = false);
        return;
      }

      final finalUserId = _userId!;
      final todayStr = DateTime.now().toIso8601String().split('T')[0];

      // Parallel fetch for speed
      final results = await Future.wait([
        _api.fetchDailySchedule(finalUserId, todayStr),
        _insights.fetchSummary(finalUserId),
        _api.fetchNews(),
      ]);

      final List<StudyBlock> blocks = results[0] as List<StudyBlock>;
      final Map<String, dynamic> summary = results[1] as Map<String, dynamic>;
      final List<dynamic> news = results[2] as List<dynamic>;
      
      if (mounted) {
        setState(() {
          _news = news;
          _blocks = blocks;
          _summary = summary;
          
          // Calculate minutes correctly from real blocks
          _completedMinutes = _blocks
              .where((b) => b.status == 'completed')
              .fold(0, (sum, b) => sum + b.durationMinutes);
          _totalMinutes = _blocks.fold(0, (sum, b) => sum + b.durationMinutes);
          if (_totalMinutes == 0) _totalMinutes = 420;

          _upNext = null;
          for (var b in _blocks) {
            if (b.status == 'pending' || b.status == 'ongoing') {
              _upNext = b;
              break;
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      // debugPrint("Home Load Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not sync with War Room backend.')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _startFocusMode() {
    if (_upNext == null) return;
    
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (_) => FocusModeScreen(
          blockId: _upNext!.id,
          subject: _upNext!.subject,
          topic: _upNext!.topic ?? 'General',
          plannedMinutes: _upNext!.durationMinutes,
        )
      )
    ).then((_) => _loadData());
  }

  void _finalizeDay() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('FINALIZE WAR ROOM', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        content: const Text('Are you sure you want to lock today\'s progress? This will generate your performance synthesis.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('SYNTHESIZE')),
        ],
      ),
    );

    if (confirmed == true && _userId != null) { // Ensure _userId is not null
      setState(() => _isLoading = true);
      final success = await _api.submitDailyReport(
        userId: _userId!,
        date: DateTime.now().toIso8601String().split('T')[0],
        focusRating: 5,
        blocks: _blocks.map((b) => {
          'block_id': b.id,
          'status': b.status,
          'completion_percent': b.completionPercent,
          'time_spent_minutes': b.timeSpentMinutes,
        }).toList(),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Day Synthesized: Progress Locked'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Synthesis Failed. Sync connection interrupted.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    primary = colorScheme.primary;
    primaryContainer = colorScheme.primaryContainer;
    secondary = theme.textTheme.bodyMedium?.color ?? const Color(0xFF515F74);
    surface = colorScheme.surface;
    onSurface = colorScheme.onSurface;
    outlineVariant = theme.dividerColor;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: surface,
        body: Center(child: CircularProgressIndicator(color: primary)),
      );
    }

    double focusIntensity = (_completedMinutes / _totalMinutes).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildModernSummaryCard(focusIntensity),
              const SizedBox(height: 32),
              _buildStatusRow(),
              const SizedBox(height: 32), // Added
              _buildNewsSection(), // Added
              const SizedBox(height: 48),
              if (_upNext != null) ...[
                _buildSectionHeader('Up Next'),
                const SizedBox(height: 16),
                _buildUpNextCard(),
                const SizedBox(height: 48),
              ],
              _buildSectionHeader('Synchronization Log'),
              const SizedBox(height: 16),
              _buildActivityList(),
              const SizedBox(height: 32),
              _buildFinalizeButton(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinalizeButton() {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primary, const Color(0xFF1E293B)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: ElevatedButton(
        onPressed: _finalizeDay,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: const Text('FINALIZE WAR ROOM', style: TextStyle(fontFamily: 'Lexend', fontWeight: FontWeight.w800, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildModernSummaryCard(double intensity) {
    int percentage = (intensity * 100).toInt();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Progress',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$percentage%',
                style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: -2),
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    _summary?['countdown_mode'] != null 
                        ? "MODE: ${_summary!['countdown_mode'].toUpperCase()}" 
                        : 'UPSC Prelims focus',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(5)),
              ),
              FractionallySizedBox(
                widthFactor: intensity,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_completedMinutes / $_totalMinutes min',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w600),
              ),
              if (_upNext != null)
                Flexible(
                  child: Text(
                    'Next: ${_upNext!.subject}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow() {
    // Summary metrics derived from _summary
    return Row(
      children: [
        Expanded(child: _buildSmallStatusCard(Icons.local_fire_department_rounded, '${_summary?['current_streak_days'] ?? 0} Days', 'Streak', const Color(0xFFF97316))),
        const SizedBox(width: 12),
        Expanded(child: _buildSmallStatusCard(Icons.auto_awesome, '${(_summary?['consistency_score'] ?? 0.0 * 100).toInt()}%', 'Accuracy', Colors.amber)),
        const SizedBox(width: 12),
        Expanded(child: _buildSmallStatusCard(Icons.task_alt_rounded, '${(_blocks.where((b)=>b.status == 'pending').length)} Units', 'Pending', primary)),
      ],
    );
  }

  Widget _buildSmallStatusCard(IconData icon, String value, String label, Color color) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final outlineVariant = colorScheme.outlineVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: onSurface), textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: secondary.withValues(alpha: 0.6)), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildUpNextCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primary;
    final onSurface = colorScheme.onSurface;
    final outlineVariant = colorScheme.outlineVariant;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.auto_awesome_rounded, color: primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Suggested sequence for now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
              const Spacer(),
              _buildPulseIndicator(),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _upNext!.subject,
            style: TextStyle(color: onSurface, fontSize: 24, fontWeight: FontWeight.w800, fontFamily: 'Lexend'),
          ),
          const SizedBox(height: 4),
          Text(
            _upNext!.topic ?? 'General Focus',
            style: TextStyle(color: secondary.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.timer_outlined, color: secondary, size: 16),
                  const SizedBox(width: 6),
                  Text('${_upNext!.durationMinutes} min', style: TextStyle(color: secondary, fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _startFocusMode,
                icon: const Icon(Icons.play_arrow_rounded, size: 20, color: Colors.white),
                label: const Text('Start Focus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(backgroundColor: primary, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HOME',
              style: TextStyle(
                fontFamily: 'Lexend',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 4.0,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'User: ARCHITECT_0${_summary?['user_id'] ?? 1}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        _buildHeaderActions(),
      ],
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      children: [
        _buildRoundIcon(Icons.notifications_outlined, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
        }),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [primary, primaryContainer]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: const Center(
              child: Text(
                'A',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoundIcon(IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final secondary = theme.textTheme.bodyMedium?.color ?? const Color(0xFF515F74);
    final outlineVariant = colorScheme.outlineVariant;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Icon(icon, size: 22, color: secondary),
        ),
      ),
    );
  }


  Widget _buildPulseIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF006847).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF006847).withValues(alpha: 0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 6, color: Color(0xFF00C853)),
          SizedBox(width: 6),
          Text('LIVE', style: TextStyle(color: Color(0xFF00C853), fontSize: 10, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Lexend',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
    );
  }

  Widget _buildActivityList() {
    return Column(
      children: _blocks.map((block) => _buildActivityItem(block)).toList(),
    );
  }

  Widget _buildActivityItem(StudyBlock block) {
    final theme = Theme.of(context);
    final outlineVariant = theme.colorScheme.outlineVariant;
    bool isCompleted = block.status == 'completed';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isCompleted ? const Color(0xFF10B981) : secondary).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCompleted ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
              color: isCompleted ? const Color(0xFF10B981) : secondary.withValues(alpha: 0.5),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block.subject,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  block.topic ?? 'General',
                  style: TextStyle(fontSize: 12, color: secondary.withValues(alpha: 0.5), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: outlineVariant.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(
              '${block.durationMinutes}m',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: onSurface.withValues(alpha: 0.7)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsSection() {
    if (_news.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Intelligence Briefing'),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _news.length,
            clipBehavior: Clip.none,
            itemBuilder: (context, index) {
              final item = _news[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item['category']?.toUpperCase() ?? 'GENERAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: primary,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item['title'] ?? 'No Title',
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 14, color: secondary.withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        Text(
                          'Just now',
                          style: TextStyle(
                            fontSize: 11,
                            color: secondary.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
