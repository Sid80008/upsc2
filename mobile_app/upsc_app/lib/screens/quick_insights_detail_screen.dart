import 'package:flutter/material.dart';

class QuickInsightsDetailScreen extends StatelessWidget {
  const QuickInsightsDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8f6f6),
      appBar: AppBar(
        title: const Text('Detailed Insights', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildInsightSection(
            icon: Icons.local_fire_department_outlined,
            color: Colors.orange.shade500,
            bgColor: Colors.orange.shade50,
            title: 'Active Study Status',
            description: 'You are currently in an active learning phase. Your consistency over the last 3 days has been excellent. Maintain this momentum to improve retention by up to 20%.',
          ),
          const SizedBox(height: 24),
          _buildInsightSection(
            icon: Icons.assignment_late_outlined,
            color: const Color(0xFF1173D4),
            bgColor: const Color(0xFF1173D4).withValues(alpha: 0.1),
            title: 'Pending Tasks',
            description: 'You have tasks left for today. Consider breaking them down into smaller 25-minute Pomodoro sessions if you are feeling fatigued.',
          ),
          const SizedBox(height: 24),
          _buildInsightSection(
            icon: Icons.trending_up_rounded,
            color: Colors.green.shade600,
            bgColor: Colors.green.shade50,
            title: 'Optimization Suggestion',
            description: 'Switching to active recall (like practice quizzes) for your pending tasks will yield higher returns than passive reading at this time of day.',
          ),
        ],
      ),
    );
  }

  Widget _buildInsightSection({required IconData icon, required Color color, required Color bgColor, required String title, required String description}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
