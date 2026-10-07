import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/calendar.dart';
import '../models/planner_state.dart';
import '../models/planner_stats.dart';
import '../models/todo.dart';
import '../providers/todo_provider.dart';
import '../widgets/planner_calendar.dart';
import '../widgets/planner_dialogs.dart';
import '../widgets/planner_style.dart';
import '../widgets/planner_summary.dart';
import '../widgets/place_stats_dialog.dart';
import '../widgets/suggestion_text_field.dart';
import '../widgets/todo_tile.dart';

class TodoScreen extends ConsumerStatefulWidget {
  const TodoScreen({super.key, this.initialDate});
  final DateTime? initialDate;

  @override
  ConsumerState<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends ConsumerState<TodoScreen> {
  final _inputController = TextEditingController();
  final _categoryController = TextEditingController(text: '기타');
  final _locationController = TextEditingController();
  final _minutesController = TextEditingController(text: '30');
  final _inputFocus = FocusNode();
  final _locationFocus = FocusNode();
  final _scrollController = ScrollController();
  late DateTime _selectedDate;
  late DateTime _month;
  String? _titleError;
  String? _minutesError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = normalizeDate(widget.initialDate ?? DateTime.now());
    _month = DateTime(_selectedDate.year, _selectedDate.month);
    _categoryController.addListener(_refreshCategory);
  }

  void _refreshCategory() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _inputController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    _minutesController.dispose();
    _inputFocus.dispose();
    _locationFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _selectDate(DateTime date) {
    if (_busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _selectedDate = normalizeDate(date);
      _month = DateTime(date.year, date.month);
      _titleError = null;
      _minutesError = null;
    });
  }

  Future<bool> _perform(Future<void> Function() operation) async {
    if (_busy || !mounted) return false;
    setState(() => _busy = true);
    try {
      await operation();
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                error is ArgumentError
                    ? '입력값을 확인해 주세요. ${error.message}'
                    : '저장하지 못했어요. 기록은 바뀌지 않았습니다. 다시 시도해 주세요.',
              ),
            ),
          );
      }
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addTodo() async {
    if (_busy) return;
    final title = _inputController.text.trim();
    final category = _categoryController.text;
    final location = _locationController.text;
    final minutes = int.tryParse(_minutesController.text);
    setState(() {
      _titleError = title.isEmpty ? '할 일을 입력하세요.' : null;
      _minutesError = minutes == null || minutes < 1 || minutes > 1440
          ? '1~1440분으로 입력하세요.'
          : null;
    });
    if (_titleError != null || _minutesError != null) {
      _inputFocus.requestFocus();
      return;
    }
    final date = _selectedDate;
    final saved = await _perform(() async {
      final added = await ref
          .read(todoProvider.notifier)
          .addTodo(
            title,
            category: category,
            location: location,
            estimatedMinutes: minutes!,
            date: date,
          );
      if (!added) throw StateError('The todo was not added.');
    });
    if (!mounted || !saved) return;
    _inputController.clear();
    _locationController.clear();
    _minutesController.text = '30';
    _inputFocus.requestFocus();
  }

  Future<void> _rate(Todo todo) async {
    if (_busy) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RatingDialog(
        todo: todo,
        onSave: (score) => _perform(
          () => ref.read(todoProvider.notifier).rateTodo(todo.id, score),
        ),
      ),
    );
  }

  Future<void> _edit(Todo todo) async {
    if (_busy) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EditTodoDialog(
        todo: todo,
        state: ref.read(todoProvider).requireValue,
        onSave: (title, category, location, minutes, date) =>
            _perform(() async {
              final edited = await ref
                  .read(todoProvider.notifier)
                  .editTodo(
                    todo.id,
                    title: title,
                    category: category,
                    location: location,
                    estimatedMinutes: minutes,
                    date: date,
                  );
              if (!edited) throw StateError('The todo could not be found.');
            }),
      ),
    );
  }

  Future<void> _goals(PlannerState state) async {
    if (_busy) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => GoalsDialog(
        count: state.dailyCountGoal,
        minutes: state.dailyMinutesGoal,
        onSave: (count, minutes) => _perform(
          () => ref
              .read(todoProvider.notifier)
              .updateGoals(count: count, minutes: minutes),
        ),
      ),
    );
  }

  Future<void> _details(DayStats stats) async {
    await showDialog<void>(
      context: context,
      builder: (_) => ScoreDetailsDialog(stats: stats),
    );
  }

  Future<void> _places(PlannerState state) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await showDialog<void>(
      context: context,
      builder: (_) => PlaceStatsDialog(state: state),
    );
  }

  Future<void> _reflection(PlannerState state) async {
    if (_busy) return;
    final date = _selectedDate;
    final saved = state.reflectionFor(date);
    FocusManager.instance.primaryFocus?.unfocus();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ReflectionDialog(
        good: saved?.good ?? '',
        needsWork: saved?.needsWork ?? '',
        improve: saved?.improve ?? '',
        onSave: (good, needsWork, improve) => _perform(
          () => ref
              .read(todoProvider.notifier)
              .saveReflection(
                date,
                good: good,
                needsWork: needsWork,
                improve: improve,
              ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(todoProvider);
    final state = asyncState.asData?.value;
    return Scaffold(
      backgroundColor: plannerBackground,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1320),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;
                return CustomScrollView(
                  key: const ValueKey('todo-scroll'),
                  controller: _scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        wide ? 28 : 16,
                        28,
                        wide ? 28 : 16,
                        22,
                      ),
                      sliver: SliverToBoxAdapter(child: _header(state)),
                    ),
                    if (_busy)
                      const SliverToBoxAdapter(
                        child: LinearProgressIndicator(
                          minHeight: 2,
                          color: plannerTeal,
                        ),
                      ),
                    asyncState.when(
                      loading: () => const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                key: ValueKey('planner-loading'),
                              ),
                              SizedBox(height: 16),
                              Text('저장된 기록을 불러오는 중이에요.'),
                            ],
                          ),
                        ),
                      ),
                      error: (error, stack) => SliverFillRemaining(
                        hasScrollBody: false,
                        child: _restoreError(error),
                      ),
                      data: (planner) => SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          wide ? 28 : 16,
                          0,
                          wide ? 28 : 16,
                          32,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _dashboard(planner, wide),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(PlannerState? state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: plannerTeal,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.checklist_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '오늘 할 일',
                style: TextStyle(
                  color: plannerTeal,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 5),
              Text(
                '날짜마다 계획하고, 끝낸 만큼 돌아보세요.',
                style: TextStyle(color: plannerMuted, fontSize: 13),
              ),
            ],
          ),
        ),
        IconButton(
          key: const ValueKey('goals-button'),
          tooltip: '하루 목표 설정',
          onPressed: state == null || _busy ? null : () => _goals(state),
          icon: const Icon(Icons.tune_rounded, color: plannerTeal),
        ),
      ],
    );
  }

  Widget _dashboard(PlannerState state, bool wide) {
    final stats = state.statsFor(_selectedDate);
    final history = state.historyStats(_selectedDate);
    final scores = <String, double>{};
    final monthDays = DateTime(_month.year, _month.month + 1, 0).day;
    for (var day = 1; day <= monthDays; day++) {
      final date = DateTime(_month.year, _month.month, day);
      final dateStats = state.statsFor(date);
      if (dateStats.hasRecord) scores[dateKey(date)] = dateStats.dailyScore;
    }
    final calendar = PlannerCalendar(
      month: _month,
      selectedDate: _selectedDate,
      scores: scores,
      onSelect: _selectDate,
      onMonth: (month) {
        if (!_busy) setState(() => _month = month);
      },
      onToday: () => _selectDate(DateTime.now()),
      noteDates: state.reflections.keys.toSet(),
    );
    final summary = PlannerSummary(
      stats: stats,
      history: history,
      onDetails: () => _details(stats),
    );
    final tasks = _taskSection(state, stats);
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 308,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [calendar, const SizedBox(height: 20), summary],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(child: tasks),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        calendar,
        const SizedBox(height: 24),
        tasks,
        const SizedBox(height: 24),
        summary,
      ],
    );
  }

  Widget _taskSection(PlannerState state, DayStats stats) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final pending = stats.tasks.where((todo) => !todo.isCompleted).toList();
    final completed = stats.tasks.where((todo) => todo.isCompleted).toList();
    final reflection = state.reflectionFor(_selectedDate);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일 (${weekdays[_selectedDate.weekday - 1]})',
          key: const ValueKey('selected-date'),
          style: const TextStyle(
            color: plannerTeal,
            fontSize: 23,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '계획 ${stats.plannedCount}개 · ${stats.plannedMinutes}분',
          style: const TextStyle(color: plannerMuted, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            TextButton.icon(
              key: const ValueKey('feedback-button'),
              onPressed: _busy ? null : () => _reflection(state),
              icon: const Icon(Icons.edit_note_rounded, size: 20),
              label: Text(reflection == null ? '하루 피드백 쓰기' : '하루 피드백 보기'),
            ),
            TextButton.icon(
              key: const ValueKey('place-stats-button'),
              onPressed: () => _places(state),
              icon: const Icon(Icons.place_outlined, size: 18),
              label: const Text('장소별 기록'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildInput(state),
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(
              child: Text(
                '날짜별 전체 목록',
                style: TextStyle(
                  color: plannerTeal,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE5ECE7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${stats.tasks.length}개',
                key: const ValueKey('todo-count'),
                style: const TextStyle(
                  color: plannerTeal,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _taskGroup(
          '해야 할 일',
          'pending-section',
          'pending-count',
          pending,
          stats.tasks.isEmpty ? 'todo-empty-state' : 'pending-empty-state',
          '해야 할 일이 없어요. 새 계획을 위에 적어 보세요.',
        ),
        const SizedBox(height: 24),
        _taskGroup(
          '실제로 한 일',
          'completed-section',
          'finished-count',
          completed,
          'completed-empty-state',
          '완료한 일이 아직 없어요. 체크하고 평점을 남겨 보세요.',
        ),
        if (reflection != null) ...[
          const SizedBox(height: 24),
          PlannerPanel(
            key: const ValueKey('feedback-saved-summary'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '저장한 하루 피드백',
                  style: TextStyle(
                    color: plannerTeal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (reflection.good.isNotEmpty)
                  _reflectionLine('잘한 점', reflection.good),
                if (reflection.needsWork.isNotEmpty)
                  _reflectionLine('미흡했던 점', reflection.needsWork),
                if (reflection.improve.isNotEmpty)
                  _reflectionLine('다음에 개선할 점', reflection.improve),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _reflectionLine(String label, String text) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: plannerMuted, fontSize: 12)),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(color: plannerTeal)),
      ],
    ),
  );

  Widget _taskGroup(
    String title,
    String sectionKey,
    String countKey,
    List<Todo> tasks,
    String emptyKey,
    String emptyText,
  ) => Column(
    key: ValueKey(sectionKey),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: plannerTeal,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '${tasks.length}개',
            key: ValueKey(countKey),
            style: const TextStyle(color: plannerMuted, fontSize: 13),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (tasks.isEmpty)
        PlannerPanel(
          key: ValueKey(emptyKey),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
          child: Text(
            emptyText,
            textAlign: TextAlign.center,
            style: const TextStyle(color: plannerMuted, fontSize: 13),
          ),
        )
      else
        for (final todo in tasks)
          TodoTile(
            key: ValueKey(todo.id),
            todo: todo,
            enabled: !_busy,
            onDelete: () => _perform(
              () => ref.read(todoProvider.notifier).deleteTodo(todo.id),
            ),
            onToggleCompleted: () => todo.isCompleted
                ? _perform(
                    () => ref.read(todoProvider.notifier).reopenTodo(todo.id),
                  )
                : _rate(todo),
            onEdit: () => _edit(todo),
            onRate: () => _rate(todo),
          ),
    ],
  );

  Widget _buildInput(PlannerState state) {
    return PlannerPanel(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final input = TextField(
            key: const ValueKey('todo-input'),
            controller: _inputController,
            focusNode: _inputFocus,
            enabled: !_busy,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _addTodo(),
            onChanged: (_) {
              if (_titleError != null) setState(() => _titleError = null);
            },
            decoration: InputDecoration(
              labelText: '새 할 일',
              hintText: '무엇을 할까요?',
              errorText: _titleError,
            ),
          );
          final category = TextField(
            key: const ValueKey('category-input'),
            controller: _categoryController,
            enabled: !_busy,
            decoration: const InputDecoration(
              labelText: '카테고리',
              hintText: '직접 적어도 좋아요',
            ),
          );
          final location = SuggestionTextField(
            fieldKey: 'location-input',
            controller: _locationController,
            focusNode: _locationFocus,
            suggestions: state.locationsFor(_categoryController.text),
            enabled: !_busy,
            label: '장소',
            hint: '입력한 장소가 추천돼요',
          );
          final categories = Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final value in <String>{
                '공부',
                '운동',
                '기타',
                ...state.categories,
              }.take(6))
                ActionChip(
                  key: ValueKey('category-option-$value'),
                  label: Text(value),
                  onPressed: _busy
                      ? null
                      : () {
                          _categoryController.text = value;
                          _locationFocus.unfocus();
                        },
                ),
            ],
          );
          final minutes = TextField(
            key: const ValueKey('minutes-input'),
            controller: _minutesController,
            enabled: !_busy,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _addTodo(),
            onChanged: (_) {
              if (_minutesError != null) setState(() => _minutesError = null);
            },
            decoration: InputDecoration(
              labelText: '예상 시간',
              suffixText: '분',
              errorText: _minutesError,
            ),
          );
          final add = FilledButton.icon(
            key: const ValueKey('add-todo-button'),
            onPressed: _busy ? null : _addTodo,
            icon: const Icon(Icons.add_rounded, size: 22),
            label: Text(_busy ? '저장 중' : '추가'),
            style: FilledButton.styleFrom(
              backgroundColor: plannerTeal,
              foregroundColor: Colors.white,
              minimumSize: const Size(104, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: Theme.of(context).textTheme.labelLarge!.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
          if (constraints.maxWidth < 460) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                input,
                const SizedBox(height: 14),
                category,
                const SizedBox(height: 8),
                categories,
                const SizedBox(height: 14),
                location,
                const SizedBox(height: 14),
                minutes,
                const SizedBox(height: 14),
                add,
              ],
            );
          }
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: input),
                  const SizedBox(width: 12),
                  add,
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  SizedBox(width: 144, child: category),
                  const SizedBox(width: 12),
                  Expanded(child: location),
                  const SizedBox(width: 12),
                  SizedBox(width: 128, child: minutes),
                ],
              ),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerLeft, child: categories),
            ],
          );
        },
      ),
    );
  }

  Widget _restoreError(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: plannerTeal,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                '저장된 기록을 불러오지 못했어요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: plannerTeal, fontSize: 19),
              ),
              const SizedBox(height: 10),
              const Text(
                '기록을 그대로 두고 다시 불러옵니다.',
                style: TextStyle(color: plannerMuted),
              ),
              const SizedBox(height: 12),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: plannerMuted, fontSize: 12),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                key: const ValueKey('retry-restore'),
                onPressed: () => ref.invalidate(todoProvider),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('다시 불러오기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
