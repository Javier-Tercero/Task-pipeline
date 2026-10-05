import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_pipeline/features/auth/data/legacy_data_migration.dart';
import 'package:task_pipeline/features/auth/logic/auth_bloc.dart';

/// Account details: display name, email, sign out, and the one-time import of
/// projects saved before accounts existed.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  bool _hasLegacyData = false;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AuthBloc>().state;
    _nameController = TextEditingController(
      text: state is Authenticated ? state.displayName : '',
    );
    _checkLegacyData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _checkLegacyData() async {
    final found = await const LegacyDataMigration().hasLegacyData();
    if (mounted) setState(() => _hasLegacyData = found);
  }

  void _saveName() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    context.read<AuthBloc>().add(DisplayNameUpdateRequested(name));
  }

  Future<void> _import() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Import old projects'),
        content: const Text(
          'This copies every project and task saved before accounts existed '
          'into this account, then deletes the originals.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _importing = true);
    try {
      final count = await const LegacyDataMigration().migrate();
      if (!mounted) return;
      setState(() {
        _importing = false;
        _hasLegacyData = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Imported $count project(s).')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _importing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is! Authenticated) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.email_outlined),
                        title: Text(state.email ?? ''),
                        subtitle: Text(
                          state.emailVerified ? 'Verified' : 'Not verified',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        onSubmitted: (_) => _saveName(),
                        decoration: const InputDecoration(
                          labelText: 'Display name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (state.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            state.error!,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      if (state.info != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(state.info!),
                        ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: state.busy ? null : _saveName,
                        child: const Text('Save name'),
                      ),
                      if (_hasLegacyData) ...[
                        const SizedBox(height: 32),
                        OutlinedButton.icon(
                          onPressed: _importing ? null : _import,
                          icon: _importing
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.move_to_inbox_outlined),
                          label: const Text(
                            'Import projects from before accounts',
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      OutlinedButton.icon(
                        onPressed: () =>
                            context.read<AuthBloc>().add(SignOutRequested()),
                        icon: const Icon(Icons.logout),
                        label: const Text('Sign out'),
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
