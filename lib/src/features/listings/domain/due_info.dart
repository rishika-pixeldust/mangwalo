import 'package:flutter/foundation.dart';

@immutable
class DueInfo {
  const DueInfo({
    required this.days,
    required this.isOverdue,
    required this.isDueToday,
    required this.label,
  });

  /// Calendar days until due: negative when overdue.
  final int days;
  final bool isOverdue;
  final bool isDueToday;
  final String label;

  /// Overdue and due-today both deserve the attention treatment in the UI.
  bool get needsAttention => isOverdue || isDueToday;
}

/// Both dates are truncated to local calendar days before comparing, so
/// "due tomorrow at any time of day" is always exactly 1 day away.
DueInfo computeDueInfo(DateTime dueDate, DateTime now) {
  final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
  final today = DateTime(now.year, now.month, now.day);
  final days = due.difference(today).inDays;

  final String label;
  if (days < 0) {
    final overdueBy = -days;
    label = overdueBy == 1 ? 'Overdue by 1 day' : 'Overdue by $overdueBy days';
  } else if (days == 0) {
    label = 'Due today';
  } else if (days == 1) {
    label = 'Due tomorrow';
  } else {
    label = 'Due in $days days';
  }

  return DueInfo(
    days: days,
    isOverdue: days < 0,
    isDueToday: days == 0,
    label: label,
  );
}
