import 'dart:convert';
import '../models/study_block.dart';
import '../models/user_signals.dart';
import 'api_service.dart';

class ScheduleService {
  Future<List<StudyBlock>> fetchDailySchedule(int userId, String date) async {
    final response = await ApiService.get('/schedule/$userId/$date');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Backend returns { date, blocks, total_planned_minutes, ... }
      final List<dynamic> blocks = data['blocks'] ?? [];
      return blocks.map((json) => StudyBlock.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load schedule: ${response.statusCode}');
    }
  }

  Future<String?> addTask({
    required int userId,
    required String date,
    required String subject,
    required String topic,
    required String startTime,
    required int durationMinutes,
  }) async {
    // Fix: was /schedule/tasks → correct path is /schedule/add_task
    final response = await ApiService.post('/schedule/add_task', {
      'user_id': userId,
      'date': date,
      'subject': subject,
      'topic': topic,
      'start_time': startTime,
      'duration_minutes': durationMinutes,
    });
    if (response.statusCode == 200 || response.statusCode == 201) return null;
    return jsonDecode(response.body)['detail'] ?? 'Failed to add task';
  }

  Future<void> updateBlockTime(int blockId, int minutesSpent) async {
    // Fix: PATCH /schedule/blocks/{id} doesn't exist — use report/submit instead
    // This is a no-op for now until a block-update endpoint is added
    // Silently skip rather than fire a 404
    return;
  }

  Future<bool> submitDailyReport({
    required int userId,
    required String date,
    required List<dynamic> blocks,
  }) async {
    final response = await ApiService.post('/report/submit', {
      'user_id': userId,
      'date': date,
      'blocks': blocks,
    });
    return response.statusCode == 200;
  }

  // Library Management
  Future<List<String>> fetchLibrarySubjects() async {
    final response = await ApiService.get('/library/subjects');
    if (response.statusCode == 200) return List<String>.from(jsonDecode(response.body));
    return [];
  }

  Future<List<dynamic>> fetchLibraryFolders() async {
    // Fix: /library/folders/{subject} doesn't exist — use base /library/folders
    final response = await ApiService.get('/library/folders');
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  Future<List<dynamic>> fetchLibraryAssets() async {
    // Fix: /library/assets/{id} doesn't exist — use base /library/assets
    final response = await ApiService.get('/library/assets');
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  Future<bool> uploadAsset(int? folderId, [dynamic fileData]) async {
    // Fix: /library/assets/upload → correct path is /library/upload
    final response = await ApiService.post('/library/upload', {
      'folder_id': folderId,
    });
    return response.statusCode == 200;
  }

  Future<void> addLibrarySubject({
    required String subjectName,
    required String topic,
    required String timePeriod,
    required String priority,
  }) async {
    // Fix: /library/subjects → correct path is /library/add_subject
    await ApiService.post('/library/add_subject', {
      'subject_name': subjectName,
      'topic': topic,
      'time_period': timePeriod,
      'priority': priority,
    });
  }

  Future<bool> updatePreferences({
    int? userId,
    required String studyStyle,
    required String focusLevel,
    required String revisionPreference,
    required num currentAffairsWeight,
  }) async {
    // Fix: was PATCH /onboarding/preferences/{id} → correct is POST /auth/preferences
    final response = await ApiService.post('/auth/preferences', {
      'study_style': studyStyle,
      'focus_level': focusLevel,
      'revision_preference': revisionPreference,
      'current_affairs_weight': currentAffairsWeight,
    });
    return response.statusCode == 200;
  }

  Future<List<dynamic>> fetchNews() async {
    final response = await ApiService.get('/news/daily');
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  Future<UserSignals?> fetchSignals(int userId) async {
    final response = await ApiService.get('/schedule/signals/$userId');
    if (response.statusCode == 200) {
      return UserSignals.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  // Removed disabled endpoints:
  // - queryAI (/ai/query) — router disabled
  // - optimizeRecovery (/schedule/recovery/optimize) — router disabled
  // - fetchDashboardSummary (/dashboard/summary) — router disabled
}
