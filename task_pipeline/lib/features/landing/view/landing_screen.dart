import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_pipeline/features/auth/logic/auth_bloc.dart';
import 'package:task_pipeline/features/auth/view/auth_screen.dart';
import 'package:task_pipeline/shared/widgets/cross_pattern_painter.dart';

/// The web front page for visitors who aren't signed in.
///
/// "Get started" drops them straight into the app as a guest (see AuthBloc);
/// "Sign in" is for returning users. All copy here is placeholder text.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  // Below this width the page stacks vertically, as on a phone's browser.
  static const double _wideLayout = 700;

  void _getStarted(BuildContext context) {
    context.read<AuthBloc>().add(GuestStartRequested());
  }

  void _signIn(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AuthScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wide = MediaQuery.sizeOf(context).width >= _wideLayout;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: CrossPatternPainter(color: theme.colorScheme.primary),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final busy = state is Unauthenticated && state.busy;
                      final error = state is Unauthenticated
                          ? state.error
                          : null;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _TopBar(
                            showGetStarted: wide,
                            busy: busy,
                            onSignIn: () => _signIn(context),
                            onGetStarted: () => _getStarted(context),
                          ),
                          SizedBox(height: wide ? 96 : 48),
                          _Hero(
                            busy: busy,
                            error: error,
                            onGetStarted: () => _getStarted(context),
                            onSignIn: () => _signIn(context),
                          ),
                          SizedBox(height: wide ? 96 : 56),
                          const _Features(),
                          const SizedBox(height: 48),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool showGetStarted;
  final bool busy;
  final VoidCallback onSignIn;
  final VoidCallback onGetStarted;

  const _TopBar({
    required this.showGetStarted,
    required this.busy,
    required this.onSignIn,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.view_carousel_outlined, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          'Task Pipeline',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        TextButton(onPressed: onSignIn, child: const Text('Sign in')),
        if (showGetStarted) ...[
          const SizedBox(width: 8),
          FilledButton(
            onPressed: busy ? null : onGetStarted,
            child: const Text('Get started'),
          ),
        ],
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  final bool busy;
  final String? error;
  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;

  const _Hero({
    required this.busy,
    required this.error,
    required this.onGetStarted,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          'Your projects, one card at a time.',
          textAlign: TextAlign.center,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            'Task Pipeline keeps each project on its own card and its tasks '
            'in order, so you always know what to pick up next.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: busy ? null : onGetStarted,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          ),
          child: busy
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Get started'),
        ),
        const SizedBox(height: 8),
        Text('No account needed to try it.', style: theme.textTheme.bodySmall),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        TextButton(
          onPressed: onSignIn,
          child: const Text('Already have an account? Sign in'),
        ),
      ],
    );
  }
}

class _Features extends StatelessWidget {
  const _Features();

  static const _items = [
    (
      icon: Icons.style_outlined,
      title: 'A deck of projects',
      text: 'Flip through your projects like cards and open the one you need.',
    ),
    (
      icon: Icons.shuffle,
      title: 'Pick for me',
      text:
          "Can't decide what's next? Let it pick one of your tasks at random.",
    ),
    (
      icon: Icons.cloud_done_outlined,
      title: 'Always with you',
      text: 'Saved to your account, on the web and on your phone.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Wrap puts the blocks side by side when there's room, and stacks them
    // on narrow screens.
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: [
        for (final item in _items)
          SizedBox(
            width: 300,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.icon, color: theme.colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(item.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(item.text, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
