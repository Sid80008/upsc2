import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import '../services/schedule_service.dart';
import '../services/auth_service.dart';
import '../models/study_block.dart';
import 'focus_mode_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  // Theme Colors will now use Theme.of(context)
  late Color primary;
  late Color primaryFixed;
  late Color secondary;
  late Color tertiary;
  late Color background;
  late Color surface;
  late Color surfaceLowest;
  late Color surfaceLow;
  late Color onSurface;
  late Color onSurfaceVariant;
  late Color outlineVariant;

  final ScheduleService _api = ScheduleService();
  final AuthService _auth = AuthService();
  List<StudyBlock> _blocks = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadSchedule(_selectedDate);
  }

  Future<void> _loadSchedule(DateTime date) async {
    if (mounted) setState(() => _isLoading = true);
    final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
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

      final blocks = await _api.fetchDailySchedule(_userId!, dateStr);
      if (mounted) {
        setState(() {
          _blocks = blocks;
          _isLoading = false;
          _selectedDate = date;
        });
      }
    } catch (e) {
      debugPrint("Schedule Load Error: $e");
      if (mounted) {
        setState(() {
          _blocks = [];
          _isLoading = false;
          _selectedDate = date;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to sync schedule for this date.')),
        );
      }
    }
  }

  static final List<String> _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    primary = colorScheme.primary;
    primaryFixed = isDark ? colorScheme.primaryContainer : Color(0xFFD5E3FF);
    secondary = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ?? Color(0xFF515F74);
    tertiary = isDark ? colorScheme.tertiary : Color(0xFF006847);
    background = colorScheme.surface;
    surface = isDark ? colorScheme.surfaceContainerHighest : Color(0xFFF7F9FB);
    surfaceLowest = theme.cardColor;
    surfaceLow = isDark ? colorScheme.surfaceContainer : Color(0xFFF2F4F6);
    onSurface = colorScheme.onSurface;
    onSurfaceVariant = colorScheme.onSurfaceVariant;
    outlineVariant = theme.dividerColor;

    return Scaffold(
      backgroundColor: surface,
      appBar: _buildAppBar(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primary))
          : ListView(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 100),
              children: [
                _buildHeader(),
                SizedBox(height: 32),
                _buildHorizontalCalendar(),
                SizedBox(height: 32),
                _buildTimelineList(),
                SizedBox(height: 32),
                _buildInsightsBento(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: CircleBorder(),
        elevation: 8,
        child: Icon(Icons.add),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final theme = Theme.of(context);
    return AppBar(
      backgroundColor: surfaceLow,
      elevation: 0,
      scrolledUnderElevation: 4,
      shadowColor: theme.shadowColor.withValues(alpha: 0.1),
      title: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.architecture_rounded, color: Color(0xFF1173D4), size: 20),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Academic Architect',
                  style: GoogleFonts.lexend(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1173D4),
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.notifications, color: secondary),
          onPressed: () {},
        ),
        GestureDetector(
          onTap: () {},
          child: Container(
            margin: EdgeInsets.only(right: 16, left: 8),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: primaryFixed,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text('JD', style: TextStyle(color: Color(0xFF001B3C), fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'UPSC MASTER PLAN',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: secondary,
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Daily Sprint',
          style: GoogleFonts.lexend(
            fontSize: 42,
            fontWeight: FontWeight.w800,
            color: onSurface,
            letterSpacing: -1.0,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalCalendar() {
    final today = DateTime.now();
    final List<DateTime> calendarDates = List.generate(14, (i) => today.subtract(Duration(days: 7 - i)));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: calendarDates.map((date) {
          final isSelected = date.year == _selectedDate.year &&
              date.month == _selectedDate.month &&
              date.day == _selectedDate.day;
          
          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => _loadSchedule(date),
              borderRadius: BorderRadius.circular(16),
              child: _buildDayItem(_months[date.month - 1], date.day.toString(), isSelected),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDayItem(String month, String date, bool isSelected) {
    return Container(
      width: 70,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? primary : surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isSelected
            ? [BoxShadow(color: primary.withValues(alpha: 0.2), blurRadius: 12, offset: Offset(0, 4))]
            : [],
      ),
      child: Column(
        children: [
          Text(
            month.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white.withValues(alpha: 0.8) : secondary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            date,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          if (isSelected) ...[
            SizedBox(height: 8),
            Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          ]
        ],
      ),
    );
  }

  Widget _buildTimelineList() {
    if (_blocks.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Text("No tasks scheduled for today.", style: TextStyle(color: secondary)),
        ),
      );
    }

    return Stack(
      children: [
        // Vertical connector line
        Positioned(
          left: 23,
          top: 16,
          bottom: 16,
          child: Container(
            width: 1,
            color: outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        Column(
          children: _blocks.map((b) => _buildTimelineBlock(b)).toList(),
        ),
      ],
    );
  }
  Widget _buildTimelineBlock(StudyBlock block) {
    final bool isCompleted = block.status == 'completed';
    // markerColor was used for the side border, now using tonal layering
    final bool isOngoing = block.status == 'ongoing' || block.status == 'pending';
    final bool isUpcoming = block.status == 'upcoming' || block.status == 'missed';
    Color bgColor = isCompleted
        ? tertiary.withValues(alpha: 0.1)
        : (isOngoing ? primary : surfaceLow);
    IconData icon = isCompleted ? Icons.check_circle : (isOngoing ? Icons.play_arrow : Icons.lock);

    return Padding(
      padding: EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Marker
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              boxShadow: isOngoing ? [BoxShadow(color: primary.withValues(alpha: 0.2), blurRadius: 10)] : [],
            ),
            child: Icon(
              icon,
              color: isCompleted ? tertiary : (isOngoing ? Colors.white : secondary),
            ),
          ),
          SizedBox(width: 16),
          // Content Card
          Expanded(
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isOngoing ? surfaceLowest : (isUpcoming ? surfaceLow.withValues(alpha: 0.5) : surfaceLowest),
                borderRadius: BorderRadius.circular(20),
                // No-Line Rule: Using tonal depth instead of solid borders
                boxShadow: isOngoing 
                  ? [BoxShadow(color: primary.withValues(alpha: 0.08), offset: Offset(0, 20), blurRadius: 40, spreadRadius: -8)]
                  : [BoxShadow(color: Color(0x0A191C1E), offset: Offset(0, 12), blurRadius: 32, spreadRadius: -4)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.schedule, size: 14, color: secondary),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${block.startTime} - ${block.endTime} ${isOngoing ? '(Ongoing)' : ''}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isOngoing ? primary : secondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              block.subject,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isUpcoming ? onSurfaceVariant : onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (block.rescheduledFromId != null) ...[
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.history_rounded, size: 12, color: primary),
                                  SizedBox(width: 4),
                                  Text(
                                    'RESCHEDULED',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: primary,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isOngoing ? Color(0xFFD5E3FC) : surfaceLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          (block.topic ?? 'General').toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isOngoing ? Color(0xFF57657A) : onSurfaceVariant,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isOngoing) ...[
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Session Progress', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: secondary)),
                        Text('0%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primary)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: primaryFixed,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8, // 0 progress mock
                            height: 8,
                            decoration: BoxDecoration(
                              color: primary,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.4), blurRadius: 12)],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 8,
                          shadowColor: primary.withValues(alpha: 0.2),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FocusModeScreen(
                                blockId: block.id,
                                subject: block.subject,
                                topic: block.topic ?? 'General',
                                plannedMinutes: block.durationMinutes,
                              ),
                            ),
                          );
                        },
                        icon: Icon(Icons.play_arrow),
                        label: Text('Start Focus', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                  if (isUpcoming) ...[
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: outlineVariant.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: secondary, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Will unlock after current session completion.',
                              style: TextStyle(fontSize: 12, color: secondary, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (isCompleted) ...[
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Session Completed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: tertiary)),
                        Text('View Notes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primary)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsBento() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PERFORMANCE RADIUS',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: secondary,
            letterSpacing: 2.0,
          ),
        ),
        SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            bool isWide = constraints.maxWidth > 600;
            return isWide 
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildEfficiencyCard()),
                      SizedBox(width: 20),
                      Expanded(flex: 2, child: _buildArchitectTipsCard()),
                    ],
                  )
                : Column(
                    children: [
                      _buildEfficiencyCard(),
                      SizedBox(height: 20),
                      _buildArchitectTipsCard(),
                    ],
                  );
          },
        ),
      ],
    );
  }

  Widget _buildEfficiencyCard() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Color(0x0F191C1E), offset: Offset(0, 12), blurRadius: 32, spreadRadius: -4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily Efficiency', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface)),
          SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(value: 1.0, strokeWidth: 8, color: primaryFixed),
                    CircularProgressIndicator(value: 0.82, strokeWidth: 8, color: primary, strokeCap: StrokeCap.round),
                    Center(child: Text('82%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              SizedBox(width: 24),
              Expanded(
                child: Text(
                  'You are 12% ahead of your targets for October. Consistency is key!',
                  style: TextStyle(fontSize: 12, color: secondary, height: 1.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArchitectTipsCard() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFF1173D4),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.2), offset: Offset(0, 12), blurRadius: 32, spreadRadius: -4)],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -24,
            bottom: -24,
            child: Icon(Icons.lightbulb, size: 100, color: Colors.white.withValues(alpha: 0.1)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Architect\'s Tip', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(height: 8),
              Text(
                'Modern History focuses heavily on Chronology. Try creating a visual timeline for the 1857 era today.',
                style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9), height: 1.5, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('LEARN MORE', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
