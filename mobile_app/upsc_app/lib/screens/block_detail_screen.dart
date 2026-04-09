import 'package:flutter/material.dart';

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
    this.initialStatus = 'completed',
    this.initialCompletion = 100,
    this.initialNotes = '',
  });

  @override
  State<BlockDetailScreen> createState() => _BlockDetailScreenState();
}

class _BlockDetailScreenState extends State<BlockDetailScreen> {
  late String _status;
  late double _completion;
  late TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _completion = widget.initialCompletion.toDouble();
    _notesCtrl = TextEditingController(text: widget.initialNotes);
  }

  void _save() {
    Navigator.pop(context, {
      'status': _status,
      'completion_percent': _completion.toInt(),
      'notes': _notesCtrl.text.trim(),
    });
  }

  String _formatDuration(int mins) {
    if (mins < 60) return '$mins m';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    const Color iosGray = Color(0xFFF2F2F7);
    const Color iosBlue = Color(0xFF007AFF);
    const Color iosLabelObj = Color(0xFF3C3C43);
    final Color iosLabel = iosLabelObj.withValues(alpha: 0.6);

    return Scaffold(
      backgroundColor: iosGray,
      appBar: AppBar(
        backgroundColor: iosGray.withValues(alpha: 0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leadingWidth: 80,
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: iosBlue),
          label: const Text('Back', style: TextStyle(color: iosBlue, fontSize: 16)),
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
        ),
        title: const Text('Block Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Done', style: TextStyle(color: iosBlue, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Text(widget.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text('Planned Duration: ${_formatDuration(widget.plannedDurationMinutes)}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: iosLabel)),
            
            const SizedBox(height: 32),
            
            // Status Segmented Control
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text('STATUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: iosLabel, letterSpacing: 0.5)),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _buildSegment('missed', 'Missed'),
                  _buildSegment('partial', 'Partial'),
                  _buildSegment('completed', 'Completed'),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Progress Slider
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0,2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Completion %', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                      Text('${_completion.toInt()}%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: iosBlue)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: iosBlue,
                      inactiveTrackColor: Colors.grey.shade200,
                      thumbColor: Colors.white,
                      trackHeight: 6,
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      value: _completion,
                      min: 0,
                      max: 100,
                      divisions: 100,
                      onChanged: (val) {
                        setState(() {
                          _completion = val;
                          if (val == 0) {
                            _status = 'missed';
                          } else if (val == 100) {
                            _status = 'completed';
                          } else {
                            _status = 'partial';
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Notes Field
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text('OPTIONAL NOTES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: iosLabel, letterSpacing: 0.5)),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0,2))],
              ),
              child: TextField(
                controller: _notesCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'How did it go? Any challenges encountered...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            
            const SizedBox(height: 48),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: iosBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: const Text('Save Progress'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegment(String value, String label) {
    final isSelected = _status == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _status = value;
            if (value == 'missed') _completion = 0;
            if (value == 'completed') _completion = 100;
            if (value == 'partial' && _completion == 100) _completion = 50; 
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0,3))] : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.black : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}
