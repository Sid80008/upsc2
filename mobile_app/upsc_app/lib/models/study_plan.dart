import 'subject.dart';

/// Placeholder study plan model for the Flutter app.
///
/// Mirrors the core fields from the backend `StudyPlan` model.
class StudyPlan {
  final int userId;
  final List<Subject> subjects;
  final DateTime startDate;
  final DateTime targetExamDate;

  StudyPlan({
    required this.userId,
    required this.subjects,
    required this.startDate,
    required this.targetExamDate,
  });
}

