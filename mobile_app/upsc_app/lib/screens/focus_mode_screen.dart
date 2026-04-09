import 'package:flutter/material.dart';
import 'dart:async';
// ignore: unnecessary_import
import 'dart:ui';
import '../services/schedule_service.dart';

class FocusModeScreen extends StatefulWidget {
  final int? blockId;
  final String subject;
  final String topic;
  final int plannedMinutes;

  const FocusModeScreen({
    super.key,
    this.blockId,
    required this.subject,
    required this.topic,
    required this.plannedMinutes,
  });

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {

  late Timer _timer;
  late Timer _syncTimer;
  int _secondsRemaining = 0;
  int _secondsElapsed = 0;
  bool _isPaused = false;
  

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _secondsRemaining = widget.plannedMinutes * 60;
    

    _startTimer();
    _startSyncTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _syncWithBackend();
    }
  }

  void _startSyncTimer() {
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isPaused && widget.blockId != null) {
        _syncWithBackend();
      }
    });
  }

  Future<void> _syncWithBackend() async {
    if (widget.blockId == null) return;
    final minutes = _secondsElapsed ~/ 60;
    if (minutes > 0) {
      await ScheduleService().updateBlockTime(widget.blockId!, minutes);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && _secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
          _secondsElapsed++;
        });
      } else if (_secondsRemaining <= 0) {
        _timer.cancel();
        _syncTimer.cancel();
        _syncWithBackend().then((_) {
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                backgroundColor: Theme.of(context).colorScheme.surface,
                title: Text('Session Complete!', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                content: Text('Great job maintaining your focus. Keep the momentum going!', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context, true);
                    },
                    child: Text('Continue', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                  ),
                ],
              ),
            );
          }
        });
      }
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _syncWithBackend();
      } else {
      }
    });
  }
  
  void _endSession() async {
    _timer.cancel();
    _syncTimer.cancel();
    await _syncWithBackend();
    if (mounted) Navigator.pop(context, true); 
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_timer.isActive) _timer.cancel();
    if (_syncTimer.isActive) _syncTimer.cancel();
    super.dispose();
  }

  String get _timeString {
    int h = _secondsRemaining ~/ 3600;
    int m = (_secondsRemaining % 3600) ~/ 60;
    int s = _secondsRemaining % 60;
    if (h > 0) {
      return '${h.toString()}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Calculate progress for outer ring
    int totalSecs = widget.plannedMinutes * 60;
    double progress = totalSecs > 0 ? (totalSecs - _secondsRemaining) / totalSecs : 0;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Simplified Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.onSurface.withValues(alpha: 0.5), size: 20),
                    onPressed: _endSession,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'DEEP FOCUS',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48), // Balance for back button
                ],
              ),
            ),
            
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Responsive Timer
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.7,
                        height: MediaQuery.of(context).size.width * 0.7,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 8,
                          backgroundColor: colorScheme.primary.withValues(alpha: 0.05),
                          color: colorScheme.primary,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _timeString,
                            style: TextStyle(
                              fontSize: 80,
                              fontWeight: FontWeight.w200,
                              color: colorScheme.onSurface,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          Text(
                            _isPaused ? 'PAUSED' : 'FOCUSING',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface.withValues(alpha: 0.4),
                              letterSpacing: 4.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 64),
                  
                  // Session Identity
                  Text(
                    widget.subject.toUpperCase(),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: colorScheme.primary, letterSpacing: 3),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      widget.topic,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: colorScheme.onSurface, height: 1.2),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            
            // Refined Bottom Controls
            Padding(
              padding: const EdgeInsets.all(48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildControlBtn(
                    icon: _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    label: _isPaused ? 'Resume' : 'Pause',
                    color: _isPaused ? const Color(0xFF10B981) : Colors.amber,
                    onTap: _togglePause,
                    onSurface: colorScheme.onSurface,
                  ),
                  const SizedBox(width: 48),
                  _buildControlBtn(
                    icon: Icons.stop_rounded,
                    label: 'Stop',
                    color: const Color(0xFFEF4444),
                    onTap: _endSession,
                    onSurface: colorScheme.onSurface,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required Color onSurface,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            label.toUpperCase(),
            style: TextStyle(color: onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

}
