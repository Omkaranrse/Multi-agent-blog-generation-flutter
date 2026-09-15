import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../models/blog_session.dart';
import '../services/blog_history_service.dart';
import '../services/blog_ws_service.dart';
import '../theme.dart';

const _backendWsUrl = String.fromEnvironment(
  'BACKEND_WS_URL',
  defaultValue: 'ws://localhost:8000',
);

enum _AgentStage { research, write, edit }

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key, required this.topic, required this.audience});

  final String topic;
  final String audience;

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen>
    with SingleTickerProviderStateMixin {
  late final BlogSession _session;
  late final BlogWsService _ws;
  late final AnimationController _pulse;
  final _feedbackController = TextEditingController();
  bool _savedToHistory = false;

  @override
  void initState() {
    super.initState();
    _session = BlogSession();
    _ws = BlogWsService(baseWsUrl: _backendWsUrl);
    _session.addListener(_saveCompletedPost);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
      lowerBound: 0.82,
      upperBound: 1,
    )..repeat(reverse: true);
    _ws.start(
        session: _session, topic: widget.topic, audience: widget.audience);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _session.removeListener(_saveCompletedPost);
    _ws.dispose();
    _feedbackController.dispose();
    _session.dispose();
    super.dispose();
  }

  void _saveCompletedPost() {
    if (_savedToHistory || _session.phase != SessionPhase.done) return;
    final blog = _session.finalBlog;
    if (blog == null || blog.trim().isEmpty) return;
    _savedToHistory = true;
    BlogHistoryStore.instance.add(
      topic: widget.topic,
      audience: widget.audience,
      blog: blog,
    );
  }

  void _copyToClipboard() {
    final blog = _session.finalBlog;
    if (blog == null || blog.isEmpty) return;
    Clipboard.setData(ClipboardData(text: blog));
    if (mounted) {
      final tokens = AppThemeTokens.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            Icon(Icons.check_rounded, color: tokens.success, size: 18),
            const SizedBox(width: Spacing.sm),
            const Text('Copied to clipboard'),
          ]),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);

    return ChangeNotifierProvider.value(
      value: _session,
      child: Scaffold(
        backgroundColor: tokens.bgPrimary,
        appBar: AppBar(
          title: Text(
            widget.topic,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: tokens.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: tokens.bgPrimary,
          leading: IconButton(
            tooltip: 'Leave session',
            icon: Icon(Icons.arrow_back_rounded, color: tokens.textMuted),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: SafeArea(
          child: Consumer<BlogSession>(
            builder: (context, session, _) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 780),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.xxl,
                      vertical: Spacing.lg,
                    ),
                    child: switch (session.phase) {
                      SessionPhase.idle ||
                      SessionPhase.connecting =>
                        _buildConnecting(tokens),
                      SessionPhase.running => _buildRunning(tokens, session),
                      SessionPhase.awaitingResearchReview ||
                      SessionPhase.awaitingDraftReview =>
                        _buildReview(tokens, session),
                      SessionPhase.done => _buildDone(tokens, session),
                      SessionPhase.error => _buildError(tokens, session),
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildConnecting(AppThemeTokens tokens) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: tokens.accent,
          ),
        ),
        const SizedBox(height: Spacing.xl),
        Text(
          'Connecting to the team…',
          style: TextStyle(fontSize: 16, color: tokens.textPrimary),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          'Starting a dedicated graph runner for this post.',
          style: TextStyle(fontSize: 14, color: tokens.textMuted),
        ),
      ],
    );
  }

  Widget _buildRunning(AppThemeTokens tokens, BlogSession session) {
    final stage = _stageForNode(session.activeNode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: Spacing.huge),
        _PipelineStepper(
          active: stage,
          completedThrough: stage.index - 1,
          pulse: _pulse,
          tokens: tokens,
        ),
        const SizedBox(height: 56),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Spacing.xxl),
          decoration: BoxDecoration(
            color: tokens.bgSurface,
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(color: tokens.border),
          ),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, child) =>
                    Transform.scale(scale: _pulse.value, child: child),
                child: Icon(Icons.circle, size: 12, color: tokens.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _stageTitle(stage),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      _stageDescription(stage),
                      style: TextStyle(
                        fontSize: 14,
                        color: tokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.md),
              Text(
                '5–20 sec',
                style: TextStyle(fontSize: 12, color: tokens.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReview(AppThemeTokens tokens, BlogSession session) {
    final isResearch = session.phase == SessionPhase.awaitingResearchReview;
    final title = isResearch ? 'Review the research' : 'Review the draft';
    final eyebrow = isResearch ? 'Step 1 of 2: Research review' : 'Step 2 of 2: Draft review';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: Spacing.sm),
        _PipelineStepper(
          active: isResearch ? _AgentStage.research : _AgentStage.write,
          completedThrough: isResearch ? -1 : 0,
          pulse: _pulse,
          tokens: tokens,
        ),
        const SizedBox(height: 36),
        Text(
          eyebrow,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: tokens.warning,
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: tokens.textPrimary,
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          session.reviewInstructions ??
              'Give this a quick read, then choose how to continue.',
          style: TextStyle(fontSize: 14, color: tokens.textMuted),
        ),
        const SizedBox(height: Spacing.lg),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Spacing.xl),
            decoration: BoxDecoration(
              color: tokens.bgSurface,
              borderRadius: BorderRadius.circular(Radii.md),
              border: Border.all(color: tokens.border),
            ),
            child: SingleChildScrollView(
              child: MarkdownBody(
                data: session.reviewText ?? '',
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(color: tokens.textPrimary, height: 1.65, fontSize: 15),
                  h1: TextStyle(color: tokens.textPrimary, fontSize: 22, fontWeight: FontWeight.w700),
                  h2: TextStyle(color: tokens.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
                  h3: TextStyle(color: tokens.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                  listBullet: TextStyle(color: tokens.textPrimary),
                ),
                selectable: true,
              ),
            ),
          ),
        ),
        const SizedBox(height: Spacing.lg),
        TextField(
          controller: _feedbackController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Optional revision note',
            hintText: 'Tell the agent what to change…',
            prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
          ),
        ),
        const SizedBox(height: Spacing.md),
        LayoutBuilder(builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 500;
          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: _approve,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.accent,
                    foregroundColor: tokens.onAccent,
                  ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Approve and continue'),
                ),
                const SizedBox(height: Spacing.sm),
                OutlinedButton.icon(
                  onPressed: _submitRevision,
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text('Request revision'),
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _submitRevision,
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text('Request revision'),
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _approve,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.accent,
                    foregroundColor: tokens.onAccent,
                  ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Approve and continue'),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildDone(AppThemeTokens tokens, BlogSession session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: Spacing.sm),
        _PipelineStepper(
          active: _AgentStage.edit,
          completedThrough: 2,
          pulse: _pulse,
          tokens: tokens,
        ),
        const SizedBox(height: 36),
        Row(
          children: [
            Icon(Icons.check_circle_rounded, color: tokens.success, size: 20),
            const SizedBox(width: Spacing.sm),
            Text(
              'Finished',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: tokens.success,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _copyToClipboard,
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Copy'),
              style: TextButton.styleFrom(
                foregroundColor: tokens.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          'Your post is ready.',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: tokens.textPrimary,
          ),
        ),
        const SizedBox(height: Spacing.xl),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: readerPaneDecoration(context),
            child: SingleChildScrollView(
              child: MarkdownBody(
                data: session.finalBlog ?? '',
                styleSheet: buildReaderStyleSheet(context),
                selectable: true,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(AppThemeTokens tokens, BlogSession session) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(Spacing.xxl),
        decoration: BoxDecoration(
          color: tokens.bgSurface,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: tokens.danger.withValues(alpha: .3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, color: tokens.danger, size: 32),
            const SizedBox(height: Spacing.lg),
            Text(
              'The session paused unexpectedly',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              session.errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: tokens.textMuted),
            ),
            const SizedBox(height: Spacing.xl),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Return home'),
            ),
          ],
        ),
      ),
    );
  }

  void _approve() {
    _feedbackController.clear();
    _ws.approve();
  }

  void _submitRevision() {
    final feedback = _feedbackController.text.trim();
    if (feedback.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Write a revision note before requesting changes'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    _feedbackController.clear();
    _ws.requestRevision(feedback);
  }

  _AgentStage _stageForNode(String? node) {
    if (node == 'writer_node') return _AgentStage.write;
    if (node == 'editor_node') return _AgentStage.edit;
    return _AgentStage.research;
  }

  String _stageTitle(_AgentStage stage) => switch (stage) {
        _AgentStage.research => 'Researching sources and outline',
        _AgentStage.write => 'Drafting the blog post',
        _AgentStage.edit => 'Polishing the prose',
      };

  String _stageDescription(_AgentStage stage) => switch (stage) {
        _AgentStage.research => 'Gathering facts and structuring the argument.',
        _AgentStage.write => 'Turning the approved outline into a full draft.',
        _AgentStage.edit => 'Reviewing clarity, tone, and final phrasing.',
      };
}

// ---------------------------------------------------------------------------
// Pipeline Stepper
// ---------------------------------------------------------------------------

class _PipelineStepper extends StatelessWidget {
  const _PipelineStepper({
    required this.active,
    required this.completedThrough,
    required this.pulse,
    required this.tokens,
  });

  final _AgentStage active;
  final int completedThrough;
  final Animation<double> pulse;
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    const labels = ['Research', 'Write', 'Edit'];
    const icons = [
      Icons.search_rounded,
      Icons.edit_note_rounded,
      Icons.auto_fix_high_rounded,
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final showLabels = constraints.maxWidth > 400;
      return Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            Expanded(
              child: Row(children: [
                _StepIcon(
                  index: i,
                  active: active.index == i,
                  complete: completedThrough >= i,
                  icon: icons[i],
                  pulse: pulse,
                  tokens: tokens,
                ),
                if (showLabels) ...[
                  const SizedBox(width: Spacing.md),
                  Flexible(
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: active.index == i || completedThrough >= i
                            ? tokens.textPrimary
                            : tokens.textMuted,
                      ),
                    ),
                  ),
                ],
              ]),
            ),
            if (i < labels.length - 1)
              Expanded(
                child: Container(
                  height: 1,
                  color: completedThrough >= i
                      ? tokens.success
                      : tokens.border,
                ),
              ),
          ],
        ],
      );
    });
  }
}

class _StepIcon extends StatelessWidget {
  const _StepIcon({
    required this.index,
    required this.active,
    required this.complete,
    required this.icon,
    required this.pulse,
    required this.tokens,
  });

  final int index;
  final bool active;
  final bool complete;
  final IconData icon;
  final Animation<double> pulse;
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final color = complete
        ? tokens.success
        : active
            ? tokens.accent
            : tokens.textMuted;
    final child = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: active || complete ? .15 : .05),
        border: Border.all(
          color: color.withValues(alpha: active || complete ? .7 : .3),
        ),
      ),
      child: Icon(complete ? Icons.check_rounded : icon, size: 16, color: color),
    );
    return active
        ? AnimatedBuilder(
            animation: pulse,
            builder: (_, child) =>
                Transform.scale(scale: pulse.value, child: child),
            child: child)
        : child;
  }
}
