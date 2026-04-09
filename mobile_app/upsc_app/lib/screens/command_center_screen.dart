import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/schedule_service.dart';

class CommandCenterScreen extends StatefulWidget {
  const CommandCenterScreen({super.key});

  @override
  State<CommandCenterScreen> createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends State<CommandCenterScreen> {
  final ScheduleService _api = ScheduleService();
  bool _isLoading = true;
  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Dashboard router is currently disabled on backend.
    // CommandCenter shows with null summary — all values default to 0/safe.
    if (mounted) {
      setState(() {
        _summary = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(colorScheme),
                const SizedBox(height: 32),
                _buildFocusIntensityCard(colorScheme),
                const SizedBox(height: 32),
                _buildEcosystemGrid(colorScheme),
                const SizedBox(height: 32),
                _buildDeviceStatus(colorScheme),
              ],
            ),
          ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colorScheme.primary),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
        ),
        const SizedBox(height: 16),
        Text(
          'COMMAND CENTER',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Ecosystem Health',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1),
        ),
      ],
    );
  }

  Widget _buildFocusIntensityCard(ColorScheme colorScheme) {
    final intensity = (_summary?['completion_percentage_today'] ?? 0) / 100.0;
    
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 15),
          )
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                height: MediaQuery.of(context).size.width * 0.5,
                child: CustomPaint(
                  painter: IntensityGaugePainter(
                    intensity: intensity,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              Column(
                children: [
                  Text(
                    '${(intensity * 100).toInt()}%',
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -2),
                  ),
                  Text(
                    'FOCUS INTENSITY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatMini('Streak', '${_summary?['streak_days'] ?? 0}d', Icons.bolt_rounded, const Color(0xFFF59E0B)),
              _buildStatMini('Pending', '${_summary?['pending_blocks_today'] ?? 0}', Icons.hourglass_empty_rounded, colorScheme.primary),
              _buildStatMini('Stability', 'High', Icons.verified_user_rounded, const Color(0xFF10B981)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatMini(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildEcosystemGrid(ColorScheme colorScheme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildEcoCard('Sync Engine', 'Operational', Icons.sync_rounded, const Color(0xFF10B981)),
        _buildEcoCard('Intelligence', 'Active', Icons.psychology_rounded, const Color(0xFF8B5CF6)),
        _buildEcoCard('Data Archive', 'Cloud', Icons.cloud_done_rounded, colorScheme.primary),
        _buildEcoCard('Network', 'Secure', Icons.security_rounded, const Color(0xFF3B82F6)),
      ],
    );
  }

  Widget _buildEcoCard(String title, String status, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
           Container(
             padding: const EdgeInsets.all(8),
             decoration: BoxDecoration(
               color: color.withValues(alpha: 0.1),
               borderRadius: BorderRadius.circular(12),
             ),
             child: Icon(icon, color: color, size: 18),
           ),
           const SizedBox(width: 12),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                 Text(status, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
               ],
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildDeviceStatus(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('LINKED DEVICES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 20),
          _buildDeviceRow('iPhone 15 Pro', 'Primary Node', Icons.phone_iphone_rounded, true),
          _buildDeviceRow('MacBook Pro M3', 'Development Cell', Icons.laptop_mac_rounded, true),
          _buildDeviceRow('iPad Pro', 'Digital Canvas', Icons.tablet_mac_rounded, false),
        ],
      ),
    );
  }

  Widget _buildDeviceRow(String name, String role, IconData icon, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              Text(role, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
            ],
          ),
          const Spacer(),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF10B981) : Colors.transparent,
              border: isActive ? null : Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class IntensityGaugePainter extends CustomPainter {
  final double intensity;
  final Color color;

  IntensityGaugePainter({required this.intensity, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Background Track
    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    // Progress Arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5,
      false,
      trackPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5 * intensity,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant IntensityGaugePainter oldDelegate) => 
      oldDelegate.intensity != intensity || oldDelegate.color != color;
}
