import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_pipeline/features/auth/logic/auth_bloc.dart';

/// Shown to a signed-in user until their email is verified.
class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is! Authenticated) return const SizedBox.shrink();
                  final bloc = context.read<AuthBloc>();
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.mark_email_unread_outlined,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Verify your email',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We sent a link to ${state.email}. Open it, then come '
                        'back here and continue.',
                        textAlign: TextAlign.center,
                      ),
                      if (state.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            state.error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      if (state.info != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(state.info!, textAlign: TextAlign.center),
                        ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: state.busy
                            ? null
                            : () => bloc.add(VerificationCheckRequested()),
                        child: state.busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text("I've verified my email"),
                      ),
                      OutlinedButton(
                        onPressed: state.busy
                            ? null
                            : () => bloc.add(VerificationEmailRequested()),
                        child: const Text('Resend email'),
                      ),
                      TextButton(
                        onPressed: () => bloc.add(SignOutRequested()),
                        child: const Text('Sign out'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
