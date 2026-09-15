import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  static const _inspirationSlips = [
    'Why analog tools endure in a digital era',
    'The sourdough paradox: craft vs convenience',
    'The sociology of coffee shops as third spaces',
    'The myth of 10x engineering velocity',
  ];

  @override
  void dispose() {
    _topicController.dispose();
    _audienceController.dispose();
    super.dispose();
  }

  void _applyInspiration(String slip) {
    setState(() {
      _topicController.text = slip;
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
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.lg)),
        title: Text(
          'Leave the Desk?',
          style: GoogleFonts.fraunces(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'Your active sessions and history remain safely preserved in the cloud.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
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
          _buildEditorialDesk(),
          const HistoryScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.borderSubtle, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedTab,
          onDestinationSelected: (index) {
            setState(() => _selectedTab = index);
            if (index == 1) BlogHistoryStore.instance.load();
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.edit_note_rounded),
              selectedIcon: Icon(Icons.edit_rounded),
              label: 'Editorial Desk',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_edu_rounded),
              selectedIcon: Icon(Icons.menu_book_rounded),
              label: 'Archive & History',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorialDesk() {
    final user = FirebaseAuth.instance.currentUser;
    return SafeArea(
      child: LayoutBuilder(builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 720;
        final horizontal = isNarrow ? 20.0 : 56.0;

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
                  // Top Masthead & Account Bar
                  _buildMasthead(user),
                  const SizedBox(height: 52),

                  // Hero Headline in Fraunces
                  Text(
                    'Turn a passing thought into\na published essay.',
                    style: GoogleFonts.fraunces(
                      fontSize: isNarrow ? 32 : 44,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.8,
                      height: 1.15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),
                  Text(
                    'Three specialized agents survey the evidence, craft the narrative, and hone the prose. You retain final editorial authority.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isNarrow ? 15 : 17,
                      height: 1.6,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Architectural Pipeline Station Bay (Resting State)
                  _PipelineRestBay(isNarrow: isNarrow),
                  const SizedBox(height: 44),

                  // The Manuscript Intake Docket
                  _buildManuscriptDocket(isNarrow),
                  const SizedBox(height: 40),

                  // Colophon Footer
                  _buildColophon(),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMasthead(User? user) {
    return Row(
      children: [
        const _BrandMark(),
        const Spacer(),
        if (user != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.xs + 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(Radii.pill),
              border: Border.all(color: AppColors.border),
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
                  const Icon(
                    Icons.account_circle_outlined,
                    size: 20,
                    color: AppColors.accent,
                  ),
                const SizedBox(width: Spacing.sm),
                Text(
                  user.displayName?.split(' ').first ?? 'Author',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: Spacing.xs),
                IconButton(
                  tooltip: 'Sign out',
                  icon: const Icon(Icons.logout_rounded, size: 16),
                  color: AppColors.textSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: _signOut,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildManuscriptDocket(bool isNarrow) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Docket Header Banner
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.xl,
                vertical: Spacing.md + 2,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(Radii.lg - 1),
                  topRight: Radius.circular(Radii.lg - 1),
                ),
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    'MANUSCRIPT INTAKE DOCKET',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.4,
                      color: AppColors.accent,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'ISSUE 01',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            // Main Docket Content
            Padding(
              padding: EdgeInsets.all(isNarrow ? Spacing.lg : Spacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Field 1: Topic
                  Row(
                    children: [
                      Text(
                        'TOPIC OR CENTRAL THESIS',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.3,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('*', style: TextStyle(color: AppColors.accent)),
                    ],
                  ),
                  const SizedBox(height: Spacing.sm),
                  TextFormField(
                    controller: _topicController,
                    minLines: 2,
                    maxLines: 4,
                    textInputAction: TextInputAction.next,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'e.g. Why every engineer secretly dreams of working with their hands...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        color: AppColors.textMuted,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                      alignLabelWithHint: true,
                      fillColor: AppColors.surfaceElevated,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Provide a topic or question to dispatch the agents';
                      }
                      if (value.trim().length > 500) {
                        return 'Topic must be under 500 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: Spacing.md),

                  // Prompt Inspiration Slips
                  Text(
                    'INSPIRATION SLIPS (TAP TO INSCRIBE):',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      letterSpacing: 1.2,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.sm,
                    children: _inspirationSlips.map((slip) {
                      return InkWell(
                        onTap: () => _applyInspiration(slip),
                        borderRadius: BorderRadius.circular(Radii.sm),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.md,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(Radii.sm),
                            border: Border.all(
                              color: AppColors.borderSubtle,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.add_rounded,
                                size: 13,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                slip,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: Spacing.xl),

                  // Field 2: Audience
                  Text(
                    'TARGET AUDIENCE & EDITORIAL TONE',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.3,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  TextFormField(
                    controller: _audienceController,
                    onFieldSubmitted: (_) => _start(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. Curious minds, tech practitioners, essay readers',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.groups_2_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      fillColor: AppColors.surfaceElevated,
                    ),
                    validator: (value) {
                      if (value != null && value.trim().length > 200) {
                        return 'Audience description must be under 200 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: Spacing.xxl),

                  // Breaking the SaaS CTA Rule: The Manuscript Dispatch Bar
                  _buildDispatchBar(isNarrow),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDispatchBar(bool isNarrow) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: AppColors.border),
      ),
      child: isNarrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ESTIMATED DISPATCH: ~90 SECONDS',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.md),
                ElevatedButton.icon(
                  onPressed: _start,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('COMMENCE DRAFTING'),
                ),
              ],
            )
          : Row(
              children: [
                const SizedBox(width: Spacing.sm),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.done,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Text(
                  '3 AGENTS READY',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: AppColors.done,
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Text(
                  '•   EST. PIPELINE TIME: ~90s',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _start,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.xxl,
                      vertical: Spacing.lg,
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('COMMENCE DRAFTING'),
                ),
              ],
            ),
    );
  }

  Widget _buildColophon() {
    return Center(
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 24, height: 1, color: AppColors.border),
              const SizedBox(width: Spacing.sm),
              const Icon(Icons.auto_stories_outlined,
                  size: 14, color: AppColors.textMuted),
              const SizedBox(width: Spacing.sm),
              Container(width: 24, height: 1, color: AppColors.border),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'DRAFTLINE PRESS · THREE-STAGE SEQUENTIAL COMPOSITION · AUTONOMOUS AGENTS',
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              letterSpacing: 1.3,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Brand Mark Widget
// ---------------------------------------------------------------------------

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.history_edu_rounded,
            size: 18,
            color: AppColors.onAccent,
          ),
        ),
        const SizedBox(width: Spacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DRAFTLINE',
              style: GoogleFonts.fraunces(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'THE EDITORIAL DESK',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Architectural Pipeline Rest Bay Widget
// ---------------------------------------------------------------------------

class _PipelineRestBay extends StatelessWidget {
  final bool isNarrow;

  const _PipelineRestBay({required this.isNarrow});

  @override
  Widget build(BuildContext context) {
    final stations = [
      (
        step: '01',
        phase: 'RESEARCH',
        archetype: 'The Cartographer',
        icon: Icons.explore_outlined,
        focus: 'Surveys angles, maps evidence & outlines structure.',
        artifact: 'Thesis & Outline Brief',
      ),
      (
        step: '02',
        phase: 'WRITE',
        archetype: 'The Wordsmith',
        icon: Icons.history_edu_rounded,
        focus: 'Shapes narrative prose, voice, and thematic cadence.',
        artifact: 'Full First Draft',
      ),
      (
        step: '03',
        phase: 'EDIT',
        archetype: 'The Critic',
        icon: Icons.auto_fix_normal_rounded,
        focus: 'Prunes surplus phrases, tightens flow & polishes.',
        artifact: 'Publication Galley',
      ),
    ];

    if (isNarrow) {
      return Column(
        children: [
          for (var i = 0; i < stations.length; i++) ...[
            _StationCard(station: stations[i]),
            if (i < stations.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Center(
                  child: Container(
                    width: 1,
                    height: 18,
                    color: AppColors.border,
                  ),
                ),
              ),
          ],
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'THE COMPOSITION PIPELINE',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                  color: AppColors.textMuted,
                ),
              ),
              const Spacer(),
              Text(
                'SEQUENTIAL INTELLIGENCE',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < stations.length; i++) ...[
                Expanded(
                  child: _StationCard(station: stations[i]),
                ),
                if (i < stations.length - 1)
                  const Padding(
                    padding: EdgeInsets.only(top: 36, left: 8, right: 8),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: AppColors.borderHover,
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StationCard extends StatelessWidget {
  final ({
    String step,
    String phase,
    String archetype,
    IconData icon,
    String focus,
    String artifact,
  }) station;

  const _StationCard({required this.station});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Kicker + Icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accentSubtle,
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: Text(
                  '${station.step} // ${station.phase}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                station.icon,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),

          // Archetype Name in Fraunces
          Text(
            station.archetype,
            style: GoogleFonts.fraunces(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),

          // Focus Description
          Text(
            station.focus,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: Spacing.md),

          // Artifact Badge
          Row(
            children: [
              const Icon(
                Icons.description_outlined,
                size: 12,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  station.artifact,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
