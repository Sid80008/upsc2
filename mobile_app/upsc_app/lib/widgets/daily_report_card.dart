import 'package:flutter/material.dart';

/// Rich daily report card matching the Bento aesthetic.
class DailyReportCard extends StatelessWidget {
  final int completedTasks;
  final int totalTasks;
  final int completedMinutes;
  final int totalMinutes;

  const DailyReportCard({
    super.key,
    required this.completedTasks,
    required this.totalTasks,
    required this.completedMinutes,
    required this.totalMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = totalMinutes > 0 ? completedMinutes / totalMinutes : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Focus Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF191C1E),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF005AAB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(progress * 100).toInt()}% Done',
                  style: const TextStyle(
                    color: Color(0xFF005AAB),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFD5E3FF),
            color: const Color(0xFF005AAB),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          
          const SizedBox(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                label: 'Tasks',
                value: '$completedTasks/$totalTasks',
                icon: Icons.task_alt,
                color: const Color(0xFF006847),
              ),
              _buildStatItem(
                label: 'Time',
                value: '${(completedMinutes / 60).toStringAsFixed(1)}h',
                icon: Icons.timer,
                color: const Color(0xFF005AAB),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF191C1E),
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

