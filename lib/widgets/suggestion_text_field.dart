import 'package:flutter/material.dart';

import 'planner_style.dart';

class SuggestionTextField extends StatelessWidget {
  const SuggestionTextField({
    super.key,
    required this.fieldKey,
    required this.controller,
    required this.focusNode,
    required this.suggestions,
    required this.label,
    this.hint,
    this.enabled = true,
  });

  final String fieldKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> suggestions;
  final String label;
  final String? hint;
  final bool enabled;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => RawAutocomplete<String>(
      key: ValueKey(suggestions.join('\u0000')),
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (value) {
        if (!enabled) return const Iterable<String>.empty();
        final query = value.text.trim().toLowerCase();
        return suggestions
            .where((option) => option.toLowerCase().contains(query))
            .take(8);
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
          TextField(
            key: ValueKey(fieldKey),
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            decoration: InputDecoration(labelText: label, hintText: hint),
            onSubmitted: (_) => onSubmitted(),
          ),
      optionsViewBuilder: (context, onSelected, options) {
        final values = options.toList();
        final highlighted = AutocompleteHighlightedOption.of(context);
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: plannerSurface,
            elevation: 5,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 180,
                maxWidth: constraints.maxWidth,
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: values.length,
                itemBuilder: (context, index) => InkWell(
                  key: ValueKey('$fieldKey-option-${values[index]}'),
                  onTap: () => onSelected(values[index]),
                  child: Container(
                    color: index == highlighted
                        ? const Color(0xFFE5ECE7)
                        : null,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Text(
                      values[index],
                      style: const TextStyle(color: plannerTeal),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
