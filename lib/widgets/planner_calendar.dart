import 'package:flutter/material.dart';

import '../models/calendar.dart';
import 'planner_style.dart';

class PlannerCalendar extends StatelessWidget {
  const PlannerCalendar({
    super.key,
    required this.month,
    required this.selectedDate,
    required this.scores,
    required this.onSelect,
    required this.onMonth,
    required this.onToday,
    this.noteDates = const {},
  });

  final DateTime month;
  final DateTime selectedDate;
  final Map<String, double> scores;
  final ValueChanged<DateTime> onSelect;
  final ValueChanged<DateTime> onMonth;
  final VoidCallback onToday;
  final Set<String> noteDates;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final leading = first.weekday - 1;
    final days = DateTime(month.year, month.month + 1, 0).day;
    final rows = (leading + days + 6) ~/ 7;
    final today = normalizeDate(DateTime.now());

    return PlannerPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                key: const ValueKey('calendar-previous'),
                tooltip: '이전 달',
                onPressed: month.year == 1 && month.month == 1
                    ? null
                    : () => onMonth(DateTime(month.year, month.month - 1)),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  '${month.year}년 ${month.month}월',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: plannerTeal,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('calendar-next'),
                tooltip: '다음 달',
                onPressed: month.year == 9999 && month.month == 12
                    ? null
                    : () => onMonth(DateTime(month.year, month.month + 1)),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final weekday in const ['월', '화', '수', '목', '금', '토', '일'])
                Expanded(
                  child: Text(
                    weekday,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: plannerMuted),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (var row = 0; row < rows; row++)
            Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: _day(row * 7 + col - leading + 1, days, today),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '날짜 아래 숫자는 하루 점수예요.',
                  style: TextStyle(color: plannerMuted, fontSize: 11),
                ),
              ),
              TextButton(
                key: const ValueKey('calendar-today'),
                onPressed: onToday,
                child: const Text('오늘'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _day(int number, int days, DateTime today) {
    if (number < 1 || number > days) return const SizedBox(height: 56);
    final date = DateTime(month.year, month.month, number);
    final key = dateKey(date);
    final selected = date == selectedDate;
    final score = scores[key];
    final hasNote = noteDates.contains(key);
    return Semantics(
      button: true,
      selected: selected,
      label:
          '$key${score == null ? ', 점수 기록 없음' : ', 하루 점수 ${score.toStringAsFixed(1)}점'}${hasNote ? ', 하루 피드백 있음' : ''}',
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: Material(
          color: selected ? plannerTeal : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            key: ValueKey('calendar-day-$key'),
            onTap: () => onSelect(date),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: date == today && !selected
                    ? Border.all(color: plannerTeal)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$number',
                    style: TextStyle(
                      color: selected ? Colors.white : plannerTeal,
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 3),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          score?.toStringAsFixed(1) ?? '',
                          style: TextStyle(
                            color: selected
                                ? const Color(0xFFD8EEE4)
                                : plannerMuted,
                            fontSize: 10,
                          ),
                        ),
                        if (hasNote)
                          Padding(
                            padding: EdgeInsets.only(
                              left: score == null ? 0 : 2,
                            ),
                            child: Icon(
                              Icons.edit_note_rounded,
                              key: ValueKey('calendar-note-$key'),
                              size: 11,
                              color: selected
                                  ? const Color(0xFFD8EEE4)
                                  : plannerMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
