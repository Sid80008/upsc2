import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class AITutorScreen extends StatefulWidget {
  const AITutorScreen({super.key});

  @override
  State<AITutorScreen> createState() => _AITutorScreenState();
}

class _AITutorScreenState extends State<AITutorScreen> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'model',
      'content': 'Hello Aspirant! I am your AI UPSC Mentor. How can I help you today? You can ask me about study strategies, topic explanations, or schedule management.'
    });
  }

  Future<void> _sendMessage() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _textCtrl.clear();
    _scrollToBottom();

    FocusScope.of(context).unfocus();

    try {
      final auth = AuthService();
      final token = await auth.getToken();
      
      final url = auth.baseUrl.replaceAll('/auth', '/tutor/chat');
      
      final bodyMessages = _messages.map((m) => {
        'role': m['role'],
        'content': m['content']
      }).toList();

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({'messages': bodyMessages}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _messages.add({'role': 'model', 'content': data['reply'] ?? 'Unknown response.'});
        });
      } else {
        setState(() {
          _messages.add({'role': 'model', 'content': 'Sorry, I encountered a server error. Please try again.'});
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({'role': 'model', 'content': 'Sorry, a network error occurred.'});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Light blue-grey background
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6)),
            SizedBox(width: 8),
            Text('AI Tutor', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return _buildChatBubble(msg['content']!, isUser);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: const Offset(0, -2), blurRadius: 4),
              ]
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    decoration: InputDecoration(
                      hintText: 'Ask me anything...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _isLoading ? null : _sendMessage,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1173D4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF1173D4) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: [
            if (!isUser) BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
          ]
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            height: 1.4,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
