import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/security/pin.dart';
import '../../core/validation/sanitizer.dart';
import '../settings/application/settings_controller.dart';
import 'pin_gate_screen.dart';

/// First launch: pick your neighborhood (single-neighborhood scope) and
/// optionally start with clearly-marked sample listings.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  String? _selected;
  bool _saving = false;
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  String? _pinError;

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final neighborhood = _selected;
    if (neighborhood == null) return;
    final pin = _pinController.text.trim();
    if (pin.isNotEmpty && !PinLock.isValidPin(pin)) {
      setState(() => _pinError = 'PIN must be 4–6 digits.');
      return;
    }
    setState(() => _saving = true);
    // Setting a PIN during setup shouldn't immediately gate the user —
    // the lock applies from the NEXT launch.
    ref.read(appUnlockedProvider.notifier).unlock();
    await ref.read(settingsProvider.notifier).completeOnboarding(
          neighborhood,
          displayName: sanitize(_nameController.text, maxLength: 30),
          pin: pin.isEmpty ? null : pin,
        );
    // RootGate swaps to the feed once settings update; nothing to pop.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 24),
            Icon(Icons.storefront_outlined,
                size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              AppConstants.appName,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              AppConstants.tagline,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Text('Create your profile', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'A first name for your listings and reviews — no account, '
              'no email, nothing leaves this device.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              maxLength: 30,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Your first name',
                hintText: 'e.g. Rishika',
                counterText: '',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pinController,
              maxLength: 6,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'App PIN (optional)',
                hintText: '4–6 digits',
                counterText: '',
                helperText: 'Locks MangWalo on this device. Only a salted '
                    'hash is stored.',
                helperMaxLines: 2,
                errorText: _pinError,
              ),
              onChanged: (_) {
                if (_pinError != null) setState(() => _pinError = null);
              },
            ),
            const SizedBox(height: 20),
            Text('Pick your neighborhood', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'MangWalo is one noticeboard per neighborhood. Everything you '
              'add stays on this device.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            for (final n in AppConstants.neighborhoods)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 3),
                child: ListTile(
                  title: Text(n),
                  onTap: () => setState(() => _selected = n),
                  selected: _selected == n,
                  trailing: _selected == n
                      ? Icon(Icons.check_circle,
                          color: theme.colorScheme.primary)
                      : const Icon(Icons.circle_outlined),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.science_outlined,
                    size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'We\'ll add a few clearly-marked sample listings so the '
                    'board isn\'t lonely — remove them anytime in Settings.',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _selected == null || _saving ? null : _start,
              icon: const Icon(Icons.arrow_forward),
              label: Text(_saving ? 'Setting up…' : 'Get started'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
