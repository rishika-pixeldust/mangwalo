import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../settings/application/settings_controller.dart';

/// Session unlock state — true once the PIN has been entered correctly.
/// Resets on every full app launch.
class AppUnlock extends Notifier<bool> {
  @override
  bool build() => false;

  void unlock() => state = true;
}

final appUnlockedProvider = NotifierProvider<AppUnlock, bool>(AppUnlock.new);

/// App lock: gates the UI when a PIN is set. Honest scope — casual-snooping
/// protection on a shared device, with "reset everything" as the only
/// recovery (local-first: there is no one to email a reset link).
class PinGateScreen extends ConsumerStatefulWidget {
  const PinGateScreen({super.key});

  @override
  ConsumerState<PinGateScreen> createState() => _PinGateScreenState();
}

class _PinGateScreenState extends ConsumerState<PinGateScreen> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final ok =
        ref.read(settingsProvider.notifier).verifyPin(_controller.text.trim());
    if (ok) {
      ref.read(appUnlockedProvider.notifier).unlock();
    } else {
      setState(() => _error = 'That PIN doesn\'t match. Try again.');
      _controller.clear();
    }
  }

  Future<void> _forgot() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forgot your PIN?'),
        content: const Text(
            'MangWalo is local-first — there is no account to recover. The '
            'only way back in is to reset ALL local data (listings, photos, '
            'settings). This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset everything'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(settingsProvider.notifier).resetAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = ref.watch(settingsProvider).displayName;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.lock_outline, size: 40, color: scheme.primary),
              const SizedBox(height: 12),
              Text(
                AppConstants.appName,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                name.isEmpty
                    ? 'Enter your PIN to unlock.'
                    : 'Welcome back, $name — enter your PIN.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                autofocus: true,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: theme.textTheme.headlineSmall?.copyWith(
                    fontFamily: 'PlusJakartaSans', letterSpacing: 8),
                decoration: InputDecoration(
                  hintText: '••••',
                  counterText: '',
                  errorText: _error,
                ),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.lock_open_outlined),
                label: const Text('Unlock'),
                onPressed: _submit,
              ),
              TextButton(
                onPressed: _forgot,
                child: const Text('Forgot PIN? Reset all local data'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
