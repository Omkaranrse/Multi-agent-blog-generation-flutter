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
      duration: const Duration(milliseconds: 2200),
      lowerBound: 0.95,
      upperBound: 1.05,
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              Color(0xFF0F1318),
              Color(0xFF111620),
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.xxxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated brand icon
                  AnimatedBuilder(
                    animation: _iconPulse,
                    builder: (_, child) =>
                        Transform.scale(scale: _iconPulse.value, child: child),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.accent, Color(0xFF5BA8E8)],
                        ),
                        borderRadius: BorderRadius.circular(Radii.xl),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: .25),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.edit_rounded,
                          color: AppColors.onAccent, size: 30),
                    ),
                  ),
                  const SizedBox(height: Spacing.xxxl),

                  // Title
                  Text('Welcome to Draftline',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: Spacing.md),

                  // Subtitle
                  Text(
                    'AI-powered blog writing with human control.\nSign in to get started.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: Spacing.huge),

                  // Features
                  const _FeatureRow(
                    icon: Icons.search_rounded,
                    label: 'Research · Write · Edit',
                  ),
                  const SizedBox(height: Spacing.sm),
                  const _FeatureRow(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'You review every step',
                  ),
                  const SizedBox(height: Spacing.sm),
                  const _FeatureRow(
                    icon: Icons.cloud_outlined,
                    label: 'History synced across devices',
                  ),
                  const SizedBox(height: Spacing.xxxl),

                  // Sign-in button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _signIn,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.onAccent),
                            )
                          : const Icon(Icons.login_rounded),
                      label: Text(
                          _loading ? 'Signing in…' : 'Continue with Google'),
                    ),
                  ),

                  // Error display
                  if (_error != null) ...[
                    const SizedBox(height: Spacing.lg),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(Spacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(Radii.sm),
                        border: Border.all(
                            color: AppColors.danger.withValues(alpha: .3)),
                      ),
                      child: Text(_error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.danger, fontSize: 13)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: Spacing.sm),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textMuted)),
      ],
    );
  }
}
