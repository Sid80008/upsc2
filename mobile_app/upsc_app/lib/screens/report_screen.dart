import 'package:flutter/material.dart';
import '../services/schedule_service.dart';
import '../services/report_service.dart';
import '../models/study_block.dart';
import '../models/daily_report.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ScheduleService _api = ScheduleService();
  final ReportService _reportApi = ReportService();
  final AuthService _auth = AuthService();

  List<StudyBlock> _blocks = [];
  bool _isLoading = true;
  bool _isAlreadySubmitted = false;
  bool _isSubmitting = false;
  // ignore: unused_field
  ReportSubmitResponse? _lastResponse;
  int? _userId;

  // Design Tokens
  final Color _navy = const Color(0xFF0F172A);
  final Color _accent = const Color(0xFF38BDF8);
  final Color _slate = const Color(0xFF1E293B);

  final Map<int, Map<String, dynamic>> _reports = {};
  
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() => _isLoading = true);
    final dateStr = _selectedDate.toIso8601String().split('T')[0];
    
    try {
      _userId ??= await _auth.getUserId();
      if (_userId == null) {
        final profile = await _auth.getProfile();
        _userId = profile?['id'];
      }

      if (_userId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final finalUserId = _userId!;
      
      final results = await Future.wait([
        _api.fetchDailySchedule(finalUserId, dateStr),
        _reportApi.fetchReport(finalUserId, dateStr),
      ]);

      final List<StudyBlock> blocks = results[0] as List<StudyBlock>;
      final Map<String, dynamic>? existingReport = results[1] as Map<String, dynamic>?;

      if (mounted) {
        setState(() {
          _blocks = blocks;
          _isAlreadySubmitted = existingReport != null;
          
          for (var b in _blocks) {
            _reports[b.id] = {
              'status': b.status,
              'completion_percent': b.completionPercent,
              'notes': '',
            };
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error syncing metrics with backend.')));
      }
    }
  }

  Future<void> _submitReport() async {
    if (_isSubmitting || _blocks.isEmpty || _isAlreadySubmitted) return;
    setState(() => _isSubmitting = true);

    try {
      final dateStr = _selectedDate.toIso8601String().split('T')[0];
      final request = ReportSubmitRequest(
        userId: _userId!,
        date: dateStr,
        blocks: _blocks.map((b) {
          final rep = _reports[b.id]!;
          return BlockReportItem(
            blockId: b.id,
            status: rep['status'],
            completionPercent: rep['completion_percent'],
          );
        }).toList(),
      );

      final response = await _reportApi.submitReport(request);

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isAlreadySubmitted = true;
          _lastResponse = response;
        });
        _showSuccessSheet(response);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
      }
    }
  }

  void _showSuccessSheet(ReportSubmitResponse resp) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _slate,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.tealAccent, size: 64),
            const SizedBox(height: 16),
            const Text('Trajectory Adjusted', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Report #${resp.reportId} processed. ${resp.rescheduledCount} sessions optimized for tomorrow.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Back to Dashboard'),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Unused _editBlock functionality removed to satisfy analysis lints. 
  // If editing is required in the future, re-implement _editBlock and wire to UI.

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: _accent,
              onPrimary: _navy,
              surface: _slate,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _isAlreadySubmitted = false;
      });
      _loadSchedule();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: SafeArea(
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Stack(
                children: [
                  Positioned.fill(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 140),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 32),
                          if (_blocks.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Text("No blocks scheduled.", style: TextStyle(color: Colors.white54)),
                              ),
                            ),
                          ..._blocks.map((b) => _buildBlockItem(b)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildStickyFooter(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('OVERVIEW', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
            const SizedBox(height: 4),
            const Text('Daily Report', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        InkWell(
          onTap: _pickDate,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(DateFormat('MMM dd').format(_selectedDate), style: TextStyle(color: _accent, fontSize: 18, fontWeight: FontWeight.w600)),
              Text(DateFormat('EEEE').format(_selectedDate), style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  void _quickUpdateStatus(StudyBlock block, String newStatus, int percent) {
    if (_isAlreadySubmitted) return;
    setState(() {
      _reports[block.id]!['status'] = newStatus;
      _reports[block.id]!['completion_percent'] = percent;
    });
  }

  Widget _buildBlockItem(StudyBlock block) {
    final rep = _reports[block.id]!;
    final status = rep['status'];
    
    Color bgObj, borderObj, iconColorObj;
    IconData iconData;
    
    if (status == 'completed') {
      bgObj = Colors.teal;
      borderObj = Colors.teal;
      iconColorObj = Colors.tealAccent;
      iconData = Icons.check_circle_outline;
    } else if (status == 'missed') {
      bgObj = Colors.pink;
      borderObj = Colors.pink;
      iconColorObj = Colors.pinkAccent;
      iconData = Icons.cancel_outlined;
    } else {
      bgObj = _accent;
      borderObj = _accent;
      iconColorObj = _accent;
      iconData = Icons.access_time;
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: _isAlreadySubmitted ? 0.05 : 0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bgObj.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderObj.withValues(alpha: 0.3)),
                ),
                child: Icon(iconData, color: iconColorObj),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(block.subject, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white)),
                    Text('${block.startTime} • ${status.toString().toUpperCase()}', style: TextStyle(color: iconColorObj, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              if (!_isAlreadySubmitted)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.check_circle_outline),
                      color: status == 'completed' ? Colors.tealAccent : Colors.white24,
                      onPressed: () => _quickUpdateStatus(block, 'completed', 100),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.timelapse),
                      color: status == 'partial' ? _accent : Colors.white24,
                      onPressed: () => _quickUpdateStatus(block, 'partial', 50),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.cancel_outlined),
                      color: status == 'missed' ? Colors.pinkAccent : Colors.white24,
                      onPressed: () => _quickUpdateStatus(block, 'missed', 0),
                    ),
                  ],
                )
              else
                Text('${rep['completion_percent']}%', style: const TextStyle(color: Colors.white60, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        if (status == 'partial' && !_isAlreadySubmitted)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: Row(
              children: [
                const Text('Completion:', style: TextStyle(color: Colors.white54, fontSize: 11)),
                Expanded(
                  child: Slider(
                    value: (rep['completion_percent'] as int).toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 10,
                    activeColor: _accent,
                    onChanged: (val) {
                      setState(() {
                        rep['completion_percent'] = val.toInt();
                      });
                    },
                  ),
                ),
                Text('${rep['completion_percent']}%', style: TextStyle(color: _accent, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
      ],
    );

  }

  Widget _buildStickyFooter() {
    int total = _blocks.length;
    int completed = _reports.values.where((r) => r['status'] == 'completed').length;
    int missed = _reports.values.where((r) => r['status'] == 'missed').length;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCol(completed.toString().padLeft(2, '0'), 'Total Completed', Colors.tealAccent),
              Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.1)),
              _buildStatCol(missed.toString().padLeft(2, '0'), 'Total Missed', Colors.pinkAccent),
              Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.1)),
              _buildStatCol(total.toString().padLeft(2, '0'), 'Total Tasks', Colors.white),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSubmitting 
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    _isAlreadySubmitted ? 'REPORT SUBMITTED' : 'Submit Daily Report',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatCol(String val, String label, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white54, letterSpacing: 0.5)),
      ],
    );
  }
}

class BlockDetailScreen extends StatefulWidget {
  final int blockId;
  final String title;
  final int plannedDurationMinutes;
  final String initialStatus;
  final int initialCompletion;
  final String initialNotes;

  const BlockDetailScreen({
    super.key,
    required this.blockId,
    required this.title,
    required this.plannedDurationMinutes,
    required this.initialStatus,
    required this.initialCompletion,
    required this.initialNotes,
  });

  @override
  State<BlockDetailScreen> createState() => _BlockDetailScreenState();
}

class _BlockDetailScreenState extends State<BlockDetailScreen> {
  late String _status;
  late int _completion;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _completion = widget.initialCompletion;
    _notesController = TextEditingController(text: widget.initialNotes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(title: Text(widget.title), backgroundColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _status,
              items: ['pending', 'completed', 'partial', 'missed'].map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
              onChanged: (val) => setState(() => _status = val!),
              decoration: const InputDecoration(labelText: 'Status'),
            ),
            const SizedBox(height: 24),
            Text('Completion: $_completion%'),
            Slider(
              value: _completion.toDouble(),
              min: 0,
              max: 100,
              divisions: 10,
              onChanged: (val) => setState(() => _completion = val.toInt()),
            ),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, {
                  'status': _status,
                  'completion_percent': _completion,
                  'notes': _notesController.text,
                }),
                child: const Text('SAVE CHANGES'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
