import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/calendar.dart';
import '../models/planner_stats.dart';
import '../models/planner_state.dart';
import '../models/todo.dart';
import 'planner_style.dart';
import 'suggestion_text_field.dart';

class RatingDialog extends StatefulWidget {
  const RatingDialog({super.key, required this.todo, required this.onSave});
  final Todo todo;
  final Future<bool> Function(int score) onSave;

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late final _controller = TextEditingController(
    text: '${widget.todo.score ?? 7}',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SaveDialog(
      title: widget.todo.isCompleted ? '완료 평점 수정' : '완료 평점 남기기',
      saveKey: 'rating-save',
      saveLabel: '평점 저장',
      validate: () {
        final score = int.tryParse(_controller.text);
        return score == null || score < 0 || score > 10
            ? '0부터 10 사이의 정수를 입력하세요.'
            : null;
      },
      onSave: () => widget.onSave(int.parse(_controller.text)),
      content: (saving, submit) => [
        Text(widget.todo.title, style: const TextStyle(color: plannerTeal)),
        const SizedBox(height: 12),
        const Text('이번 할 일을 얼마나 잘 해냈나요?\n0점도 완료한 기록으로 남습니다.'),
        const SizedBox(height: 18),
        TextField(
          key: const ValueKey('rating-input'),
          controller: _controller,
          autofocus: true,
          enabled: !saving,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onSubmitted: (_) => submit(),
          decoration: const InputDecoration(
            labelText: '완료 평점',
            suffixText: '/ 10',
          ),
        ),
      ],
    );
  }
}

class EditTodoDialog extends StatefulWidget {
  const EditTodoDialog({
    super.key,
    required this.todo,
    required this.state,
    required this.onSave,
  });
  final Todo todo;
  final PlannerState state;
  final Future<bool> Function(
    String title,
    String category,
    String location,
    int minutes,
    DateTime date,
  )
  onSave;

  @override
  State<EditTodoDialog> createState() => _EditTodoDialogState();
}

class _EditTodoDialogState extends State<EditTodoDialog> {
  late final _title = TextEditingController(text: widget.todo.title);
  late final _category = TextEditingController(text: widget.todo.category);
  late final _location = TextEditingController(text: widget.todo.location);
  final _locationFocus = FocusNode();
  late final _minutes = TextEditingController(
    text: '${widget.todo.estimatedMinutes}',
  );
  late final _date = TextEditingController(text: dateKey(widget.todo.date));

  @override
  void initState() {
    super.initState();
    _category.addListener(_refreshCategory);
  }

  void _refreshCategory() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final controller in [_title, _category, _location, _minutes, _date]) {
      controller.dispose();
    }
    _locationFocus.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final firstDate = DateTime(1);
    final lastDate = DateTime(9999, 12, 31);
    final enteredDate = _parseDate(_date.text) ?? widget.todo.date;
    final initialDate = enteredDate.isBefore(firstDate)
        ? firstDate
        : enteredDate.isAfter(lastDate)
        ? lastDate
        : enteredDate;
    final result = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: '계획 날짜 선택',
      cancelText: '취소',
      confirmText: '선택',
    );
    if (!mounted || result == null) return;
    _date.text = dateKey(result);
  }

  @override
  Widget build(BuildContext context) {
    return _SaveDialog(
      title: '할 일 수정',
      saveKey: 'edit-save',
      saveLabel: '변경 저장',
      validate: () {
        final minutes = int.tryParse(_minutes.text);
        if (_title.text.trim().isEmpty ||
            minutes == null ||
            minutes < 1 ||
            minutes > 1440 ||
            _parseDate(_date.text) == null) {
          return '제목, 1~1440분, 올바른 날짜(YYYY-MM-DD)를 입력하세요.';
        }
        return null;
      },
      onSave: () => widget.onSave(
        _title.text.trim(),
        _category.text,
        _location.text,
        int.parse(_minutes.text),
        _parseDate(_date.text)!,
      ),
      content: (saving, submit) => [
        _field('edit-title-input', '할 일', _title, saving),
        const SizedBox(height: 14),
        _field('edit-category-input', '카테고리', _category, saving),
        const SizedBox(height: 14),
        SuggestionTextField(
          fieldKey: 'edit-location-input',
          controller: _location,
          focusNode: _locationFocus,
          suggestions: widget.state.locationsFor(_category.text),
          label: '장소',
          enabled: !saving,
        ),
        const SizedBox(height: 14),
        _field(
          'edit-minutes-input',
          '예상 시간 (분)',
          _minutes,
          saving,
          numeric: true,
        ),
        const SizedBox(height: 14),
        TextField(
          key: const ValueKey('edit-date-input'),
          controller: _date,
          enabled: !saving,
          decoration: InputDecoration(
            labelText: '날짜 (YYYY-MM-DD)',
            suffixIcon: IconButton(
              onPressed: saving ? null : _pickDate,
              tooltip: '달력에서 선택',
              icon: const Icon(Icons.calendar_month_outlined),
            ),
          ),
          onSubmitted: (_) => submit(),
        ),
      ],
    );
  }
}

class ReflectionDialog extends StatefulWidget {
  const ReflectionDialog({
    super.key,
    this.good = '',
    this.needsWork = '',
    this.improve = '',
    required this.onSave,
  });
  final String good;
  final String needsWork;
  final String improve;
  final Future<bool> Function(String good, String needsWork, String improve)
  onSave;

  @override
  State<ReflectionDialog> createState() => _ReflectionDialogState();
}

class _ReflectionDialogState extends State<ReflectionDialog> {
  late final _good = TextEditingController(text: widget.good);
  late final _needsWork = TextEditingController(text: widget.needsWork);
  late final _improve = TextEditingController(text: widget.improve);

  @override
  void dispose() {
    _good.dispose();
    _needsWork.dispose();
    _improve.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _SaveDialog(
    title: '하루 피드백',
    saveKey: 'feedback-save',
    saveLabel: '피드백 저장',
    validate: () => null,
    onSave: () => widget.onSave(_good.text, _needsWork.text, _improve.text),
    content: (saving, submit) => [
      const Text(
        '저장 버튼을 눌러야 기록됩니다. 취소하면 이번 입력은 저장하지 않아요. 세 칸을 모두 비우고 저장하면 이 날 피드백을 지웁니다.',
        style: TextStyle(color: plannerMuted, fontSize: 12),
      ),
      const SizedBox(height: 18),
      _reflectionField('feedback-good-input', '잘한 점', _good, saving),
      const SizedBox(height: 14),
      _reflectionField(
        'feedback-needs-work-input',
        '미흡했던 점',
        _needsWork,
        saving,
      ),
      const SizedBox(height: 14),
      _reflectionField('feedback-improve-input', '다음에 개선할 점', _improve, saving),
    ],
  );

  Widget _reflectionField(
    String key,
    String label,
    TextEditingController controller,
    bool saving,
  ) => TextField(
    key: ValueKey(key),
    controller: controller,
    enabled: !saving,
    minLines: 2,
    maxLines: 4,
    keyboardType: TextInputType.multiline,
    decoration: InputDecoration(labelText: label),
  );
}

DateTime? _parseDate(String input) {
  try {
    final date = dateFromKey(input.trim());
    return date.year >= 1 && date.year <= 9999 && dateKey(date) == input.trim()
        ? date
        : null;
  } catch (_) {
    return null;
  }
}

class GoalsDialog extends StatefulWidget {
  const GoalsDialog({
    super.key,
    required this.count,
    required this.minutes,
    required this.onSave,
  });
  final int count;
  final int minutes;
  final Future<bool> Function(int count, int minutes) onSave;

  @override
  State<GoalsDialog> createState() => _GoalsDialogState();
}

class _GoalsDialogState extends State<GoalsDialog> {
  late final _count = TextEditingController(text: '${widget.count}');
  late final _minutes = TextEditingController(text: '${widget.minutes}');

  @override
  void dispose() {
    _count.dispose();
    _minutes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SaveDialog(
      title: '하루 목표 설정',
      saveKey: 'goals-save',
      saveLabel: '목표 저장',
      validate: () {
        final count = int.tryParse(_count.text);
        final minutes = int.tryParse(_minutes.text);
        return count == null ||
                count < 1 ||
                count > 1000 ||
                minutes == null ||
                minutes < 1 ||
                minutes > 1440
            ? '개수는 1~1000개, 시간은 1~1440분으로 입력하세요.'
            : null;
      },
      onSave: () =>
          widget.onSave(int.parse(_count.text), int.parse(_minutes.text)),
      content: (saving, submit) => [
        const Text('앞으로 새로 기록하는 날짜에 적용해요.\n이미 기록된 날짜의 목표는 그대로 유지합니다.'),
        const SizedBox(height: 20),
        _field(
          'goal-count-input',
          '하루 완료 목표 (개)',
          _count,
          saving,
          numeric: true,
        ),
        const SizedBox(height: 14),
        _field(
          'goal-minutes-input',
          '하루 시간 목표 (분)',
          _minutes,
          saving,
          numeric: true,
        ),
      ],
    );
  }
}

Widget _field(
  String key,
  String label,
  TextEditingController controller,
  bool saving, {
  bool numeric = false,
}) {
  return TextField(
    key: ValueKey(key),
    controller: controller,
    enabled: !saving,
    keyboardType: numeric ? TextInputType.number : TextInputType.text,
    inputFormatters: numeric ? [FilteringTextInputFormatter.digitsOnly] : null,
    decoration: InputDecoration(labelText: label),
  );
}

class _SaveDialog extends StatefulWidget {
  const _SaveDialog({
    required this.title,
    required this.saveKey,
    required this.saveLabel,
    required this.validate,
    required this.onSave,
    required this.content,
  });

  final String title;
  final String saveKey;
  final String saveLabel;
  final String? Function() validate;
  final Future<bool> Function() onSave;
  final List<Widget> Function(bool saving, VoidCallback submit) content;

  @override
  State<_SaveDialog> createState() => _SaveDialogState();
}

class _SaveDialogState extends State<_SaveDialog> {
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    if (_saving) return;
    final error = widget.validate();
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await widget.onSave();
      if (!mounted) return;
      if (saved) {
        Navigator.pop(context);
      } else {
        setState(() {
          _saving = false;
          _error = '저장하지 못했어요. 다시 시도해 주세요.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '저장하지 못했어요. 다시 시도해 주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        title: Text(widget.title),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...widget.content(_saving, _save),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            key: ValueKey(widget.saveKey),
            onPressed: _saving ? null : _save,
            child: Text(_saving ? '저장 중' : widget.saveLabel),
          ),
        ],
      ),
    );
  }
}

class ScoreDetailsDialog extends StatelessWidget {
  const ScoreDetailsDialog({super.key, required this.stats});
  final DayStats stats;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('하루 점수 계산'),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '개수 점수 = 완료 점수 합 ÷ 기준 개수\n시간 점수 = 완료(점수 × 예상 분) 합 ÷ 기준 분\n하루 점수 = (개수 점수 + 시간 점수) ÷ 2',
              ),
              const SizedBox(height: 16),
              Text(
                '이 날: (${stats.countScore.toStringAsFixed(2)} + ${stats.timeScore.toStringAsFixed(2)}) ÷ 2 = ${stats.dailyScore.toStringAsFixed(2)}점',
                style: const TextStyle(
                  color: plannerTeal,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              const Text('시간은 완료한 할 일에 입력한 예상 분의 합이에요. 실제 시간을 측정하지 않습니다.'),
              const SizedBox(height: 14),
              const Text(
                '예: 3개·90분 목표에서 30분짜리 한 일을 10점으로 완료하면, (10 ÷ 3 + 300 ÷ 90) ÷ 2 = 3.33점이에요. 각 점수는 최대 10점입니다.',
              ),
              const Divider(height: 30),
              const Text(
                '계획을 삭제해도 기준이 줄지 않는 이유',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                '이 날짜의 기준은 ${stats.requiredCount}개·${stats.requiredMinutes}분입니다. 처음 목표와 지금까지 잡았던 최대 계획량을 기억해요. 삭제·시간 축소·다른 날로 이동해도 기준은 줄지 않아서, 계획 삭제만으로 점수가 오르지 않습니다.',
              ),
              const SizedBox(height: 16),
              const Text(
                '목표 점수는 첫 기록 때 이전 14기록일의 하루 점수 평균에 0.5점을 더해 정하고, 최대 10점으로 제한합니다. 이전 기록이 없으면 7점으로 시작해요. 완료 평점 평균과 개수·시간 달성률도 따로 보여드립니다.',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('확인'),
        ),
      ],
    );
  }
}
