import 'dart:convert';
import '../models/daily_report.dart';
import 'api_service.dart';

class ReportService {
  Future<ReportSubmitResponse> submitReport(ReportSubmitRequest request) async {
    final response = await ApiService.post('/report/submit', request.toJson());

    if (response.statusCode == 200) {
      return ReportSubmitResponse.fromJson(jsonDecode(response.body));
    } else {
      final detail = jsonDecode(response.body)['detail'] ?? 'Submission failed';
      throw Exception(detail);
    }
  }

  Future<Map<String, dynamic>?> fetchReport(int userId, String date) async {
    final response = await ApiService.get('/report/$userId/$date');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to fetch report status');
    }
  }
}
