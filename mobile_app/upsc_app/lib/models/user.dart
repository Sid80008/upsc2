/// Placeholder user model for the Flutter app.
///
/// Mirrors the core fields from the backend `User` model.
class User {
  final int id;
  final String name;
  final String examType;
  final DateTime? examDate;
  final double? dailyStudyHours;

  User({
    required this.id,
    required this.name,
    required this.examType,
    this.examDate,
    this.dailyStudyHours,
  });
}

