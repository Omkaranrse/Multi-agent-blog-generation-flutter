import 'package:firebase_auth/firebase_auth.dart';
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
  final _formKey = GlobalKey<FormState>();
  int _selectedTab = 0;

  @override
  void dispose() {
    _topicController.dispose();
    _audienceController.dispose();
    super.dispose();
  }

  void _start() {
    if (!_formKey.currentState!.validate()) return;
    final topic = _topicController.text.trim();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SessionScreen(
        topic: topic,
        audience: _audienceController.text.trim().isEmpty
            ? 'general readers'
            : _audienceController.text.trim(),
      ),
    ));
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.lg)),
        title: const Text('Sign out?'),
        content: const Text('You can sign back in anytime.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      BlogHistoryStore.instance.reset();
      await FirebaseAuth.instance.signOut();
    }
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
    final user = FirebaseAuth.instance.currentUser;
    return SafeArea(
      child: LayoutBuilder(builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;
        final horizontal = isNarrow ? 24.0 : 64.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(horizontal, Spacing.xxl, horizontal, Spacing.huge),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand + user bar
                  Row(
                    children: [
                      const _BrandMark(),
                      const Spacer(),
                      if (user != null) ...[
                        if (user.photoURL != null)
                          CircleAvatar(
                            radius: 14,
                            backgroundImage: NetworkImage(user.photoURL!),
                          ),
                        const SizedBox(width: Spacing.sm),
                        IconButton(
                          tooltip: 'Sign out',
                          icon: const Icon(Icons.logout_rounded, size: 20),
                          color: AppColors.textSecondary,
                          onPressed: _signOut,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 76),

                  // Hero text
                  Text(
                    'Turn a thought into\na finished post.',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: Spacing.lg),
                  Text(
                    'Three focused agents do the heavy lifting. You stay in control at the moments that matter.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 36),

                  // Pipeline preview (responsive)
                  _PipelinePreview(isNarrow: isNarrow),
                  const SizedBox(height: Spacing.huge),

                  // Form
                  Text('Start a new post',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: Spacing.lg),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _topicController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'What should we write about?',
                            hintText: 'e.g. Why sourdough starters die',
                            prefixIcon: Icon(Icons.subject_rounded),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter a topic to get started';
                            }
                            if (value.trim().length > 500) {
                              return 'Topic is too long (max 500 characters)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: Spacing.md),
                        TextFormField(
                          controller: _audienceController,
                          onFieldSubmitted: (_) => _start(),
                          decoration: const InputDecoration(
                            labelText: 'Who is it for?',
                            prefixIcon: Icon(Icons.people_outline_rounded),
                          ),
                          validator: (value) {
                            if (value != null && value.trim().length > 200) {
                              return 'Audience is too long (max 200 characters)';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Spacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _start,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Start writing'),
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
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
        child: const Icon(Icons.edit_rounded,
            size: 16, color: AppColors.onAccent),
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
  const _PipelinePreview({required this.isNarrow});

  final bool isNarrow;

  @override
  Widget build(BuildContext context) {
    const steps = [
      (Icons.search_rounded, 'Research', 'Find the signal'),
      (Icons.edit_note_rounded, 'Write', 'Shape the story'),
      (Icons.auto_fix_high_rounded, 'Edit', 'Polish the result'),
    ];

    if (isNarrow) {
      // Stack vertically on small screens
      return Column(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            Row(children: [
              Icon(steps[i].$1, color: AppColors.textSecondary, size: 20),
              const SizedBox(width: Spacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(steps[i].$2,
                      style: Theme.of(context).textTheme.labelLarge),
                  Text(steps[i].$3,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ]),
            if (i < steps.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 9),
                child: Container(
                    width: 1,
                    height: 20,
                    color: AppColors.border),
              ),
          ],
        ],
      );
    }

    // Horizontal layout for wider screens
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
            padding: EdgeInsets.symmetric(horizontal: Spacing.sm),
            child: Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.border),
          ),
      ],
    ]);
  }
}
