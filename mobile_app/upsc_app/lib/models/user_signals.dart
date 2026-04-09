class SubjectSignal {
  final String subject;
  final int missCount;
  final int partialCount;
  final int completeCount;
  final double avgCompletionPct;
  final bool isWeak;
  final List<String> preferredSlots;

  SubjectSignal({
    required this.subject,
    required this.missCount,
    required this.partialCount,
    required this.completeCount,
    required this.avgCompletionPct,
    required this.isWeak,
    required this.preferredSlots,
  });

  factory SubjectSignal.fromJson(Map<String, dynamic> json) {
    return SubjectSignal(
      subject: json['subject'],
      missCount: json['miss_count'],
      partialCount: json['partial_count'],
      completeCount: json['complete_count'],
      avgCompletionPct: (json['avg_completion_pct'] as num).toDouble(),
      isWeak: json['is_weak'],
      preferredSlots: List<String>.from(json['preferred_slots'] ?? []),
    );
  }
}

class UserSignals {
  final int userId;
  final double consistencyScore;
  final List<String> weakSubjects;
  final Map<String, List<String>> avoidancePatterns;
  final Map<String, String> recommendedSlotAdjustments;
  final List<SubjectSignal> subjectSignals;
  final Map<String, dynamic>? fingerprint;

  UserSignals({
    required this.userId,
    required this.consistencyScore,
    required this.weakSubjects,
    required this.avoidancePatterns,
    required this.recommendedSlotAdjustments,
    required this.subjectSignals,
    this.fingerprint,
  });

  factory UserSignals.fromJson(Map<String, dynamic> json) {
    return UserSignals(
      userId: json['user_id'],
      consistencyScore: (json['consistency_score'] as num).toDouble(),
      weakSubjects: List<String>.from(json['weak_subjects'] ?? []),
      avoidancePatterns: (json['avoidance_patterns'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, List<String>.from(v)),
      ) ?? {},
      recommendedSlotAdjustments: (json['recommended_slot_adjustments'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, v.toString()),
      ) ?? {},
      subjectSignals: (json['subject_signals'] as List<dynamic>?)
          ?.map((s) => SubjectSignal.fromJson(s))
          .toList() ?? [],
      fingerprint: json['fingerprint'],
    );
  }
}
