import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class InsightsService {
  Future<Map<String, dynamic>> fetchSubjectStats(int userId) async {
    final response = await ApiService.get('/insights/subjects/$userId');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load subject stats');
    }
  }

  Future<Map<String, dynamic>> fetchSummary(int userId) async {
    final response = await ApiService.get('/insights/summary/$userId');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load insights summary');
    }
  }

  Future<List<double>> fetchWeeklyRhythm(int userId) async {
    final List<Future<http.Response>> requests = [];
    final List<double> rhythm = [];
    
    // Generate last 7 days
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      requests.add(ApiService.get('/report/$userId/$dateStr'));
    }

    final responses = await Future.wait(requests);
    for (final response in responses) {
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        rhythm.add((data['blocks_completed'] as num).toDouble());
      } else {
        rhythm.add(0.0);
      }
    }
    return rhythm;
  }
}
