import 'package:flutter/material.dart';

import '../../listings/domain/date_range.dart';

/// A month grid showing which days a listing is free, and letting the renter
/// drag out a range across the free ones.
///
/// Blocked days are not merely styled differently — they are unselectable, and
/// a selection cannot span across one. That is deliberate: the database's
/// exclusion constraint would reject an overlapping booking anyway, so letting
/// someone build an invalid range only to fail on submit would be a worse
/// experience than never offering it.
class AvailabilityCalendar extends StatefulWidget {
  const AvailabilityCalendar({
    super.key,
    required this.availability,
    required this.onRangeChanged,
    required this.today,
    this.maxMonthsAhead = 6,
  });

  final Availability availability;

  /// Null while the selection is incomplete (a start with no end yet).
  final ValueChanged<DateRange?> onRangeChanged;

  /// Injected rather than DateTime.now() so the widget is testable.
  final DateTime today;
  final int maxMonthsAhead;

  @override
  State<AvailabilityCalendar> createState() => _AvailabilityCalendarState();
}

class _AvailabilityCalendarState extends State<AvailabilityCalendar> {
  late DateTime _month;
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    _month = DateTime(widget.today.year, widget.today.month);
  }

  DateTime get _firstMonth => DateTime(widget.today.year, widget.today.month);
  DateTime get _lastMonth => DateTime(
      widget.today.year, widget.today.month + widget.maxMonthsAhead);

  bool _isPast(DateTime day) =>
      day.isBefore(DateTime(widget.today.year, widget.today.month, widget.today.day));

  bool _isBlocked(DateTime day) => !widget.availability.isFreeOn(day);

  bool _selectable(DateTime day) => !_isPast(day) && !_isBlocked(day);

  void _tap(DateTime day) {
    if (!_selectable(day)) return;
    setState(() {
      // Fresh start when nothing is chosen, or when a complete range exists,
      // or when the tap is before the current start.
      if (_start == null || _end != null || day.isBefore(_start!)) {
        _start = day;
        _end = null;
        widget.onRangeChanged(null);
        return;
      }
      // Second tap completes the range. End is exclusive, so tapping the 14th
      // after the 12th means 12–14 inclusive: three nights.
      final candidate = DateRange(_start!, day.add(const Duration(days: 1)));
      // Refuse a span that jumps over blocked days — the constraint would.
      if (!widget.availability.isFree(candidate)) {
        _start = day;
        _end = null;
        widget.onRangeChanged(null);
        return;
      }
      _end = day;
      widget.onRangeChanged(candidate);
    });
  }

  bool _inSelection(DateTime day) {
    if (_start == null) return false;
    if (_end == null) return day == _start;
    return !day.isBefore(_start!) && !day.isAfter(_end!);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Monday-first, matching Indian convention.
    final firstOfMonth = DateTime(_month.year, _month.month);
    final leadingBlanks = (firstOfMonth.weekday - 1) % 7;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous month',
              onPressed: _month.isAfter(_firstMonth)
                  ? () => setState(() =>
                      _month = DateTime(_month.year, _month.month - 1))
                  : null,
            ),
            Expanded(
              child: Text(
                _monthLabel(_month),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next month',
              onPressed: _month.isBefore(_lastMonth)
                  ? () => setState(() =>
                      _month = DateTime(_month.year, _month.month + 1))
                  : null,
            ),
          ],
        ),
        Row(
          children: [
            for (final d in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
              Expanded(
                child: Center(
                  child: Text(d,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: leadingBlanks + daysInMonth,
          itemBuilder: (context, i) {
            if (i < leadingBlanks) return const SizedBox.shrink();
            final day = DateTime(_month.year, _month.month, i - leadingBlanks + 1);
            return _DayCell(
              day: day,
              selectable: _selectable(day),
              blocked: _isBlocked(day) && !_isPast(day),
              selected: _inSelection(day),
              isRangeStart: _start != null && day == _start,
              isRangeEnd: _end != null && day == _end,
              onTap: () => _tap(day),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _Legend(color: scheme.primary, label: 'Selected'),
            const SizedBox(width: 16),
            _Legend(
                color: scheme.surfaceContainerHighest, label: 'Already booked'),
          ],
        ),
      ],
    );
  }

  static String _monthLabel(DateTime m) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${names[m.month - 1]} ${m.year}';
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selectable,
    required this.blocked,
    required this.selected,
    required this.isRangeStart,
    required this.isRangeEnd,
    required this.onTap,
  });

  final DateTime day;
  final bool selectable;
  final bool blocked;
  final bool selected;
  final bool isRangeStart;
  final bool isRangeEnd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color bg;
    final Color fg;
    if (selected) {
      bg = scheme.primary;
      fg = scheme.onPrimary;
    } else if (blocked) {
      bg = scheme.surfaceContainerHighest;
      fg = scheme.onSurfaceVariant.withValues(alpha: 0.6);
    } else if (!selectable) {
      bg = Colors.transparent;
      fg = scheme.onSurfaceVariant.withValues(alpha: 0.35);
    } else {
      bg = Colors.transparent;
      fg = scheme.onSurface;
    }

    // One announcement per day, stating availability rather than leaving a
    // screen-reader user to infer it from colour.
    final state = selected
        ? 'selected'
        : blocked
            ? 'already booked'
            : selectable
                ? 'available'
                : 'unavailable';

    return Semantics(
      label: '${day.day} ${_month(day.month)}, $state',
      button: selectable,
      excludeSemantics: true,
      child: InkWell(
        onTap: selectable ? onTap : null,
        customBorder: const CircleBorder(),
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: (isRangeStart || isRangeEnd)
                ? Border.all(color: scheme.primary, width: 2)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            '${day.day}',
            style: TextStyle(
              color: fg,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              decoration: blocked ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ),
    );
  }

  static String _month(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][m - 1];
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
