import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  String? _error;
  late final AnimationController _iconPulse;

  @override
  void initState() {
    super.initState();
    _iconPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
      lowerBound: 0.96,
      upperBound: 1.04,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _iconPulse.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final provider = GoogleAuthProvider();
      if (kIsWeb) {
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        await FirebaseAuth.instance.signInWithProvider(provider);
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = error.message ?? error.code);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);

    return Scaffold(
      backgroundColor: tokens.bgPrimary,
      body: Stack(
        children: [
          // Theme toggle at top right
          Positioned(
            top: Spacing.xl,
            right: Spacing.xl,
            child: IconButton(
              tooltip: 'Toggle light / dark mode',
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                color: tokens.textMuted,
              ),
              onPressed: () => ThemeController.instance.toggle(context),
            ),
          ),

          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(Spacing.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand Icon
                    AnimatedBuilder(
                      animation: _iconPulse,
                      builder: (_, child) =>
                          Transform.scale(scale: _iconPulse.value, child: child),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: tokens.accent,
                          borderRadius: BorderRadius.circular(Radii.lg),
                          boxShadow: [
                            BoxShadow(
                              color: tokens.accent.withValues(alpha: 0.2),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.edit_note_rounded,
                          color: tokens.onAccent,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.xxl),

                    // Title
                    Text(
                      'Welcome to Draftline',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),

                    // Subtitle
                    Text(
                      'AI-assisted blog writing with human control.\nSign in to get started.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: tokens.textMuted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: Spacing.xxxl),

                    // Feature highlights
                    _FeatureRow(
                      tokens: tokens,
                      icon: Icons.search_rounded,
                      label: 'Research, Write, and Edit in sequence',
                    ),
                    const SizedBox(height: Spacing.md),
                    _FeatureRow(
                      tokens: tokens,
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Review and steer each agent before proceeding',
                    ),
                    const SizedBox(height: Spacing.md),
                    _FeatureRow(
                      tokens: tokens,
                      icon: Icons.cloud_outlined,
                      label: 'Cloud sync across your devices',
                    ),
                    const SizedBox(height: Spacing.xxxl),

                    // Sign-in button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tokens.accent,
                          foregroundColor: tokens.onAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Radii.md),
                          ),
                        ),
                        icon: _loading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: tokens.onAccent,
                                ),
                              )
                            : const Icon(Icons.login_rounded, size: 18),
                        label: Text(
                          _loading ? 'Signing in…' : 'Continue with Google',
                        ),
                      ),
                    ),

                    // Error message
                    if (_error != null) ...[
                      const SizedBox(height: Spacing.lg),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(Spacing.md),
                        decoration: BoxDecoration(
                          color: tokens.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(Radii.md),
                          border: Border.all(
                            color: tokens.danger.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: tokens.danger, fontSize: 13),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final AppThemeTokens tokens;
  final IconData icon;
  final String label;

  const _FeatureRow({
    required this.tokens,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: tokens.textMuted),
        const SizedBox(width: Spacing.sm),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: tokens.textMuted,
          ),
        ),
      ],
    );
  }
}
