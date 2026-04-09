import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class AIInsightsScreen extends StatefulWidget {
  const AIInsightsScreen({super.key});

  @override
  State<AIInsightsScreen> createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends State<AIInsightsScreen> {
  bool _isLoading = true;
  String _analysis = '';

  @override
  void initState() {
    super.initState();
    _fetchInsights();
  }

  Future<void> _fetchInsights() async {
    try {
      final auth = AuthService();
      final token = await auth.getToken();
      
      final url = auth.baseUrl.replaceAll('/auth', '/insights/advanced/ai_analysis');
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _analysis = data['analysis'] ?? 'No analysis available.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _analysis = 'Failed to load insights. Please try again later.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _analysis = 'An error occurred while fetching insights. $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8f6f6),
      appBar: AppBar(
        title: const Text('AI Mentor Insights', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFFF7ECFF), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6)),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(child: Text('Performance Analysis', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _analysis,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
