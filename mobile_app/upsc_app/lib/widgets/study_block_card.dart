import 'package:flutter/material.dart';
import '../models/study_block.dart';

/// Rich study block card matching the Bento aesthetic.
class StudyBlockCard extends StatelessWidget {
  final StudyBlock block;
  final VoidCallback? onTap;

  const StudyBlockCard({
    super.key,
    required this.block,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine color and icon based on subject or status
    final Color accentColor = _getSubjectColor(block.subjectName);
    
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Subject Icon/Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getSubjectIcon(block.subjectName),
                color: accentColor,
              ),
            ),
            const SizedBox(width: 16),
            
            // Text Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    block.subjectName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF191C1E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${block.startTime} - ${block.endTime}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Status Icon
            _buildStatusIndicator(block.status),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String status) {
    IconData icon;
    Color color;
    
    switch (status.toLowerCase()) {
      case 'completed':
        icon = Icons.check_circle;
        color = const Color(0xFF006847);
        break;
      case 'missed':
        icon = Icons.cancel;
        color = const Color(0xFFBA1A1A);
        break;
      case 'in_progress':
        icon = Icons.pending;
        color = const Color(0xFF005AAB);
        break;
      default:
        icon = Icons.radio_button_unchecked;
        color = Colors.grey.withValues(alpha: 0.5);
    }
    
    return Icon(icon, color: color, size: 24);
  }

  Color _getSubjectColor(String subject) {
    // Simplified mapping
    if (subject.contains('History')) return const Color(0xFFBA1A1A);
    if (subject.contains('Polity')) return const Color(0xFF005AAB);
    if (subject.contains('Geography')) return const Color(0xFF006847);
    if (subject.contains('Economics')) return const Color(0xFF7D5800);
    return const Color(0xFF515F74).withValues(alpha: 0.1);
  }

  IconData _getSubjectIcon(String subject) {
    if (subject.contains('History')) return Icons.history_edu;
    if (subject.contains('Polity')) return Icons.gavel;
    if (subject.contains('Geography')) return Icons.public;
    if (subject.contains('Economics')) return Icons.trending_up;
    return Icons.menu_book;
  }
}

