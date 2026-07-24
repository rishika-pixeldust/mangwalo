import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/security/pin.dart';
import '../../../core/validation/sanitizer.dart';
import '../../listings/application/listing_providers.dart';
import '../application/settings_controller.dart';

/// Simple one-field text prompt; returns null on cancel.
Future<String?> _promptText(BuildContext context,
    {required String title, String initial = ''}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 30,
        textCapitalization: TextCapitalization.words,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context)
              .pop(sanitize(controller.text, maxLength: 30)),
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

/// Set / change / remove the app PIN. Changing requires the current PIN.
Future<void> _managePin(BuildContext context, WidgetRef ref) async {
  final controller = ref.read(settingsProvider.notifier);
  final hasPin = ref.read(settingsProvider).pinEnabled;
  final current = TextEditingController();
  final next = TextEditingController();

  final action = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(hasPin ? 'Change app PIN' : 'Set app PIN'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasPin)
            TextField(
              controller: current,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                  labelText: 'Current PIN', counterText: ''),
            ),
          TextField(
            controller: next,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
                labelText: 'New PIN (4–6 digits)',
                helperText: 'Leave empty to remove the lock.',
                counterText: ''),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop('save'),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  if (action != 'save') return;
  if (hasPin && !controller.verifyPin(current.text.trim())) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Current PIN didn\'t match — nothing changed.')));
    }
    return;
  }
  final newPin = next.text.trim();
  if (newPin.isEmpty) {
    await controller.removePin();
  } else if (PinLock.isValidPin(newPin)) {
    await controller.setPin(newPin);
  } else {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('PIN must be 4–6 digits — nothing changed.')));
    }
    return;
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(newPin.isEmpty ? 'App lock removed' : 'App lock set')));
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset all local data?'),
        content: const Text(
            'All listings and settings on this device will be deleted and '
            'the app will return to setup. This cannot be undone.'),
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
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final engineInfo = ref.watch(localAiServiceProvider).engineInfo;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Profile', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  settings.displayName.isEmpty
                      ? '?'
                      : settings.displayName[0].toUpperCase(),
                  style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700),
                ),
              ),
              title: Text(settings.displayName.isEmpty
                  ? 'Add your name'
                  : settings.displayName),
              subtitle: const Text('Used on your listings and reviews. '
                  'Stored only on this device.'),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () async {
                final name = await _promptText(
                  context,
                  title: 'Your first name',
                  initial: settings.displayName,
                );
                if (name != null) await controller.setDisplayName(name);
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(
                settings.pinEnabled ? Icons.lock : Icons.lock_open_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text(settings.pinEnabled
                  ? 'App lock is on'
                  : 'Set an app PIN'),
              subtitle: Text(settings.pinEnabled
                  ? 'MangWalo asks for your PIN on launch. Tap to change '
                      'or remove.'
                  : '4–6 digits; locks the app on this device. Only a '
                      'salted hash is stored.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _managePin(context, ref),
            ),
          ),
          const SizedBox(height: 24),
          Text('Neighborhood', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: settings.neighborhood,
            items: [
              for (final n in AppConstants.neighborhoods)
                DropdownMenuItem(value: n, child: Text(n)),
            ],
            onChanged: (value) {
              if (value != null) controller.changeNeighborhood(value);
            },
            decoration: const InputDecoration(
              helperText: 'Your noticeboard shows one neighborhood at a time.',
              helperMaxLines: 2,
            ),
          ),
          const SizedBox(height: 24),
          Text('Appearance', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode_outlined)),
                ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('Auto'),
                    icon: Icon(Icons.brightness_auto_outlined)),
                ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode_outlined)),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (selection) =>
                  controller.setThemeMode(selection.first),
            ),
          ),
          const SizedBox(height: 24),
          Text('Sample data', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          if (settings.seedVersion == 0)
            FilledButton.tonalIcon(
              icon: const Icon(Icons.science_outlined),
              label: const Text('Load sample listings'),
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
              onPressed: () async {
                await controller.loadSamples();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Sample listings loaded')));
                }
              },
            )
          else
            OutlinedButton.icon(
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('Remove sample listings'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
              onPressed: () async {
                await controller.removeSamples();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Sample listings removed — your own '
                          'listings are untouched')));
                }
              },
            ),
          const SizedBox(height: 24),
          Text('Your data', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Everything in ${AppConstants.appName} lives only on this '
            'device. No account, no server, no tracking.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('Reset all local data'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: theme.colorScheme.error,
            ),
            onPressed: () => _confirmReset(context, ref),
          ),
          const SizedBox(height: 24),
          Text('About', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${AppConstants.appName} — ${AppConstants.tagline}',
                      style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Listing helper: ${engineInfo.name}. '
                    '${engineInfo.userFacingNote}',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Built for MAL Lab 1 — local-first architecture, '
                    'accessibility, security, and on-device AI.',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
