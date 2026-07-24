import 'package:flutter/material.dart';

import '../../../../core/validation/sanitizer.dart';
import '../../domain/listing.dart';

/// Optional prefill for the reviewer-name field (the local profile name).

/// Bottom sheet for leaving a review: tappable stars + text that can cover
/// both the item and how the person was to deal with. First name only.
Future<Review?> showAddReviewSheet(BuildContext context,
    {required DateTime now, String initialName = ''}) {
  return showModalBottomSheet<Review>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _AddReviewForm(now: now, initialName: initialName),
    ),
  );
}

class _AddReviewForm extends StatefulWidget {
  const _AddReviewForm({required this.now, required this.initialName});

  final DateTime now;
  final String initialName;

  @override
  State<_AddReviewForm> createState() => _AddReviewFormState();
}

class _AddReviewFormState extends State<_AddReviewForm> {
  int _rating = 5;
  final _text = TextEditingController();
  late final _name = TextEditingController(text: widget.initialName);
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final text = sanitize(_text.text, maxLength: 300, multiline: true);
    if (text.length < 5) {
      setState(() => _error = 'Say a little about the item or the person.');
      return;
    }
    Navigator.of(context).pop(Review(
      rating: _rating,
      text: text,
      reviewerName: sanitize(_name.text, maxLength: 30),
      createdAt: widget.now,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add a review', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'How was the item — and how was the person to deal with?',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                Semantics(
                  label: '$i star${i == 1 ? '' : 's'}',
                  button: true,
                  selected: _rating == i,
                  onTap: () => setState(() => _rating = i),
                  child: ExcludeSemantics(
                    child: IconButton(
                      onPressed: () => setState(() => _rating = i),
                      icon: Icon(
                        i <= _rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 32,
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _text,
            maxLines: 3,
            maxLength: 300,
            decoration: InputDecoration(
              labelText: 'Your review',
              hintText: 'Pristine bag, and a gracious lender…',
              errorText: _error,
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _name,
            maxLength: 30,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Your first name (optional)',
              helperText: 'Stored only on this device.',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _submit,
            child: const Text('Post review'),
          ),
        ],
      ),
    );
  }
}
