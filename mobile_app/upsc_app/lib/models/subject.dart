/// Placeholder subject model for the Flutter app.
///
/// Mirrors the core fields from the backend `Subject` model.
class Subject {
  final int id;
  final String name;
  final int priority;
  final int difficulty;

  Subject({
    required this.id,
    required this.name,
    required this.priority,
    required this.difficulty,
  });
}

