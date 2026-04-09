import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = const Color(0xFF1173D4);

    final List<Map<String, String>> notifications = [
      {
        'title': 'Schedule Updated',
        'body': 'Your AI coach has adjusted your evening session based on your morning focus.',
        'time': '10 mins ago',
        'type': 'system',
      },
      {
        'title': 'New Insight Available',
        'body': 'You are 15% more focused during "History" sessions than "Ethics". See details in your report.',
        'time': '2 hours ago',
        'type': 'insight',
      },
      {
        'title': 'Streak Milestone',
        'body': 'Congratulations! You\'ve completed 7 days of consistent study.',
        'time': 'Today, 8:00 AM',
        'type': 'achievement',
      },
      {
        'title': 'Upcoming Deadline',
        'body': 'Answer Writing Practice for GS Paper 1 starts in 30 minutes.',
        'time': 'Yesterday',
        'type': 'reminder',
      },
    ];

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.bold, 
          fontSize: 20, 
          color: theme.colorScheme.onSurface
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: theme.dividerColor.withValues(alpha: 0.1), height: 1),
        ),
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'All caught up!',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => Divider(height: 32, indent: 72, endIndent: 24, color: theme.dividerColor.withValues(alpha: 0.1)),
              itemBuilder: (context, index) {
                final item = notifications[index];
                return _NotificationItem(item: item, primaryColor: primaryColor);
              },
            ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final Map<String, String> item;
  final Color primaryColor;

  const _NotificationItem({required this.item, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;
    Color iconBg;

    switch (item['type']) {
      case 'insight':
        icon = Icons.auto_graph_rounded;
        iconColor = const Color(0xFF8B5CF6);
        iconBg = const Color(0xFFF5F3FF);
        break;
      case 'achievement':
        icon = Icons.emoji_events;
        iconColor = const Color(0xFFF59E0B);
        iconBg = const Color(0xFFFFFBEB);
        break;
      case 'reminder':
        icon = Icons.timer_outlined;
        iconColor = const Color(0xFFEF4444);
        iconBg = const Color(0xFFFEF2F2);
        break;
      default:
        icon = Icons.settings_suggest_rounded;
        iconColor = primaryColor;
        iconBg = primaryColor.withValues(alpha: 0.1);
    }

    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                      child: Icon(icon, color: iconColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['title']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(item['time']!, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(item['body']!, style: const TextStyle(fontSize: 16, height: 1.5)),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Acknowledge', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item['title']!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        item['time']!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['body']!,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
