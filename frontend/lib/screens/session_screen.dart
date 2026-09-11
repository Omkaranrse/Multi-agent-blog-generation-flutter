import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _session,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.topic, overflow: TextOverflow.ellipsis),
          leading: IconButton(
            tooltip: 'Leave session',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: Consumer<BlogSession>(
          builder: (context, session, _) => LayoutBuilder(
            builder: (context, constraints) {
              final horizontal = constraints.maxWidth < 720 ? 20.0 : 64.0;
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOut,
                child: Padding(
                  key: ValueKey(session.phase),
                  padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 32),
                  child: _buildBody(session, constraints.maxWidth),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BlogSession session, double width) {
    final content = switch (session.phase) {
      SessionPhase.idle ||
      SessionPhase.connecting ||
      SessionPhase.running =>
        _buildRunning(session),
      SessionPhase.awaitingResearchReview ||
      SessionPhase.awaitingDraftReview =>
        _buildReview(session),
      SessionPhase.done => _buildDone(session),
      SessionPhase.error => _buildError(session),
    };
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width > 1000 ? 920 : 760),
        child: content,
      ),
    );
  }

  Widget _buildRunning(BlogSession session) {
    final stage = _stageForNode(session.activeNode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text('Your post is taking shape',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
            'The agents are working in sequence. You will be asked to review the important decisions.',
            style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 48),
        _PipelineStepper(
            active: stage, completedThrough: stage.index - 1, pulse: _pulse),
        const SizedBox(height: 56),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, child) =>
                    Transform.scale(scale: _pulse.value, child: child),
                child: const Icon(Icons.circle,
                    size: 12, color: AppColors.working),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_stageTitle(stage),
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(_stageDescription(stage),
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text('5–20 sec', style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReview(BlogSession session) {
    final isResearch = session.phase == SessionPhase.awaitingResearchReview;
    final title = isResearch ? 'Review the research' : 'Review the draft';
    final eyebrow =
        isResearch ? 'YOUR INPUT · 01 OF 02' : 'YOUR INPUT · 02 OF 02';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _PipelineStepper(
          active: isResearch ? _AgentStage.research : _AgentStage.write,
          completedThrough: isResearch ? -1 : 0,
          pulse: _pulse,
        ),
        const SizedBox(height: 42),
        Text(eyebrow,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: AppColors.needsInput)),
        const SizedBox(height: 10),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
            session.reviewInstructions ??
                'Give this a quick read, then choose how to continue.',
            style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 24),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: SingleChildScrollView(
              child: SelectableText(session.reviewText ?? '',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.7,
                      )),
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _feedbackController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Optional revision note',
            hintText: 'Tell the agent what to change...',
            prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _submitRevision(),
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Request revision'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _approve,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Approve and continue'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDone(BlogSession session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _PipelineStepper(
            active: _AgentStage.edit, completedThrough: 2, pulse: _pulse),
        const SizedBox(height: 40),
        Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.done, size: 22),
            const SizedBox(width: 10),
            Text('Finished asset',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: AppColors.done)),
          ],
        ),
        const SizedBox(height: 10),
        Text('Your post is ready.',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F5F0),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: SingleChildScrollView(
              child: Markdown(
                data: session.finalBlog ?? '',
                shrinkWrap: true,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                      color: Color(0xFF24272B), fontSize: 16, height: 1.65),
                  h1: const TextStyle(
                      color: Color(0xFF111315),
                      fontSize: 30,
                      height: 1.2,
                      fontWeight: FontWeight.w800),
                  h2: const TextStyle(
                      color: Color(0xFF111315),
                      fontSize: 22,
                      height: 1.3,
                      fontWeight: FontWeight.w700),
                  h3: const TextStyle(
                      color: Color(0xFF111315),
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                  blockquote: const TextStyle(
                      color: Color(0xFF555C66), fontStyle: FontStyle.italic),
                  blockquoteDecoration: const BoxDecoration(
                      border: Border(
                          left:
                              BorderSide(color: Color(0xFF7CC4FF), width: 3))),
                  blockquotePadding: const EdgeInsets.only(left: 16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(BlogSession session) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.danger.withValues(alpha: .35)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                color: AppColors.danger, size: 30),
            const SizedBox(height: 16),
            Text('The session paused unexpectedly',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(session.errorMessage ?? 'Something went wrong.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Return home')),
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
    if (feedback.isEmpty) return;
    _feedbackController.clear();
    _ws.requestRevision(feedback);
  }

  _AgentStage _stageForNode(String? node) {
    if (node == 'writer_node') return _AgentStage.write;
    if (node == 'editor_node') return _AgentStage.edit;
    return _AgentStage.research;
  }

  String _stageTitle(_AgentStage stage) => switch (stage) {
        _AgentStage.research => 'Researcher is finding the signal',
        _AgentStage.write => 'Writer is shaping the story',
        _AgentStage.edit => 'Editor is polishing the result',
      };

  String _stageDescription(_AgentStage stage) => switch (stage) {
        _AgentStage.research => 'Building an outline from the strongest ideas.',
        _AgentStage.write =>
          'Turning the approved outline into a readable draft.',
        _AgentStage.edit => 'Checking structure, clarity, and final details.',
      };
}

class _PipelineStepper extends StatelessWidget {
  const _PipelineStepper(
      {required this.active,
      required this.completedThrough,
      required this.pulse});

  final _AgentStage active;
  final int completedThrough;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    const labels = ['Research', 'Write', 'Edit'];
    const icons = [
      Icons.search_rounded,
      Icons.edit_note_rounded,
      Icons.auto_fix_high_rounded
    ];
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
              ),
              const SizedBox(width: 10),
              Flexible(
                  child: Text(labels[i],
                      style: Theme.of(context).textTheme.labelLarge)),
            ]),
          ),
          if (i < labels.length - 1)
            Expanded(
                child: Container(
                    height: 1,
                    color: completedThrough >= i
                        ? AppColors.done
                        : AppColors.border)),
        ],
      ],
    );
  }
}

class _StepIcon extends StatelessWidget {
  const _StepIcon(
      {required this.index,
      required this.active,
      required this.complete,
      required this.icon,
      required this.pulse});

  final int index;
  final bool active;
  final bool complete;
  final IconData icon;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final color = complete
        ? AppColors.done
        : active
            ? AppColors.working
            : AppColors.textSecondary;
    final child = Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: active || complete ? .14 : .05),
        border: Border.all(
            color: color.withValues(alpha: active || complete ? .7 : .3)),
      ),
      child:
          Icon(complete ? Icons.check_rounded : icon, size: 17, color: color),
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
