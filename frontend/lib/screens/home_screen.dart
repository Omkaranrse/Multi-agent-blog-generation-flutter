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
  final _audienceController = TextEditingController(text: 'General readers');
  final _formKey = GlobalKey<FormState>();
  int _selectedTab = 0;

  static const _suggestions = [
    'Why software teams struggle with documentation',
    'Remote team culture and building trust',
    'Deep work habits for creative projects',
    'The tradeoff between velocity and quality',
  ];

  @override
  void dispose() {
    _topicController.dispose();
    _audienceController.dispose();
    super.dispose();
  }

  void _applySuggestion(String text) {
    setState(() {
      _topicController.text = text;
    });
    _formKey.currentState?.validate();
  }

  void _start() {
    if (!_formKey.currentState!.validate()) return;
    final topic = _topicController.text.trim();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SessionScreen(
        topic: topic,
        audience: _audienceController.text.trim().isEmpty
            ? 'General readers'
            : _audienceController.text.trim(),
      ),
    ));
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You can sign back in anytime.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppThemeTokens.of(context).danger,
            ),
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
    final tokens = AppThemeTokens.of(context);

    return Scaffold(
      backgroundColor: tokens.bgPrimary,
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _buildNewPostScreen(tokens),
          const HistoryScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: tokens.bgSurface,
          border: Border(top: BorderSide(color: tokens.border)),
        ),
        child: NavigationBar(
          selectedIndex: _selectedTab,
          backgroundColor: tokens.bgSurface,
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
      ),
    );
  }

  Widget _buildNewPostScreen(AppThemeTokens tokens) {
    final user = FirebaseAuth.instance.currentUser;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 680;
          final horizontalPadding = isNarrow ? 20.0 : 48.0;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              Spacing.xl,
              horizontalPadding,
              Spacing.huge,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 740),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Bar (Brand, Theme Toggle, Profile)
                    _buildTopBar(tokens, user),
                    SizedBox(height: isNarrow ? 36 : 48),

                    // Headline & Subtitle
                    Text(
                      'Turn an idea into a\nfinished blog post.',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: tokens.textPrimary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: Spacing.md),
                    Text(
                      'Three focused AI agents research, draft, and edit with your review at each step.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: tokens.textMuted,
                            height: 1.5,
                          ),
                    ),
                    SizedBox(height: isNarrow ? 28 : 36),

                    // Pipeline overview at rest
                    _PipelineOverview(tokens: tokens, isNarrow: isNarrow),
                    SizedBox(height: isNarrow ? 32 : 40),

                    // Input Form
                    _buildFormCard(tokens, isNarrow),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar(AppThemeTokens tokens, User? user) {
    return Row(
      children: [
        // Clean Brand Name
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: tokens.accent,
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Icon(
                Icons.edit_note_rounded,
                size: 18,
                color: tokens.onAccent,
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Text(
              'Draftline',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: tokens.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const Spacer(),

        // Theme Mode Toggle
        _ThemeToggle(tokens: tokens),
        const SizedBox(width: Spacing.sm),

        // User Account / Sign Out
        if (user != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm + 2,
              vertical: Spacing.xs,
            ),
            decoration: BoxDecoration(
              color: tokens.bgSurface,
              borderRadius: BorderRadius.circular(Radii.pill),
              border: Border.all(color: tokens.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (user.photoURL != null)
                  CircleAvatar(
                    radius: 12,
                    backgroundImage: NetworkImage(user.photoURL!),
                  )
                else
                  Icon(
                    Icons.account_circle_outlined,
                    size: 20,
                    color: tokens.textMuted,
                  ),
                const SizedBox(width: Spacing.sm),
                Text(
                  user.displayName?.split(' ').first ?? 'User',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: tokens.textPrimary,
                  ),
                ),
                IconButton(
                  tooltip: 'Sign out',
                  icon: const Icon(Icons.logout_rounded, size: 16),
                  color: tokens.textMuted,
                  padding: const EdgeInsets.only(left: 4),
                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                  onPressed: _signOut,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFormCard(AppThemeTokens tokens, bool isNarrow) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: tokens.border),
      ),
      padding: EdgeInsets.all(isNarrow ? Spacing.lg : Spacing.xl),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New post',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: Spacing.lg),

            // Topic field
            Text(
              'Topic',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: Spacing.xs + 2),
            TextFormField(
              controller: _topicController,
              minLines: 2,
              maxLines: 4,
              textInputAction: TextInputAction.next,
              style: TextStyle(
                fontSize: 15,
                color: tokens.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. Why software teams struggle with documentation',
                fillColor: tokens.bgInput,
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

            // Suggestions
            Text(
              'Suggestions',
              style: TextStyle(
                fontSize: 12,
                color: tokens.textMuted,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: _suggestions.map((text) {
                return InkWell(
                  onTap: () => _applySuggestion(text),
                  borderRadius: BorderRadius.circular(Radii.sm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.md,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: tokens.bgInput,
                      borderRadius: BorderRadius.circular(Radii.sm),
                      border: Border.all(color: tokens.border),
                    ),
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 12,
                        color: tokens.textMuted,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: Spacing.xl),

            // Audience field
            Text(
              'Audience',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: Spacing.xs + 2),
            TextFormField(
              controller: _audienceController,
              onFieldSubmitted: (_) => _start(),
              style: TextStyle(
                fontSize: 15,
                color: tokens.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. Software engineers, engineering managers',
                fillColor: tokens.bgInput,
              ),
              validator: (value) {
                if (value != null && value.trim().length > 200) {
                  return 'Audience is too long (max 200 characters)';
                }
                return null;
              },
            ),
            const SizedBox(height: Spacing.xl),

            // CTA Button & Runtime info
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _start,
                style: ElevatedButton.styleFrom(
                  backgroundColor: tokens.accent,
                  foregroundColor: tokens.onAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Start writing'),
              ),
            ),
            const SizedBox(height: Spacing.md),
            Center(
              child: Text(
                'Usually takes 1–2 minutes',
                style: TextStyle(
                  fontSize: 12,
                  color: tokens.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Clean Theme Toggle Widget (System, Light, Dark)
// ---------------------------------------------------------------------------

class _ThemeToggle extends StatelessWidget {
  final AppThemeTokens tokens;

  const _ThemeToggle({required this.tokens});

  @override
  Widget build(BuildContext context) {
    final mode = ThemeController.instance.themeMode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final icon = switch (mode) {
      ThemeMode.system => Icons.brightness_auto_outlined,
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
    };

    final tooltip = switch (mode) {
      ThemeMode.system => 'Theme: System (${isDark ? "Dark" : "Light"})',
      ThemeMode.light => 'Theme: Light',
      ThemeMode.dark => 'Theme: Dark',
    };

    return PopupMenuButton<ThemeMode>(
      tooltip: tooltip,
      icon: Icon(icon, size: 20, color: tokens.textMuted),
      color: tokens.bgSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: tokens.border),
      ),
      initialValue: mode,
      onSelected: (selected) {
        ThemeController.instance.setThemeMode(selected);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: ThemeMode.system,
          child: Row(
            children: [
              Icon(Icons.brightness_auto_outlined, size: 18, color: tokens.textMuted),
              const SizedBox(width: Spacing.sm),
              Text(
                'System default',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: mode == ThemeMode.system ? FontWeight.w600 : FontWeight.w400,
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.light,
          child: Row(
            children: [
              Icon(Icons.light_mode_outlined, size: 18, color: tokens.textMuted),
              const SizedBox(width: Spacing.sm),
              Text(
                'Light',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: mode == ThemeMode.light ? FontWeight.w600 : FontWeight.w400,
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.dark,
          child: Row(
            children: [
              Icon(Icons.dark_mode_outlined, size: 18, color: tokens.textMuted),
              const SizedBox(width: Spacing.sm),
              Text(
                'Dark',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: mode == ThemeMode.dark ? FontWeight.w600 : FontWeight.w400,
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Pipeline Overview at Rest (Clean, Plain Sentence-Case)
// ---------------------------------------------------------------------------

class _PipelineOverview extends StatelessWidget {
  final AppThemeTokens tokens;
  final bool isNarrow;

  const _PipelineOverview({required this.tokens, required this.isNarrow});

  @override
  Widget build(BuildContext context) {
    const steps = [
      (
        icon: Icons.search_rounded,
        title: 'Research',
        desc: 'Find sources and outline key points',
      ),
      (
        icon: Icons.edit_note_rounded,
        title: 'Write',
        desc: 'Draft the complete post',
      ),
      (
        icon: Icons.auto_fix_high_rounded,
        title: 'Edit',
        desc: 'Review and polish the prose',
      ),
    ];

    if (isNarrow) {
      return Container(
        decoration: BoxDecoration(
          color: tokens.bgSurface,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: tokens.border),
        ),
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: tokens.bgInput,
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                    child: Icon(steps[i].icon, size: 18, color: tokens.textMuted),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[i].title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: tokens.textPrimary,
                          ),
                        ),
                        Text(
                          steps[i].desc,
                          style: TextStyle(
                            fontSize: 12,
                            color: tokens.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (i < steps.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
                  child: Divider(color: tokens.borderSubtle, height: 16),
                ),
            ],
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: tokens.border),
      ),
      padding: const EdgeInsets.all(Spacing.lg),
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: tokens.bgInput,
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                    child: Icon(steps[i].icon, size: 18, color: tokens.textMuted),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[i].title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: tokens.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          steps[i].desc,
                          style: TextStyle(
                            fontSize: 12,
                            color: tokens.textMuted,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (i < steps.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: tokens.border,
                ),
              ),
          ],
        ],
      ),
    );
  }
}
