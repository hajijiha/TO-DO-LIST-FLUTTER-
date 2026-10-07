import 'package:flutter/material.dart';

import '../models/todo.dart';
import 'planner_style.dart';

class TodoTile extends StatelessWidget {
  const TodoTile({
    super.key,
    required this.todo,
    required this.onDelete,
    required this.onToggleCompleted,
    required this.onEdit,
    required this.onRate,
    this.enabled = true,
  });

  final Todo todo;
  final VoidCallback onDelete;
  final VoidCallback onToggleCompleted;
  final VoidCallback onEdit;
  final VoidCallback onRate;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: plannerSurface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: plannerBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  key: ValueKey('complete-todo-${todo.id}'),
                  value: todo.isCompleted,
                  onChanged: enabled ? (_) => onToggleCompleted() : null,
                  semanticLabel: todo.isCompleted ? '미완료로 되돌리기' : '완료 평점 입력',
                  activeColor: plannerTeal,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      todo.title,
                      key: ValueKey('title-todo-${todo.id}'),
                      style: const TextStyle(
                        color: plannerTeal,
                        fontSize: 16,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  key: ValueKey('delete-todo-${todo.id}'),
                  onPressed: enabled ? onDelete : null,
                  tooltip: '${todo.title} 삭제',
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: plannerMuted,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Wrap(
                spacing: 14,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5ECE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      todo.category,
                      key: ValueKey('category-todo-${todo.id}'),
                      style: const TextStyle(color: plannerTeal, fontSize: 12),
                    ),
                  ),
                  _meta(
                    Icons.place_outlined,
                    todo.location,
                    key: ValueKey('location-todo-${todo.id}'),
                  ),
                  _meta(
                    Icons.schedule_rounded,
                    '${todo.estimatedMinutes}분',
                    key: ValueKey('minutes-todo-${todo.id}'),
                  ),
                  _meta(
                    todo.isCompleted
                        ? Icons.star_rounded
                        : Icons.radio_button_unchecked_rounded,
                    todo.isCompleted ? '완료 · ${todo.score}/10점' : '미완료',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: [
                TextButton.icon(
                  key: ValueKey('edit-todo-${todo.id}'),
                  onPressed: enabled ? onEdit : null,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('수정'),
                ),
                if (todo.isCompleted)
                  TextButton.icon(
                    key: ValueKey('rate-todo-${todo.id}'),
                    onPressed: enabled ? onRate : null,
                    icon: const Icon(Icons.star_outline_rounded, size: 16),
                    label: const Text('평점 수정'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text, {Key? key}) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Text.rich(
        TextSpan(
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Icon(icon, size: 15, color: plannerMuted),
              ),
            ),
            TextSpan(text: text),
          ],
        ),
        key: key,
        style: const TextStyle(color: plannerMuted, fontSize: 12, height: 1.4),
      ),
    );
  }
}
