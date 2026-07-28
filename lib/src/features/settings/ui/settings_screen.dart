import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/validation/sanitizer.dart';
import '../../../theme/dark_variant.dart';
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
          const SizedBox(height: 24),
          Text('Locality', style: theme.textTheme.titleSmall),
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
              helperText: 'The board shows this locality. Switching takes '
                  'effect immediately.',
              helperMaxLines: 2,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: settings.showAllLocalities,
            onChanged: controller.setShowAllLocalities,
            title: const Text('Show all localities'),
            subtitle: const Text('Browse every locality at once instead of '
                'just yours.'),
          ),
          const SizedBox(height: 16),
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
          // Only meaningful when dark can actually appear.
          if (settings.themeMode != ThemeMode.light) ...[
            const SizedBox(height: 12),
            Text('Dark style', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            RadioGroup<DarkVariant>(
              groupValue: settings.darkVariant,
              onChanged: (v) {
                if (v != null) controller.setDarkVariant(v);
              },
              child: Column(
                children: [
                  for (final variant in DarkVariant.values)
                    RadioListTile<DarkVariant>(
                      contentPadding: EdgeInsets.zero,
                      value: variant,
                      title: Text(variant.label),
                      subtitle: Text(variant.description),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text('Sample data', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: settings.hideSamples,
            onChanged: controller.setHideSamples,
            title: const Text('Hide sample listings'),
            subtitle: const Text('Samples are shared illustrative data — '
                'hiding them leaves only real listings. Your own are never '
                'affected.'),
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
