class StudyBlock {
  final int id;
  final int userId;
  final String subject;
  final String? topic;
  final String date;
  final String startTime;
  final String endTime;
  final int durationMinutes;
  final String status;
  final int completionPercent;
  final int? rescheduledFromId;

  final int timeSpentMinutes;
  
  String get subjectName => subject;

  StudyBlock({
    required this.id,
    required this.userId,
    required this.subject,
    this.topic,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.status,
    required this.completionPercent,
    this.timeSpentMinutes = 0,
    this.rescheduledFromId,
  });

  factory StudyBlock.fromJson(Map<String, dynamic> json) {
    return StudyBlock(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      subject: json['subject'] as String,
      topic: json['topic'] as String?,
      date: json['date'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] ?? '00:00', // Added for UI compatibility
      durationMinutes: json['duration_minutes'] as int,
      status: json['status'] as String,
      completionPercent: json['completion_percent'] as int? ?? 0,
      rescheduledFromId: json['rescheduled_from_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'subject': subject,
      'topic': topic,
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'duration_minutes': durationMinutes,
      'status': status,
      'completion_percent': completionPercent,
      'rescheduled_from_id': rescheduledFromId,
    };
  }
}
