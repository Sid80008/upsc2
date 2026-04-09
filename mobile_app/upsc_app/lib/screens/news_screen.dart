import 'package:flutter/material.dart';
import '../services/schedule_service.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final ScheduleService _api = ScheduleService();
  bool _isLoading = true;
  List<dynamic> _articles = [];

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    final news = await _api.fetchNews();
    if (mounted) {
      setState(() {
        _articles = news;
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
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(colorScheme),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : _articles.isEmpty
                      ? _buildEmptyState()
                      : Column(
                          children: _articles.map((a) => _buildArticleCard(a, colorScheme)).toList(),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 56, vertical: 16),
        title: Text(
          'THE READER',
          style: TextStyle(
            fontFamily: 'Lexend',
            fontWeight: FontWeight.w900,
            color: colorScheme.onSurface,
            fontSize: 16,
            letterSpacing: 2,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
          ),
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 100),
          Icon(Icons.newspaper_rounded, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          const Text('No dispatches available today.', style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildArticleCard(Map<String, dynamic> article, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (article['image_url'] != null) 
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              child: Image.network(
                article['image_url'],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: colorScheme.primary.withValues(alpha: 0.05),
                  child: Icon(Icons.broken_image_rounded, color: colorScheme.primary.withValues(alpha: 0.2)),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        article['category']?.toUpperCase() ?? 'GENERAL',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: colorScheme.primary, letterSpacing: 1),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      article['source'] ?? 'Official Source',
                      style: TextStyle(fontSize: 10, color: colorScheme.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  article['title'] ?? 'No Title',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.2),
                ),
                const SizedBox(height: 12),
                Text(
                  article['content'] ?? 'No content available.',
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.6), height: 1.6),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      '3 MIN READ',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: colorScheme.onSurface.withValues(alpha: 0.3), letterSpacing: 1),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _showArticleDetail(article, colorScheme),
                      child: Row(
                        children: [
                          Text('Read Full', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w800, fontSize: 13)),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 16, color: colorScheme.primary),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showArticleDetail(Map<String, dynamic> article, ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: ListView(
            controller: controller,
            padding: EdgeInsets.zero,
            children: [
              if (article['image_url'] != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  child: Image.network(
                    article['image_url'],
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article['category']?.toUpperCase() ?? 'GENERAL',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: colorScheme.primary, letterSpacing: 2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      article['title'] ?? 'No Title',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1, height: 1.1),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    Text(
                      article['content'] ?? 'Full coverage not available for this dispatch.',
                      style: TextStyle(fontSize: 16, height: 1.8, color: colorScheme.onSurface.withValues(alpha: 0.8)),
                    ),
                    const SizedBox(height: 48),
                    Text(
                      "Source: ${article['source'] ?? 'Verified Intelligence'}",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
