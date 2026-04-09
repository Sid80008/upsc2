class WeeklyReview {
  final int userId;
  final String weekStart;
  final String weekEnd;
  final int totalBlocks;
  final int completedBlocks;
  final int missedBlocks;
  final double completionRate;
  final String strongestSubject;
  final String weakestSubject;
  final String? mostImproved;
  final String? mostDeclined;
  final Map<String, int> recommendedWeightAdjustments;
  final String summaryText;

  WeeklyReview({
    required this.userId,
    required this.weekStart,
    required this.weekEnd,
    required this.totalBlocks,
    required this.completedBlocks,
    required this.missedBlocks,
    required this.completionRate,
    required this.strongestSubject,
    required this.weakestSubject,
    this.mostImproved,
    this.mostDeclined,
    required this.recommendedWeightAdjustments,
    required this.summaryText,
  });

  factory WeeklyReview.fromJson(Map<String, dynamic> json) {
    return WeeklyReview(
      userId: json['user_id'],
      weekStart: json['week_start'],
      weekEnd: json['week_end'],
      totalBlocks: json['total_blocks'],
      completedBlocks: json['completed_blocks'],
      missedBlocks: json['missed_blocks'],
      completionRate: (json['completion_rate'] as num).toDouble(),
      strongestSubject: json['strongest_subject'],
      weakestSubject: json['weakest_subject'],
      mostImproved: json['most_improved'],
      mostDeclined: json['most_declined'],
      recommendedWeightAdjustments: Map<String, int>.from(json['recommended_weight_adjustments'] ?? {}),
      summaryText: json['summary_text'] ?? '',
    );
  }
}
