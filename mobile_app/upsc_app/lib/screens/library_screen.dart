import 'package:flutter/material.dart';
import '../services/schedule_service.dart';

class LibraryScreen extends StatefulWidget {
  final VoidCallback? onBackHome;
  const LibraryScreen({super.key, this.onBackHome});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final ScheduleService _api = ScheduleService();
  List<dynamic> _subjects = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';
  List<dynamic> _folders = [];
  List<dynamic> _assets = [];

  // Premium Theme Colors will now use Theme.of(context)
  late Color primary;
  late Color primaryContainer;
  late Color secondary;
  late Color background;
  late Color surface;
  late Color onSurface;
  late Color outlineVariant;
  late Color success;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final List<dynamic> subs = await _api.fetchLibrarySubjects();
      final List<dynamic> folds = await _api.fetchLibraryFolders();
      final List<dynamic> asts = await _api.fetchLibraryAssets();
      
      if (mounted) {
        setState(() {
          _subjects = subs;
          _folders = folds;
          _assets = asts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearch(String query) {
    setState(() => _searchQuery = query.toLowerCase());
  }

  Future<void> _uploadAsset() async {
    setState(() => _isLoading = true);
    final success = await _api.uploadAsset(null); // Passing null as we simulate selection
    if (success) {
      await _loadData();
    }
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Knowledge Ingested: Asset synchronized with library' : 'Sync Error: Asset rejected by portal'),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _newSubject() async {
    String subjectName = '';
    String topic = '';
    String timePeriod = '4 weeks';
    String priority = 'medium';

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('NEW FOCUS AREA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (v) => subjectName = v,
                decoration: const InputDecoration(labelText: 'Subject Name (e.g. Polity)', hintText: 'Polity'),
              ),
              TextField(
                onChanged: (v) => topic = v,
                decoration: const InputDecoration(labelText: 'Focus Topic', hintText: 'Fundamental Rights'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: timePeriod,
                decoration: const InputDecoration(labelText: 'Time Period'),
                items: ['2 weeks', '4 weeks', '8 weeks', '12 weeks'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => timePeriod = v!,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: priority,
                decoration: const InputDecoration(labelText: 'Priority Level'),
                items: ['low', 'medium', 'high'].map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
                onChanged: (v) => priority = v!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              if (subjectName.isNotEmpty) {
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                try {
                  await _api.addLibrarySubject(
                    subjectName: subjectName,
                    topic: topic,
                    timePeriod: timePeriod,
                    priority: priority,
                  );
                  await _loadData();
                } catch (e) {
                  setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('INITIALIZE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    primary = colorScheme.primary;
    primaryContainer = colorScheme.primaryContainer;
    secondary = theme.textTheme.bodyMedium?.color ?? const Color(0xFF515F74);
    background = colorScheme.surface;
    surface = theme.cardColor;
    onSurface = colorScheme.onSurface;
    outlineVariant = theme.dividerColor;
    success = const Color(0xFF006847);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: _isLoading 
          ? Center(child: CircularProgressIndicator(color: primary))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildHeroSection(),
                        const SizedBox(height: 32),
                        _buildHeader(),
                        const SizedBox(height: 32),
                        if (_isSearching)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: TextField(
                              autofocus: true,
                              onChanged: _onSearch,
                              decoration: InputDecoration(
                                hintText: 'Search subjects or assets...',
                                prefixIcon: const Icon(Icons.search_rounded),
                                filled: true,
                                fillColor: surface,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                              ),
                            ),
                          ),
                        _buildSectionHeader('Current Subjects', () => _newSubject(), '+ ADDR'),
                        const SizedBox(height: 16),
                        _buildAssetsGrid(),
                        const SizedBox(height: 32),
                        _buildSectionHeader('Knowledge Folders', () {}, 'NEW DIR'),
                        const SizedBox(height: 16),
                        _buildFoldersGrid(),
                        const SizedBox(height: 48),
                        _buildSectionHeader('Recent Intelligence', () => _uploadAsset(), 'UPLOAD'),
                        const SizedBox(height: 16),
                        _buildIntelligenceList(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (widget.onBackHome != null)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildRoundIcon(Icons.arrow_back_rounded, widget.onBackHome!),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LIBRARY',
                  style: TextStyle(
                    fontFamily: 'Lexend',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4.0,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Central Knowledge Asset Base',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: secondary.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            _buildRoundIcon(Icons.search_rounded, () {
              setState(() => _isSearching = !_isSearching);
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildRoundIcon(IconData icon, VoidCallback onTap) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: outlineVariant.withValues(alpha: 0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Icon(icon, color: onSurface.withValues(alpha: 0.6), size: 20),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Knowledge Hub',
          style: TextStyle(
            fontFamily: 'Lexend',
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
            color: onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Manage your study resources and cognitive assets.',
          style: TextStyle(
            fontSize: 15,
            color: onSurface.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onPressed, String actionText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Lexend',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: onSurface,
            ),
          ),
        ),
        TextButton(
          onPressed: onPressed,
          child: Text(
            actionText,
            style: TextStyle(
              color: primaryContainer,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      width: double.infinity,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: outlineVariant.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(Icons.folder_open_rounded, size: 48, color: outlineVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(fontWeight: FontWeight.w600, color: secondary)),
        ],
      ),
    );
  }

  Widget _buildAssetsGrid() {
    final filteredSubjects = _subjects.where((s) => s['subject_name'].toString().toLowerCase().contains(_searchQuery)).toList();
    
    if (filteredSubjects.isEmpty) {
       return _buildEmptyState('No matching subjects found.');
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: filteredSubjects.length,
      itemBuilder: (context, index) {
        final subject = filteredSubjects[index];
        final title = subject['subject_name'] ?? 'Unknown';
        final accuracy = subject['accuracy'] ?? 0;
        return _buildAssetCard(title, accuracy);
      },
    );
  }

  Widget _buildAssetCard(String title, int accuracy) {
    final icon = _getIconForSubject(title);
    
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: primary, size: 24),
                ),
                const Spacer(),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Lexend',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Proficiency',
                      style: TextStyle(color: secondary.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '$accuracy%',
                      style: TextStyle(color: accuracy > 70 ? success : primary, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: accuracy / 100,
                    backgroundColor: outlineVariant.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(accuracy > 70 ? success : primary),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFoldersGrid() {
    final filteredFolders = _folders.where((f) => f['name'].toString().toLowerCase().contains(_searchQuery)).toList();
    if (filteredFolders.isEmpty) {
       return _buildEmptyState('No folders created yet.');
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: filteredFolders.length,
      itemBuilder: (context, index) {
        final folder = filteredFolders[index];
        final name = folder['name'] ?? 'Folder';
        final desc = folder['description'] ?? '';
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: outlineVariant.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.folder_open_rounded, color: primary, size: 28),
              const Spacer(),
              Text(name, style: TextStyle(fontFamily: 'Lexend', fontSize: 16, fontWeight: FontWeight.w800, color: onSurface)),
              if (desc.isNotEmpty)
                Text(desc, style: TextStyle(fontSize: 11, color: secondary.withValues(alpha: 0.5)), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        );
      },
    );
  }


  Widget _buildIntelligenceList() {
    final filteredAssets = _assets.where((a) => a['title'].toString().toLowerCase().contains(_searchQuery)).toList();
    if (filteredAssets.isEmpty) return _buildEmptyState('No strategic insights found.');

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: List.generate(filteredAssets.length, (index) {
          final item = filteredAssets[index];
          final type = item['asset_type'] ?? 'document';
          
          IconData icon = Icons.article_rounded;
          Color color = primary;
          if (type == 'pdf') { icon = Icons.picture_as_pdf_rounded; color = Colors.red; }
          else if (type == 'image') { icon = Icons.image_rounded; color = Colors.orange; }
          else if (type == 'note') { icon = Icons.notes_rounded; color = Colors.blue; }
          
          return _buildIntelligenceItem(
            item['title'] ?? 'Asset',
            item['meta_info'] ?? 'Knowledge Element',
            icon,
            color,
            item['status'] ?? 'Processing',
            isLast: index == filteredAssets.length - 1,
          );
        }),
      ),
    );
  }

  Widget _buildIntelligenceItem(String title, String meta, IconData icon, Color iconColor, String status, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: outlineVariant.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: TextStyle(fontSize: 11, color: secondary.withValues(alpha: 0.4), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: outlineVariant.withValues(alpha: 0.15)),
            ),
            child: Text(
              status,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: secondary.withValues(alpha: 0.7)),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForSubject(String title) {
    if (title.contains('Polity')) return Icons.gavel_rounded;
    if (title.contains('History')) return Icons.history_edu_rounded;
    if (title.contains('Geo')) return Icons.public_rounded;
    if (title.contains('Eco')) return Icons.account_balance_rounded;
    return Icons.auto_stories_rounded;
  }
}
