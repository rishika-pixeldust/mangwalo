import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../settings/application/settings_controller.dart';
import '../../../settings/ui/profile_screen.dart';
import '../../../settings/ui/settings_screen.dart';

/// The board's app-bar actions: a notification bell and an avatar menu that
/// holds Profile, Settings and the tutorial replay.
///
/// Two targets rather than three separate icons — a 390px phone can't carry
/// the locality header plus three actions without truncating something.
class BoardActions extends ConsumerWidget {
  const BoardActions({super.key, this.unreadCount = 0, this.onOpenInbox});

  /// Rental requests and messages awaiting you. Zero until the social layer
  /// is wired, at which point only this number changes.
  final int unreadCount;
  final VoidCallback? onOpenInbox;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settings = ref.watch(settingsProvider);
    final name = settings.displayName.isEmpty ? 'You' : settings.displayName;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Bell(
          count: unreadCount,
          onPressed: onOpenInbox ??
              () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Rental requests and messages arrive here '
                        'once you sign in.'),
                  )),
        ),
        const SizedBox(width: 4),
        PopupMenuButton<String>(
          tooltip: 'Your account',
          offset: const Offset(0, 48),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          onSelected: (value) {
            switch (value) {
              case 'profile':
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ProfileScreen()));
              case 'settings':
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const SettingsScreen()));
              case 'tutorial':
                ref.read(settingsProvider.notifier).replayTutorial();
              case 'signin':
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Sign-in is coming with the shared '
                      'noticeboard.'),
                ));
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'profile',
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.person_outline),
                title: Text('Profile'),
              ),
            ),
            PopupMenuItem(
              value: 'settings',
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.settings_outlined),
                title: Text('Settings'),
              ),
            ),
            PopupMenuItem(
              value: 'tutorial',
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.help_outline),
                title: Text('How it works'),
              ),
            ),
            PopupMenuDivider(),
            PopupMenuItem(
              value: 'signin',
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.login),
                title: Text('Sign in'),
              ),
            ),
          ],
          child: Semantics(
            label: 'Your account, $name',
            button: true,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Text(
                name.characters.first.toUpperCase(),
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: scheme.onPrimaryContainer),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Bell extends StatelessWidget {
  const _Bell({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: count == 0
          ? 'Requests and messages, none new'
          : 'Requests and messages, $count new',
      button: true,
      child: ExcludeSemantics(
        child: IconButton(
          onPressed: onPressed,
          iconSize: 24,
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text('$count'),
            backgroundColor: scheme.error,
            textColor: scheme.onError,
            child: const Icon(Icons.notifications_none_rounded),
          ),
        ),
      ),
    );
  }
}
