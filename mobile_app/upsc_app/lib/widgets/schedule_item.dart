import 'package:flutter/material.dart';

class ScheduleItem extends StatelessWidget {
  final String time;
  final String subject;
  final String description;
  final bool isCompleted;
  final bool isOngoing;
  final String? priority;

  const ScheduleItem({
    super.key,
    required this.time,
    required this.subject,
    required this.description,
    this.isCompleted = false,
    this.isOngoing = false,
    this.priority,
  });

  Color _subjectColor(String subjectName) {
    const palette = <Color>[
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red,
      Colors.indigo,
      Colors.brown,
    ];

    final idx = subjectName.hashCode.abs() % palette.length;
    return palette[idx];
  }

  @override
  Widget build(BuildContext context) {
    final accent = _subjectColor(subject);

    return InkWell(
      onTap: () {
        // ignore: avoid_print
        print(subject);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOngoing ? Colors.blue : Colors.grey.shade200,
            width: isOngoing ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isCompleted ? Colors.grey : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            time,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              description,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isCompleted)
                      const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

