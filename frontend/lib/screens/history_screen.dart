import 'package:flutter/material.dart';
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
                padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 48),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('History',
                            style: Theme.of(context).textTheme.displaySmall),
                        const SizedBox(height: 10),
                        Text('Your finished posts, saved on this device.',
                            style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 32),
                        if (history.entries.isEmpty)
                          const _EmptyHistory()
                        else
                          ...history.entries
                              .map((entry) => _HistoryCard(entry: entry)),
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

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry});

  final BlogHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final date =
        MaterialLocalizations.of(context).formatMediumDate(entry.createdAt);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => _HistoryDetailScreen(entry: entry),
        )),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.done.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.article_outlined, color: AppColors.done),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.topic,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 5),
                    Text('$date · ${entry.audience}',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
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

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.auto_stories_outlined,
              color: AppColors.textSecondary, size: 32),
          const SizedBox(height: 14),
          Text('No finished posts yet',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('Your completed posts will appear here.',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _HistoryDetailScreen extends StatelessWidget {
  const _HistoryDetailScreen({required this.entry});

  final BlogHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(entry.topic, overflow: TextOverflow.ellipsis)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F5F0),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: SingleChildScrollView(
              child: Markdown(
                data: entry.blog,
                shrinkWrap: true,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                      color: Color(0xFF24272B), fontSize: 16, height: 1.65),
                  h1: const TextStyle(
                      color: Color(0xFF111315),
                      fontSize: 30,
                      fontWeight: FontWeight.w800),
                  h2: const TextStyle(
                      color: Color(0xFF111315),
                      fontSize: 22,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
