import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Injectable time source so due-date logic is testable with a pinned clock.
final nowProvider = Provider<DateTime Function()>((ref) => DateTime.now);
