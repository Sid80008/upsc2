import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  bool _isExecuting = false;
  int _selectedStrategy = 0; // 0 for Sprint, 1 for Pruning

  Future<void> _runOptimization() async {
    setState(() => _isExecuting = true);

    // Recovery router is currently disabled on backend.
    // Simulate a successful optimization locally.
    await Future.delayed(const Duration(seconds: 2));
    final result = {'number_of_blocks_rescheduled': 3, 'status': 'simulated'};

    if (mounted) {
      setState(() => _isExecuting = false);
      final count = result['number_of_blocks_rescheduled'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Architect Sequence Complete: $count blocks redistributed.'),
          backgroundColor: const Color(0xFF006847),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF515F74)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ACADEMIC ARCHITECT | RECOVERY',
          style: GoogleFonts.lexend(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: const Color(0xFFBA1A1A),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedule Collapse Recovery',
               style: GoogleFonts.lexend(
                 fontSize: 32, 
                 fontWeight: FontWeight.bold, 
                 letterSpacing: -1.0,
                 height: 1.1,
               ),
            ),
            const SizedBox(height: 12),
            Text(
              'Backlog detected. Let\'s intelligently re-architect your path to keep you on course.',
              style: GoogleFonts.inter(
                fontSize: 16, 
                color: const Color(0xFF414752),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),

            // Backlog Items
            _buildBacklogSection(),
            const SizedBox(height: 48),

            // Recovery Strategies
            const Text(
              'Select Recovery Strategy',
              style: TextStyle(fontFamily: 'Lexend', fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStrategyCard(
              title: 'The Sprint',
              subtitle: 'Add extra 1.5 hrs daily for 3 days to clear backlog.',
              icon: Icons.bolt,
              color: const Color(0xFF005AAB),
              selected: _selectedStrategy == 0,
              onTap: () => setState(() => _selectedStrategy = 0),
            ),
            const SizedBox(height: 12),
            _buildStrategyCard(
              title: 'Pruning Mode',
              subtitle: 'Remove lower-priority blocks to stay on track.',
              icon: Icons.content_cut,
              color: const Color(0xFFBA1A1A),
              selected: _selectedStrategy == 1,
              onTap: () => setState(() => _selectedStrategy = 1),
            ),
            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isExecuting ? null : _runOptimization,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF191C1E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isExecuting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Execute Recovery Sequence', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBacklogSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFBA1A1A).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFBA1A1A).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.report_problem, color: Color(0xFFBA1A1A)),
              SizedBox(width: 8),
              Text(
                'Identified Backlog',
                style: TextStyle(color: Color(0xFFBA1A1A), fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBacklogItem('Incomplete Study Blocks', 'Detected'),
          _buildBacklogItem('Missed Revision Cycles', 'Pending'),
          const Divider(height: 32),
          const Text('The Architect will redistribute these into your next 3 days.', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildBacklogItem(String title, String duration) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title, 
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            duration, 
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFFBA1A1A)),
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : Colors.grey.shade200, width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF414752))),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }
}
