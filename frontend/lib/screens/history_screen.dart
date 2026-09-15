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
    final tokens = AppThemeTokens.of(context);

    return ChangeNotifierProvider.value(
      value: BlogHistoryStore.instance,
      child: Consumer<BlogHistoryStore>(
        builder: (context, history, _) {
          if (!history.loaded) {
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: tokens.accent,
              ),
            );
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 700;
              final horizontal = isNarrow ? 20.0 : 48.0;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  Spacing.xl,
                  horizontal,
                  Spacing.huge,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'History',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: tokens.textPrimary,
                          ),
                        ),
                        const SizedBox(height: Spacing.xs),
                        Text(
                          'Your finished posts, synced across your devices.',
                          style: TextStyle(
                            fontSize: 15,
                            color: tokens.textMuted,
                          ),
                        ),
                        const SizedBox(height: Spacing.xxl),
                        if (history.entries.isEmpty)
                          _EmptyHistory(tokens: tokens)
                        else
                          ...history.entries.map((entry) => _HistoryCard(
                                entry: entry,
                                store: history,
                                tokens: tokens,
                              )),
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
  const _HistoryCard({
    required this.entry,
    required this.store,
    required this.tokens,
  });

  final BlogHistoryEntry entry;
  final BlogHistoryStore store;
  final AppThemeTokens tokens;

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
        backgroundColor: tokens.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          side: BorderSide(color: tokens.border),
        ),
        title: Text(
          'Delete this post?',
          style: TextStyle(color: tokens.textPrimary),
        ),
        content: Text(
          '"${entry.topic}" will be permanently removed.',
          style: TextStyle(color: tokens.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: tokens.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: tokens.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      store.remove(entry.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Post deleted'),
          duration: const Duration(seconds: 2),
          backgroundColor: tokens.bgSurface,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final date =
        MaterialLocalizations.of(context).formatMediumDate(entry.createdAt);
    final timeAgo = _timeAgo(entry.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.md),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: tokens.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => _HistoryDetailScreen(entry: entry),
        )),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: tokens.accent.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: Icon(
                  Icons.article_outlined,
                  color: tokens.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: Spacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.topic,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      '$timeAgo · $date · ${entry.audience}',
                      style: TextStyle(
                        fontSize: 13,
                        color: tokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: tokens.textMuted,
                  size: 20,
                ),
                onPressed: () => _confirmDelete(context),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: tokens.textMuted,
                size: 20,
              ),
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
  final AppThemeTokens tokens;

  const _EmptyHistory({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.huge),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: tokens.bgInput,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.article_outlined,
              color: tokens.textMuted,
              size: 26,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            'No finished posts yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            'Completed posts will appear here, synced to your account.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: tokens.textMuted,
            ),
          ),
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
    final tokens = AppThemeTokens.of(context);

    return Scaffold(
      backgroundColor: tokens.bgPrimary,
      appBar: AppBar(
        title: Text(
          entry.topic,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: tokens.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: tokens.bgPrimary,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: tokens.textMuted),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Copy to clipboard',
            icon: Icon(Icons.copy_rounded, size: 20, color: tokens.textMuted),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: entry.blog));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(children: [
                    Icon(Icons.check_rounded, color: tokens.success, size: 18),
                    const SizedBox(width: Spacing.sm),
                    const Text('Copied to clipboard'),
                  ]),
                  duration: const Duration(seconds: 2),
                  backgroundColor: tokens.bgSurface,
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Container(
            margin: const EdgeInsets.all(Spacing.xl),
            padding: const EdgeInsets.all(Spacing.xxl),
            decoration: readerPaneDecoration(context),
            child: SingleChildScrollView(
              child: MarkdownBody(
                data: entry.blog,
                styleSheet: buildReaderStyleSheet(context),
                selectable: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
