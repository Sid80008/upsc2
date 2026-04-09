import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/schedule_service.dart';

class BuddyScreen extends StatefulWidget {
  final VoidCallback? onBackHome;
  const BuddyScreen({super.key, this.onBackHome});

  @override
  State<BuddyScreen> createState() => _BuddyScreenState();
}

class _BuddyScreenState extends State<BuddyScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScheduleService _api = ScheduleService();
  late SharedPreferences _prefs;
  List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text': "Good morning! You've successfully completed 85% of your Deep Work goals this week. Your retention in 'UPSC Polity' is peaking.",
      'insights': true,
    }
  ];
  bool _isTyping = false;
  bool _isHistoryLoading = true; // Renamed from _isLoadingHistory

  @override
  void initState() {
    super.initState();
    _initBuddy();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initBuddy() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    final String? historyJson = _prefs.getString('buddy_chat_history');
    if (historyJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(historyJson);
        if (mounted) {
          setState(() {
            _messages = decoded.map((m) => Map<String, dynamic>.from(m)).toList();
            _isHistoryLoading = false;
          });
        }
      } catch (e) {
        // Handle JSON decoding errors, e.g., corrupted history
        debugPrint('Error decoding chat history: $e');
        if (mounted) setState(() => _isHistoryLoading = false);
      }
    } else {
      if (mounted) setState(() => _isHistoryLoading = false);
    }
  }

  Future<void> _saveChatHistory() async {
    await _prefs.setString('buddy_chat_history', jsonEncode(_messages));
  }

  Future<void> _clearHistory() async {
    if (mounted) {
      setState(() {
        _messages = [
          {
            'isUser': false,
            'text': "Memory cleared. We start fresh. How can I assist you today?",
            'insights': false,
          }
        ];
      });
    }
  }

  // Premium Theme Colors will now use Theme.of(context)
  late Color primary;
  late Color primaryContainer;
  late Color secondary;
  late Color background;
  late Color surface;
  late Color onSurface;
  late Color outlineVariant;

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (mounted) {
      setState(() {
        _messages.add({'isUser': true, 'text': text});
        _isTyping = true;
        _controller.clear();
      });
    }
    await _saveChatHistory();

    try {
      // AI router is currently disabled on the backend.
      // Buddy screen uses a local static response as a fallback.
      await Future.delayed(const Duration(milliseconds: 600));
      final Map<String, dynamic> response = {
        'response': "I'm in offline mode right now. Keep pushing — focus on your weak subjects today and track your blocks consistently. Consistency beats intensity!"
      };
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add({
            'isUser': false, 
            'text': response['response'] as String,
            'insights': false
          });
        });
        _saveChatHistory();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add({
            'isUser': false, 
            'text': "Connection error. Please check your network.",
            'insights': false
          });
        });
        _saveChatHistory();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isHistoryLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    primary = colorScheme.primary;
    primaryContainer = colorScheme.primaryContainer;
    secondary = theme.textTheme.bodyMedium?.color ?? const Color(0xFF515F74);
    background = colorScheme.surface;
    surface = theme.cardColor;
    onSurface = colorScheme.onSurface;
    outlineVariant = theme.dividerColor;

    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          // Background Gradient Mesh
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Custom Header
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Row(
                      children: [
                        if (widget.onBackHome != null)
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new),
                            onPressed: widget.onBackHome,
                            color: onSurface,
                          ),
                        const SizedBox(width: 8),
                        Text(
                          "Aspirant Buddy",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                            letterSpacing: -1,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.delete_sweep_outlined),
                          onPressed: _clearHistory,
                          color: onSurface.withValues(alpha: 0.5),
                          tooltip: "Clear History",
                        ),
                      ],
                    ),
                  ),
                ),
                _buildAvatarHeader(),
                const SizedBox(height: 8),
                // The title "Aspirant Buddy" is now part of the custom header above.
                // This Text widget is redundant and should be removed if the new header is fully adopted.
                // For now, I'll comment it out or remove it based on the instruction's implied intent.
                // The instruction's new header already includes "Aspirant Buddy" text.
                // Text(
                //   'Aspirant Buddy',
                //   style: TextStyle(
                //     fontFamily: 'Lexend',
                //     fontSize: 28,
                //     fontWeight: FontWeight.w800,
                //     letterSpacing: -1.0,
                //     color: onSurface,
                //   ),
                // ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Your architectural guide to academic mastery.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: secondary.withValues(alpha: 0.7)),
                  ),
                ),
                const SizedBox(height: 32),
                
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                    boxShadow: [
                      BoxShadow(
                        color: onSurface.withValues(alpha: 0.05),
                        blurRadius: 40,
                        offset: const Offset(0, -10),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 80), // Added bottom padding for send button
                          itemCount: _messages.length + (_isTyping ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (_isHistoryLoading && _messages.length == 1) {
                                return const Padding(
                                  padding: EdgeInsets.all(24.0),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
                            if (index == _messages.length) return _buildBuddyMessage(text: "Architect is processing...", isThinking: true);
                            final msg = _messages[index];
                            return (msg['isUser'] as bool) 
                              ? _buildUserMessage(text: msg['text'] as String)
                              : _buildBuddyMessage(
                                  text: msg['text'] as String,
                                  insights: (msg['insights'] as bool?) ?? false,
                                );
                          },
                        ),
                      ),
                      _buildInteractionDock(),
                    ],
                  ),
                ),
              ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarHeader() {
    return Container(
      width: 100,
      height: 100,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: primary.withValues(alpha: 0.1), width: 2),
      ),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [primary, primaryContainer], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: const Center(child: Icon(Icons.psychology_rounded, color: Colors.white, size: 50)),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF006847),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuddyMessage({required String text, bool insights = false, bool isThinking = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [primary, primaryContainer]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: outlineVariant.withValues(alpha: 0.08),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: isThinking 
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: primary))
                    : Text(text, style: TextStyle(fontSize: 14, height: 1.5, fontWeight: FontWeight.w500, color: onSurface)),
                ),
                if (insights) ...[
                  const SizedBox(height: 12),
                  _buildInsightsPanel(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMessage({required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(color: primary.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Text(text, style: const TextStyle(fontSize: 14, height: 1.5, fontWeight: FontWeight.w500, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: outlineVariant.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: onSurface.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: 0.85,
                  strokeWidth: 5,
                  backgroundColor: primary.withValues(alpha: 0.1),
                  color: primary,
                  strokeCap: StrokeCap.round,
                ),
                Text('85%', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: primary)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Architectural Momentum', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: onSurface)),
                Text('4.2 hours ahead of elite schedule', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: secondary.withValues(alpha: 0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionDock() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: background,
        border: Border(top: BorderSide(color: outlineVariant.withValues(alpha: 0.1))),
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickChip(Icons.auto_awesome_mosaic_rounded, 'Summarize Performance', () {
                  _controller.text = "Summarize my performance this week.";
                  _handleSend();
                }),
                const SizedBox(width: 12),
                _buildQuickChip(Icons.analytics_rounded, 'Yield Predictions', () {
                  _controller.text = "Give me yield predictions for next week.";
                  _handleSend();
                }),
                const SizedBox(width: 12),
                _buildQuickChip(Icons.history_edu_rounded, 'Explain Concept', () {
                  _controller.text = "Explain the concepts I struggled with today.";
                  _handleSend();
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: onSurface.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _handleSend(),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Consult Architect...',
                      hintStyle: TextStyle(color: secondary.withValues(alpha: 0.4), fontSize: 14),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      border: InputBorder.none,
                      suffixIcon: Icon(Icons.mic_none_rounded, color: secondary.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _handleSend,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [primary, primaryContainer]),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: outlineVariant.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: primary),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: onSurface)),
          ],
        ),
      ),
    );
  }
}
