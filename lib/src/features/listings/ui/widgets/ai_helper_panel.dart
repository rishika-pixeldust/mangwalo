import 'package:flutter/material.dart';

import '../../../ai/local_ai_service.dart';
import '../../domain/listing.dart';

/// Suggestion chips from the on-device listing helper. Suggestions NEVER
/// auto-fill anything — each chip is an explicit, labeled action, and its
/// applied state is shown with an icon, not color alone.
class AiHelperPanel extends StatelessWidget {
  const AiHelperPanel({
    super.key,
    required this.suggestion,
    required this.engineInfo,
    required this.titleApplied,
    required this.categoryApplied,
    required this.appliedTags,
    required this.durationApplied,
    required this.onApplyTitle,
    required this.onApplyCategory,
    required this.onToggleTag,
    required this.onApplyDuration,
  });

  final ListingSuggestion suggestion;
  final AiEngineInfo engineInfo;
  final bool titleApplied;
  final bool categoryApplied;
  final Set<ConditionTag> appliedTags;
  final bool durationApplied;
  final ValueChanged<String> onApplyTitle;
  final VoidCallback onApplyCategory;
  final ValueChanged<ConditionTag> onToggleTag;
  final VoidCallback onApplyDuration;

  @override
  Widget build(BuildContext context) {
    if (suggestion.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    Widget chip({
      required String text,
      required String semanticAction,
      required bool applied,
      required VoidCallback onTap,
    }) {
      return Semantics(
        label: applied ? 'Applied: $semanticAction' : semanticAction,
        button: true,
        selected: applied,
        // onTap makes the node ACTIVATABLE by screen readers — the flag
        // alone only announces it as a button.
        onTap: onTap,
        child: ExcludeSemantics(
          child: FilterChip(
            avatar: Icon(
              applied ? Icons.check : Icons.auto_awesome,
              size: 16,
            ),
            label: Text(text),
            selected: applied,
            showCheckmark: false,
            onSelected: (_) => onTap(),
          ),
        ),
      );
    }

    return Semantics(
      container: true,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text('Suggestions', style: theme.textTheme.titleSmall),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.offline_bolt_outlined,
                      size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      engineInfo.userFacingNote,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (suggestion.suggestedTitle != null)
                    chip(
                      text: 'Title: ${suggestion.suggestedTitle}',
                      semanticAction:
                          'Apply suggested title: ${suggestion.suggestedTitle}',
                      applied: titleApplied,
                      onTap: () => onApplyTitle(suggestion.suggestedTitle!),
                    ),
                  if (suggestion.suggestedCategory != null)
                    chip(
                      text: suggestion.suggestedCategory!.label,
                      semanticAction: 'Apply suggested category: '
                          '${suggestion.suggestedCategory!.label}',
                      applied: categoryApplied,
                      onTap: onApplyCategory,
                    ),
                  for (final tag in suggestion.conditionTags)
                    chip(
                      text: tag.label,
                      semanticAction: 'Add condition tag: ${tag.label}',
                      applied: appliedTags.contains(tag),
                      onTap: () => onToggleTag(tag),
                    ),
                  if (suggestion.suggestedLoanDuration != null)
                    chip(
                      text: 'Lend for ${suggestion.suggestedLoanDuration!.label}',
                      semanticAction: 'Apply suggested lending duration: '
                          '${suggestion.suggestedLoanDuration!.label}',
                      applied: durationApplied,
                      onTap: onApplyDuration,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
