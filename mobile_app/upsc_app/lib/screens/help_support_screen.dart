import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const Color primary = Color(0xFF005AAB);
  static const Color primaryContainer = Color(0xFF1173D4);
  static const Color primaryFixed = Color(0xFFD5E3FF);
  static const Color secondary = Color(0xFF515F74);
  static const Color surface = Color(0xFFF7F9FB);
  static const Color surfaceLowest = Color(0xFFFFFFFF);
  static const Color surfaceLow = Color(0xFFF2F4F6);
  static const Color onSurface = Color(0xFF191C1E);
  static const Color onSurfaceVariant = Color(0xFF414752);
  static const Color outlineVariant = Color(0xFFC1C6D4);

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
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1173D4)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text('Help Center', style: TextStyle(color: Color(0xFF1173D4), fontWeight: FontWeight.bold, fontSize: 24)),
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
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(color: surfaceLow, borderRadius: BorderRadius.circular(16)),
              child: const TextField(
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: outlineVariant),
                  hintText: 'Search for topics or keywords...',
                  hintStyle: TextStyle(color: onSurfaceVariant),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // FAQ Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Frequently Asked Questions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface)),
                Text('3 Items', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primary.withValues(alpha: 0.8))),
              ],
            ),
            const SizedBox(height: 16),
            _buildFaqItem('How does adaptation work?', 'Our adaptive engine analyzes your study pace, retention rates from previous sessions, and upcoming exam deadlines to dynamically adjust your daily workload. If you excel in a subject, the system introduces advanced concepts earlier; if you struggle, it allocates more time for foundational review.'),
            const SizedBox(height: 12),
            _buildFaqItem('Why tasks are rescheduled?', 'Tasks are rescheduled when the system detects a deviation from your "Ideal Study Path." This ensures you never face a backlog. Instead of piling up, missed tasks are redistributed based on priority and cognitive load management.'),
            const SizedBox(height: 12),
            _buildFaqItem('How is performance calculated?', 'Performance is a composite score derived from three pillars: Consistency (Daily logins), Depth (Hours spent in Deep Work mode), and Accuracy (Results from PYQ practice sessions).'),

            const SizedBox(height: 32),
            // Contact Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: surfaceLow, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Get in Touch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface)),
                  const SizedBox(height: 8),
                  const Text('Can\'t find what you\'re looking for? Our academic support team is here to help.', style: TextStyle(color: onSurfaceVariant, height: 1.5)),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 8,
                        shadowColor: primary.withValues(alpha: 0.2),
                      ),
                      onPressed: () {},
                      icon: const Icon(Icons.report_problem),
                      label: const Text('Report a problem', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: surfaceLowest,
                        foregroundColor: primary,
                        side: BorderSide(color: outlineVariant.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {},
                      icon: const Icon(Icons.rate_review),
                      label: const Text('Send feedback', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            // App Info Section
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.auto_stories, color: Colors.white),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Study Sanctuary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: onSurface)),
                    Text('Version 2.0.4', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: outlineVariant)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '"Empowering UPSC aspirants through precision-driven, adaptive study systems designed for cognitive endurance."',
              style: TextStyle(fontSize: 12, color: onSurfaceVariant, fontStyle: FontStyle.italic, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                GestureDetector(onTap: (){}, child: const Text('Privacy Policy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primary))),
                const SizedBox(width: 16),
                GestureDetector(onTap: (){}, child: const Text('Terms of Service', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primary))),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      decoration: BoxDecoration(color: surfaceLowest, borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: onSurface)),
          iconColor: primary,
          collapsedIconColor: outlineVariant,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(answer, style: const TextStyle(color: onSurfaceVariant, height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }
}
