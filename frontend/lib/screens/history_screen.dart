import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../models/blog_history_entry.dart';
import '../services/blog_history_service.dart';
import '../theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    BlogHistoryStore.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: BlogHistoryStore.instance,
      child: Consumer<BlogHistoryStore>(
        builder: (context, history, _) {
          if (!history.loaded) {
            return const Center(child: CircularProgressIndicator());
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final horizontal = constraints.maxWidth < 700 ? 24.0 : 64.0;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    horizontal, Spacing.xxl, horizontal, Spacing.huge),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('History',
                            style: Theme.of(context).textTheme.displaySmall),
                        const SizedBox(height: Spacing.md),
                        Text('Your finished posts, synced across your devices.',
                            style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: Spacing.xxxl),
                        if (history.entries.isEmpty)
                          const _EmptyHistory()
                        else
                          ...history.entries.map((entry) =>
                              _HistoryCard(entry: entry, store: history)),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// History Card
// ---------------------------------------------------------------------------

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry, required this.store});

  final BlogHistoryEntry entry;
  final BlogHistoryStore store;

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.lg)),
        title: const Text('Delete this post?'),
        content: Text(
          '"${entry.topic}" will be permanently removed.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      store.remove(entry.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post deleted'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final date =
        MaterialLocalizations.of(context).formatMediumDate(entry.createdAt);
    final timeAgo = _timeAgo(entry.createdAt);
    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => _HistoryDetailScreen(entry: entry),
        )),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.done.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: const Icon(Icons.article_outlined,
                    color: AppColors.done),
              ),
              const SizedBox(width: Spacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.topic,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: Spacing.xs),
                    Text('$timeAgo · $date · ${entry.audience}',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.textMuted, size: 20),
                onPressed: () => _confirmDelete(context),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty State
// ---------------------------------------------------------------------------

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.huge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: .08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_stories_outlined,
                color: AppColors.textSecondary, size: 28),
          ),
          const SizedBox(height: Spacing.lg),
          Text('No finished posts yet',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: Spacing.sm),
          Text('Completed posts will appear here, synced to your account.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// History Detail Screen
// ---------------------------------------------------------------------------

class _HistoryDetailScreen extends StatelessWidget {
  const _HistoryDetailScreen({required this.entry});

  final BlogHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(entry.topic, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Copy to clipboard',
            icon: const Icon(Icons.copy_rounded, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: entry.blog));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(children: [
                    Icon(Icons.check_rounded, color: AppColors.done, size: 18),
                    SizedBox(width: Spacing.sm),
                    Text('Copied to clipboard'),
                  ]),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Container(
            margin: const EdgeInsets.all(Spacing.xxl),
            padding: const EdgeInsets.symmetric(
                horizontal: 28, vertical: 30),
            decoration: readerPaneDecoration(),
            child: SingleChildScrollView(
              child: MarkdownBody(
                data: entry.blog,
                styleSheet: buildReaderStyleSheet(),
                selectable: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
