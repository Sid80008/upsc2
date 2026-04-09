import 'dart:convert';
import '../models/study_block.dart';
import '../models/user_signals.dart';
import 'api_service.dart';

class ScheduleService {
  Future<List<StudyBlock>> fetchDailySchedule(int userId, String date) async {
    final response = await ApiService.get('/schedule/$userId/$date');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => StudyBlock.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load schedule');
    }
  }

  Future<String?> addTask({
    required String date,
    required String subject,
    required String topic,
    required String startTime,
    required int durationMinutes,
  }) async {
    final response = await ApiService.post('/schedule/tasks', {
      'date': date,
      'subject': subject,
      'topic': topic,
      'start_time': startTime,
      'duration_minutes': durationMinutes,
    });
    if (response.statusCode == 200 || response.statusCode == 201) return null;
    return jsonDecode(response.body)['detail'] ?? 'Failed to add task';
  }

  Future<Map<String, dynamic>> queryAI(String query) async {
    final response = await ApiService.post('/ai/query', {'query': query});
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {'response': "I'm sorry, I couldn't process that query."};
  }

  Future<void> updateBlockTime(int blockId, int minutesSpent) async {
    await ApiService.patch('/schedule/blocks/$blockId', {
      'time_spent_minutes': minutesSpent,
    });
  }

  Future<bool> submitDailyReport({
    required int userId,
    required String date,
    required List<dynamic> blocks,
    int? focusRating,
  }) async {
    final response = await ApiService.post('/report/submit', {
      'user_id': userId,
      'date': date,
      'blocks': blocks,
      'focus_rating': ?focusRating,
    });
    return response.statusCode == 200;
  }

  // Library Management
  Future<List<String>> fetchLibrarySubjects() async {
    final response = await ApiService.get('/library/subjects');
    if (response.statusCode == 200) return List<String>.from(jsonDecode(response.body));
    return [];
  }

  Future<List<dynamic>> fetchLibraryFolders([String? subject]) async {
    final endpoint = subject != null ? '/library/folders/$subject' : '/library/folders';
    final response = await ApiService.get(endpoint);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  Future<List<dynamic>> fetchLibraryAssets([int? folderId]) async {
    final endpoint = folderId != null ? '/library/assets/$folderId' : '/library/assets';
    final response = await ApiService.get(endpoint);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  Future<bool> uploadAsset(int? folderId, [dynamic fileData]) async {
    final response = await ApiService.post('/library/assets/upload', {
      'folder_id': folderId,
      'file': fileData,
    });
    return response.statusCode == 200;
  }

  Future<void> addLibrarySubject({
    required String subjectName,
    required String topic,
    required String timePeriod,
    required String priority,
  }) async {
    await ApiService.post('/library/subjects', {
      'name': subjectName,
      'topic': topic,
      'time_period': timePeriod,
      'priority': priority,
    });
  }

  // Recovery & Preferences
  Future<Map<String, dynamic>> optimizeRecovery([int? userId]) async {
    final response = await ApiService.post('/schedule/recovery/optimize', {
      'user_id': ?userId,
    });
    if (response.statusCode == 200) return jsonDecode(response.body);
    return {'status': 'failed', 'number_of_blocks_rescheduled': 0};
  }

  Future<bool> updatePreferences({
    int? userId,
    required String studyStyle,
    required String focusLevel,
    required String revisionPreference,
    required num currentAffairsWeight,
  }) async {
    final response = await ApiService.patch('/onboarding/preferences/${userId ?? 1}', {
      'study_style': studyStyle,
      'focus_level': focusLevel,
      'revision_preference': revisionPreference,
      'current_affairs_weight': currentAffairsWeight,
    });
    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>?> fetchDashboardSummary() async {
    final response = await ApiService.get('/dashboard/summary');
    if (response.statusCode == 200) return jsonDecode(response.body);
    return null;
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
}
