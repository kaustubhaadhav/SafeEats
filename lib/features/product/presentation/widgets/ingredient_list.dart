import 'package:flutter/material.dart';

class IngredientList extends StatelessWidget {
  final List<String> ingredients;
  final List<String> flaggedIngredients;

  const IngredientList({
    super.key,
    required this.ingredients,
    this.flaggedIngredients = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (ingredients.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Text(
              'No ingredient information available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: ingredients.map((ingredient) {
          final isFlagged = _isIngredientFlagged(ingredient);
          return _IngredientChip(
            ingredient: ingredient,
            isFlagged: isFlagged,
          );
        }).toList(),
      ),
    );
  }

  bool _isIngredientFlagged(String ingredient) {
    final normalizedIngredient = ingredient.toLowerCase().trim();
    return flaggedIngredients.any(
      (flagged) => flagged.toLowerCase().trim() == normalizedIngredient,
    );
  }
}

class _IngredientChip extends StatelessWidget {
  final String ingredient;
  final bool isFlagged;

  const _IngredientChip({
    required this.ingredient,
    required this.isFlagged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isFlagged) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber,
              size: 14,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 4),
            Text(
              ingredient,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        ingredient,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class ExpandableIngredientList extends StatefulWidget {
  final List<String> ingredients;
  final List<String> flaggedIngredients;
  final int initialDisplayCount;

  const ExpandableIngredientList({
    super.key,
    required this.ingredients,
    this.flaggedIngredients = const [],
    this.initialDisplayCount = 10,
  });

  @override
  State<ExpandableIngredientList> createState() =>
      _ExpandableIngredientListState();
}

class _ExpandableIngredientListState extends State<ExpandableIngredientList> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final displayedIngredients = _isExpanded
        ? widget.ingredients
        : widget.ingredients.take(widget.initialDisplayCount).toList();

    final hasMore = widget.ingredients.length > widget.initialDisplayCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IngredientList(
          ingredients: displayedIngredients,
          flaggedIngredients: widget.flaggedIngredients,
        ),
        if (hasMore) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              icon: Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
              ),
              label: Text(
                _isExpanded
                    ? 'Show less'
                    : 'Show all ${widget.ingredients.length} ingredients',
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class IngredientTextView extends StatelessWidget {
  final String? ingredientsText;
  final List<String> flaggedIngredients;

  const IngredientTextView({
    super.key,
    this.ingredientsText,
    this.flaggedIngredients = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (ingredientsText == null || ingredientsText!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Text(
              'No ingredient information available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: _buildHighlightedText(context),
    );
  }

  Widget _buildHighlightedText(BuildContext context) {
    if (flaggedIngredients.isEmpty) {
      return Text(
        ingredientsText!,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    // Build rich text with highlighted flagged ingredients
    final spans = <TextSpan>[];
    String remaining = ingredientsText!;

    while (remaining.isNotEmpty) {
      int earliestMatch = -1;
      int matchLength = 0;

      // Find the earliest occurrence of any flagged ingredient
      for (final flagged in flaggedIngredients) {
        final index = remaining.toLowerCase().indexOf(flagged.toLowerCase());
        if (index != -1 && (earliestMatch == -1 || index < earliestMatch)) {
          earliestMatch = index;
          matchLength = flagged.length;
        }
      }

      if (earliestMatch == -1) {
        // No more matches, add the rest as plain text
        spans.add(TextSpan(text: remaining));
        break;
      }

      // Add text before the match
      if (earliestMatch > 0) {
        spans.add(TextSpan(text: remaining.substring(0, earliestMatch)));
      }

      // Add the highlighted match
      spans.add(
        TextSpan(
          text: remaining.substring(earliestMatch, earliestMatch + matchLength),
          style: TextStyle(
            backgroundColor:
                Theme.of(context).colorScheme.error.withValues(alpha: 0.2),
            color: Theme.of(context).colorScheme.error,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      remaining = remaining.substring(earliestMatch + matchLength);
    }

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium,
        children: spans,
      ),
    );
  }
}