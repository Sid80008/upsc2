import 'package:flutter/material.dart';

class PremiumInsightsScreen extends StatelessWidget {
  const PremiumInsightsScreen({super.key});

  static const Color primary = Color(0xFF005AAB);
  static const Color primaryFixed = Color(0xFFD5E3FF);
  static const Color secondary = Color(0xFF515F74);
  static const Color tertiary = Color(0xFF006847);
  static const Color surface = Color(0xFFF7F9FB);
  static const Color surfaceLowest = Color(0xFFFFFFFF);
  static const Color surfaceLow = Color(0xFFF2F4F6);
  static const Color onSurface = Color(0xFF191C1E);
  static const Color outlineVariant = Color(0xFFC1C6D4);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: surface,
        appBar: AppBar(
          backgroundColor: surfaceLow,
          elevation: 0,
          scrolledUnderElevation: 4,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1173D4)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Performance Insights', style: TextStyle(color: Color(0xFF1173D4), fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
          bottom: TabBar(
            labelColor: primary,
            unselectedLabelColor: secondary,
            indicatorColor: primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            dividerColor: outlineVariant.withValues(alpha: 0.2),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Subjects'),
              Tab(text: 'Consistency'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _OverviewTab(),
            _SubjectsTab(),
            _ConsistencyTab(),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: PremiumInsightsScreen.surfaceLow, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: PremiumInsightsScreen.surfaceLowest,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [BoxShadow(color: Color(0x05191C1E), blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: const Text('Last 7 Days', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: PremiumInsightsScreen.primary)),
                  ),
                ),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text('Last 30 Days', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, color: PremiumInsightsScreen.secondary, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Stats Row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: PremiumInsightsScreen.primary,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: PremiumInsightsScreen.primary.withValues(alpha: 0.2), blurRadius: 24, offset: const Offset(0, 12))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AVG. COMPLETION', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const Text('92', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: -1.0)),
                          Text('%', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.trending_up, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text('4.2% vs last week', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: PremiumInsightsScreen.surfaceLowest,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [BoxShadow(color: Color(0x0F191C1E), blurRadius: 32, offset: Offset(0, 12))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('MISSED RATE', style: TextStyle(color: PremiumInsightsScreen.secondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const Text('8', style: TextStyle(color: PremiumInsightsScreen.onSurface, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: -1.0)),
                          Text('%', style: TextStyle(color: PremiumInsightsScreen.secondary.withValues(alpha: 0.5), fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Icon(Icons.trending_down, color: PremiumInsightsScreen.tertiary, size: 14),
                          SizedBox(width: 4),
                          Text('-1.5% improvement', style: TextStyle(color: PremiumInsightsScreen.tertiary, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Weekly Chart UI
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: PremiumInsightsScreen.surfaceLowest,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(color: Color(0x0F191C1E), offset: Offset(0, 12), blurRadius: 32, spreadRadius: -4)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Weekly Performance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PremiumInsightsScreen.onSurface)),
                        SizedBox(height: 4),
                        Text('Tasks completed per day', style: TextStyle(fontSize: 12, color: PremiumInsightsScreen.secondary)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: PremiumInsightsScreen.primaryFixed.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.bar_chart, color: PremiumInsightsScreen.primary, size: 20),
                    )
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 160,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBar('M', 0.7),
                      _buildBar('T', 0.85),
                      _buildBar('W', 0.6),
                      _buildBar('T', 0.95, isToday: true),
                      _buildBar('F', 0.8),
                      _buildBar('S', 0.45),
                      _buildBar('S', 0.3),
                    ],
                  ),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Action Suggestion
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1173D4), // Premium highlight
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: PremiumInsightsScreen.primary.withValues(alpha: 0.2), offset: const Offset(0, 12), blurRadius: 32)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.yellow.shade400, size: 20),
                    const SizedBox(width: 8),
                    const Text('Weekly Tip', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Text('You are most productive between 9:00 AM and 11:00 AM. Try scheduling high-focus tasks during this window.', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, height: 1.5)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, 
                      foregroundColor: PremiumInsightsScreen.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    child: const Text('Optimize Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String label, double fillPct, {bool isToday = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            width: 32,
            decoration: BoxDecoration(
              color: PremiumInsightsScreen.surfaceLow, 
              borderRadius: BorderRadius.circular(8)
            ),
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: fillPct,
              child: Container(
                decoration: BoxDecoration(
                  color: isToday ? PremiumInsightsScreen.primary : PremiumInsightsScreen.primary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isToday ? [BoxShadow(color: PremiumInsightsScreen.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: isToday ? FontWeight.bold : FontWeight.w600, color: isToday ? PremiumInsightsScreen.onSurface : PremiumInsightsScreen.secondary)),
      ],
    );
  }
}

class _SubjectsTab extends StatelessWidget {
  const _SubjectsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: PremiumInsightsScreen.surfaceLowest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: PremiumInsightsScreen.tertiary.withValues(alpha: 0.2), width: 2),
                    boxShadow: const [BoxShadow(color: Color(0x05191C1E), offset: Offset(0, 12), blurRadius: 24)],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.arrow_upward, color: PremiumInsightsScreen.tertiary, size: 14),
                          SizedBox(width: 4),
                          Text('TOP STRENGTH', style: TextStyle(color: PremiumInsightsScreen.tertiary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text('Polity', style: TextStyle(color: PremiumInsightsScreen.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('92% coverage', style: TextStyle(color: PremiumInsightsScreen.secondary, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: PremiumInsightsScreen.surfaceLowest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFBA1A1A).withValues(alpha: 0.2), width: 2),
                    boxShadow: const [BoxShadow(color: Color(0x05191C1E), offset: Offset(0, 12), blurRadius: 24)],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.arrow_downward, color: Color(0xFFBA1A1A), size: 14),
                          SizedBox(width: 4),
                          Text('FOCUS NEEDED', style: TextStyle(color: Color(0xFFBA1A1A), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text('History', style: TextStyle(color: PremiumInsightsScreen.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('45% coverage', style: TextStyle(color: PremiumInsightsScreen.secondary, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          const Text('Detailed Breakdown', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: PremiumInsightsScreen.onSurface)),
          const SizedBox(height: 24),
          
          _buildSubjectRow('Polity', '92%', 0.92, PremiumInsightsScreen.tertiary, Icons.balance),
          _buildSubjectRow('Geography', '78%', 0.78, PremiumInsightsScreen.primary, Icons.public),
          _buildSubjectRow('Economics', '65%', 0.65, Colors.purple.shade600, Icons.trending_up),
          _buildSubjectRow('History', '45%', 0.45, const Color(0xFFBA1A1A), Icons.history_edu),
          
          const SizedBox(height: 32),
          // Suggestion
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: PremiumInsightsScreen.surfaceLowest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: PremiumInsightsScreen.outlineVariant.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: PremiumInsightsScreen.primary, size: 20),
                    SizedBox(width: 8),
                    Text('SMART RECOMMENDATION', style: TextStyle(color: PremiumInsightsScreen.primary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ],
                ),
                const SizedBox(height: 16),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(color: PremiumInsightsScreen.onSurface, fontSize: 14, height: 1.5),
                    children: [
                      TextSpan(text: 'You are excelling in Polity! Try spending '),
                      TextSpan(text: '30 mins more daily', style: TextStyle(color: PremiumInsightsScreen.primary, fontWeight: FontWeight.bold)),
                      TextSpan(text: ' on Modern History modules to balance your syllabus completion.'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PremiumInsightsScreen.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Update Study Plan', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectRow(String name, String scoreText, double fillPct, Color mainColor, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PremiumInsightsScreen.surfaceLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x05191C1E), offset: Offset(0, 8), blurRadius: 16)],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: mainColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Icon(icon, color: mainColor, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: PremiumInsightsScreen.onSurface)),
                    Text(scoreText, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: mainColor)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fillPct,
                    backgroundColor: PremiumInsightsScreen.surfaceLow,
                    color: mainColor,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsistencyTab extends StatelessWidget {
  const _ConsistencyTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Streak section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: PremiumInsightsScreen.surfaceLowest,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(color: Color(0x0F191C1E), offset: Offset(0, 12), blurRadius: 32, spreadRadius: -4)],
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 16,
                        color: PremiumInsightsScreen.surfaceLow,
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: CircularProgressIndicator(
                        value: 0.75,
                        strokeWidth: 16,
                        backgroundColor: Colors.transparent,
                        color: Colors.orange.shade500,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('12', style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: PremiumInsightsScreen.onSurface, letterSpacing: -2)),
                        const Text('DAY STREAK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: PremiumInsightsScreen.secondary, letterSpacing: 1.5)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department, color: Colors.orange.shade600, size: 16),
                      const SizedBox(width: 8),
                      Text('Top 5% of all students this week', style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: PremiumInsightsScreen.surfaceLowest,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(color: Color(0x0F191C1E), offset: Offset(0, 12), blurRadius: 32, spreadRadius: -4)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: PremiumInsightsScreen.onSurface)),
                    Text('October 2023', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: PremiumInsightsScreen.primary)),
                  ],
                ),
                const SizedBox(height: 24),
                // Pseudo Heatmap
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 28,
                  itemBuilder: (context, index) {
                    int intensity = (index * 13) % 4;
                    if (index < 3 || index > 20) intensity = 0;
                    
                    Color c;
                    Color t = Colors.transparent;
                    if (intensity == 0) { c = PremiumInsightsScreen.surfaceLow; }
                    else if (intensity == 1) { c = PremiumInsightsScreen.primaryFixed; }
                    else if (intensity == 2) { c = PremiumInsightsScreen.primary.withValues(alpha: 0.6); }
                    else { c = PremiumInsightsScreen.primary; }
                    
                    return Container(
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text('${index + 1}', style: TextStyle(color: t, fontSize: 10, fontWeight: FontWeight.bold)),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: PremiumInsightsScreen.surfaceLowest, borderRadius: BorderRadius.circular(20), border: Border.all(color: PremiumInsightsScreen.outlineVariant.withValues(alpha: 0.3))),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('BEST STREAK', style: TextStyle(color: PremiumInsightsScreen.secondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('24', style: TextStyle(color: PremiumInsightsScreen.onSurface, fontSize: 32, fontWeight: FontWeight.w800)),
                          Text(' days', style: TextStyle(color: PremiumInsightsScreen.secondary, fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: PremiumInsightsScreen.surfaceLowest, borderRadius: BorderRadius.circular(20), border: Border.all(color: PremiumInsightsScreen.outlineVariant.withValues(alpha: 0.3))),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AVG TIME', style: TextStyle(color: PremiumInsightsScreen.secondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('42', style: TextStyle(color: PremiumInsightsScreen.onSurface, fontSize: 32, fontWeight: FontWeight.w800)),
                          Text(' m/day', style: TextStyle(color: PremiumInsightsScreen.secondary, fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
