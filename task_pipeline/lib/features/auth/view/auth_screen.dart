import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_pipeline/features/auth/logic/auth_bloc.dart';

/// Sign in / create account, on one screen with a mode toggle.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _creating = false;
  bool _hidePassword = true;
  // True while the request in flight came from the form's submit button (as
  // opposed to "Forgot password?"), so only a failed sign-in touches the password.
  bool _submitted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    final current = context.read<AuthBloc>().state;
    // The fields stay focusable while a request runs (readOnly, not disabled),
    // so Enter can still reach this: ignore it until the request finishes.
    if (current is Unauthenticated && current.busy) return;
    if (!_formKey.currentState!.validate()) return;
    _submitted = true;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final bloc = context.read<AuthBloc>();
    if (_creating) {
      bloc.add(
        SignUpRequested(
          email: email,
          password: password,
          displayName: _nameController.text.trim(),
        ),
      );
    } else {
      bloc.add(SignInRequested(email: email, password: password));
    }
  }

  void _forgotPassword() {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email above first.')),
      );
      return;
    }
    _submitted = false;
    context.read<AuthBloc>().add(PasswordResetRequested(email));
  }

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
              child: BlocConsumer<AuthBloc, AuthState>(
                // A request that was busy has just failed.
                listenWhen: (previous, current) =>
                    previous is Unauthenticated &&
                    previous.busy &&
                    current is Unauthenticated &&
                    !current.busy &&
                    current.error != null,
                listener: (context, state) {
                  if (!_submitted) return;
                  _submitted = false;
                  // Signing in: the password was wrong, so clear it. Either
                  // way, put the cursor back where the next attempt starts.
                  if (!_creating) _passwordController.clear();
                  _passwordFocus.requestFocus();
                },
                builder: (context, state) {
                  final busy = state is Unauthenticated && state.busy;
                  final error = state is Unauthenticated ? state.error : null;
                  final info = state is Unauthenticated ? state.info : null;
                  return AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Task Pipeline',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _creating
                                ? 'Create your account'
                                : 'Sign in to continue',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          if (_creating) ...[
                            TextFormField(
                              controller: _nameController,
                              readOnly: busy,
                              textInputAction: TextInputAction.next,
                              textCapitalization: TextCapitalization.words,
                              autofillHints: const [AutofillHints.name],
                              decoration: const InputDecoration(
                                labelText: 'Display name',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) => (value ?? '').trim().isEmpty
                                  ? 'Enter a name'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                          ],
                          TextFormField(
                            controller: _emailController,
                            readOnly: busy,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => (value ?? '').contains('@')
                                ? null
                                : 'Enter a valid email',
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            readOnly: busy,
                            obscureText: _hidePassword,
                            textInputAction: TextInputAction.done,
                            autofillHints: [
                              _creating
                                  ? AutofillHints.newPassword
                                  : AutofillHints.password,
                            ],
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                tooltip: _hidePassword
                                    ? 'Show password'
                                    : 'Hide password',
                                icon: Icon(
                                  _hidePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(
                                  () => _hidePassword = !_hidePassword,
                                ),
                              ),
                            ),
                            validator: (value) => (value ?? '').length < 6
                                ? 'At least 6 characters'
                                : null,
                          ),
                          if (error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                error,
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          if (info != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(info),
                            ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: busy ? null : _submit,
                            child: busy
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _creating ? 'Create account' : 'Sign in',
                                  ),
                          ),
                          if (!_creating)
                            TextButton(
                              onPressed: busy ? null : _forgotPassword,
                              child: const Text('Forgot password?'),
                            ),
                          TextButton(
                            onPressed: busy
                                ? null
                                : () => setState(() => _creating = !_creating),
                            child: Text(
                              _creating
                                  ? 'I already have an account'
                                  : 'Create an account',
                            ),
                          ),
                        ],
                      ),
                    ),
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
