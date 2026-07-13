import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/validation/sanitizer.dart';

/// Lend-out details: who is borrowing (first name only — data minimization)
/// and the expected return date, pre-filled with the AI-suggested lending
/// duration when one was accepted.
Future<({DateTime dueDate, String borrowerName})?> showLendOutDialog(
  BuildContext context, {
  required DateTime now,
  int? suggestedDays,
  String initialBorrowerName = '',
}) {
  final today = DateTime(now.year, now.month, now.day);
  return showDialog<({DateTime dueDate, String borrowerName})>(
    context: context,
    builder: (context) => _LendOutDialog(
      today: today,
      initialDueDate: today.add(Duration(days: suggestedDays ?? 7)),
      initialBorrowerName: initialBorrowerName,
    ),
  );
}

class _LendOutDialog extends StatefulWidget {
  const _LendOutDialog({
    required this.today,
    required this.initialDueDate,
    required this.initialBorrowerName,
  });

  final DateTime today;
  final DateTime initialDueDate;
  final String initialBorrowerName;

  @override
  State<_LendOutDialog> createState() => _LendOutDialogState();
}

class _LendOutDialogState extends State<_LendOutDialog> {
  late DateTime _dueDate = widget.initialDueDate;
  late final _nameController =
      TextEditingController(text: widget.initialBorrowerName);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: widget.today,
      lastDate: widget.today.add(const Duration(days: 365)),
      helpText: 'Expected return date',
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Mark as lent out'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            maxLength: 30,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Borrower (optional)',
              hintText: 'First name is enough',
              helperText: 'Stored only on this device.',
            ),
          ),
          const SizedBox(height: 8),
          Text('Return by', style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.event_outlined),
            label: Text(DateFormat('EEE, d MMM yyyy').format(_dueDate)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop((
            dueDate: _dueDate,
            borrowerName: sanitize(_nameController.text, maxLength: 30),
          )),
          child: const Text('Mark lent out'),
        ),
      ],
    );
  }
}
