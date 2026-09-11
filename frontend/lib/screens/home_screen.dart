import 'package:flutter/material.dart';

import '../services/blog_history_service.dart';
import '../theme.dart';
import 'history_screen.dart';
import 'session_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _topicController = TextEditingController();
  final _audienceController = TextEditingController(text: 'general readers');
  int _selectedTab = 0;

  @override
  void dispose() {
    _topicController.dispose();
    _audienceController.dispose();
    super.dispose();
  }

  void _start() {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SessionScreen(
        topic: topic,
        audience: _audienceController.text.trim().isEmpty
            ? 'general readers'
            : _audienceController.text.trim(),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _buildNewPost(),
          const HistoryScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) {
          setState(() => _selectedTab = index);
          if (index == 1) BlogHistoryStore.instance.load();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.add_rounded),
            selectedIcon: Icon(Icons.edit_rounded),
            label: 'New post',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            label: 'History',
          ),
        ],
      ),
    );
  }

  Widget _buildNewPost() {
    return SafeArea(
      child: LayoutBuilder(builder: (context, constraints) {
        final horizontal = constraints.maxWidth < 700 ? 24.0 : 64.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 48),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _BrandMark(),
                  const SizedBox(height: 76),
                  Text('Turn a thought into\na finished post.',
                      style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 16),
                  Text(
                    'Three focused agents do the heavy lifting. You stay in control at the moments that matter.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 36),
                  const _PipelinePreview(),
                  const SizedBox(height: 48),
                  Text('Start a new post',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _topicController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'What should we write about?',
                      hintText: 'e.g. Why sourdough starters die',
                      prefixIcon: Icon(Icons.subject_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _audienceController,
                    onSubmitted: (_) => _start(),
                    decoration: const InputDecoration(
                      labelText: 'Who is it for?',
                      prefixIcon: Icon(Icons.people_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _start,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Start writing'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text('Usually takes 1–2 minutes',
                        style: Theme.of(context).textTheme.labelMedium),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(7),
        ),
        child:
            const Icon(Icons.edit_rounded, size: 16, color: Color(0xFF082033)),
      ),
      const SizedBox(width: 10),
      Text('DRAFTLINE',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textPrimary,
                letterSpacing: 1.8,
              )),
    ]);
  }
}

class _PipelinePreview extends StatelessWidget {
  const _PipelinePreview();

  @override
  Widget build(BuildContext context) {
    const steps = [
      (Icons.search_rounded, 'Research', 'Find the signal'),
      (Icons.edit_note_rounded, 'Write', 'Shape the story'),
      (Icons.auto_fix_high_rounded, 'Edit', 'Polish the result'),
    ];
    return Row(children: [
      for (var i = 0; i < steps.length; i++) ...[
        Expanded(
          child: Row(children: [
            Icon(steps[i].$1, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(steps[i].$2,
                      style: Theme.of(context).textTheme.labelLarge),
                  Text(steps[i].$3,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ]),
        ),
        if (i < steps.length - 1)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.border),
          ),
      ],
    ]);
  }
}
