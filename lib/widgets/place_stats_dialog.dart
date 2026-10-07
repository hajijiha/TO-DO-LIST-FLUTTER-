import 'package:flutter/material.dart';

import '../models/place_stats.dart';
import '../models/planner_state.dart';
import 'planner_style.dart';

class PlaceStatsDialog extends StatefulWidget {
  const PlaceStatsDialog({super.key, required this.state});
  final PlannerState state;

  @override
  State<PlaceStatsDialog> createState() => _PlaceStatsDialogState();
}

class _PlaceStatsDialogState extends State<PlaceStatsDialog> {
  int _categoryIndex = 0;

  @override
  Widget build(BuildContext context) {
    final categories = widget.state.categories;
    final category = _categoryIndex == 0
        ? null
        : categories[_categoryIndex - 1];
    final places = widget.state.placeStats(
      category: category,
      reference: DateTime.now(),
    );
    return AlertDialog(
      title: const Text('장소별 기록'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '오늘까지의 기록을 카테고리·장소별로 모았어요.\n성공률은 8점 이상 완료한 수 ÷ 전체 할 일 수입니다. 미완료도 포함하고 미래 계획은 제외해요.',
              ),
              const SizedBox(height: 10),
              const Text(
                '적은 표본은 크게 달라질 수 있어요. 이 값은 기록의 관측 비율이며 앞으로의 수행을 예측하지 않습니다.',
                style: TextStyle(color: plannerMuted, fontSize: 12),
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<int>(
                key: const ValueKey('place-category-filter'),
                initialValue: _categoryIndex,
                isExpanded: true,
                decoration: const InputDecoration(labelText: '카테고리'),
                items: [
                  const DropdownMenuItem(value: 0, child: Text('전체 카테고리')),
                  for (var index = 0; index < categories.length; index++)
                    DropdownMenuItem(
                      value: index + 1,
                      child: Text(categories[index]),
                    ),
                ],
                onChanged: (value) =>
                    setState(() => _categoryIndex = value ?? 0),
              ),
              const SizedBox(height: 18),
              if (places.isEmpty)
                const Padding(
                  key: ValueKey('place-stats-empty'),
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    '아직 장소 기록이 없어요. 할 일을 추가할 때 적은 장소가 자동으로 모입니다.',
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final place in places) _place(place),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('place-stats-close'),
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    );
  }

  Widget _place(PlaceStats place) {
    final suffix = '${place.category}::${place.location}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PlannerPanel(
        key: ValueKey('place-stats-$suffix'),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${place.category} · ${place.location}',
              style: const TextStyle(
                color: plannerTeal,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              place.successRate == null
                  ? '관측 성공률  기록 없음'
                  : '관측 성공률  ${(place.successRate! * 100).toStringAsFixed(0)}%',
              key: ValueKey('place-success-$suffix'),
              style: const TextStyle(
                color: plannerTeal,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '8점 이상 완료 ${place.successCount}개 / 전체 ${place.plannedCount}개',
              key: ValueKey('place-sample-$suffix'),
            ),
            const SizedBox(height: 8),
            Text(
              '완료 평점 평균  ${place.qualityAverage?.toStringAsFixed(1) ?? '아직 없음'}',
              key: ValueKey('place-quality-$suffix'),
            ),
            const SizedBox(height: 6),
            Text(
              '완료 ${place.completedCount}개 · 완료 예상시간 ${place.completedMinutes}분',
              style: const TextStyle(color: plannerMuted, fontSize: 12),
            ),
            if (place.plannedCount == 0)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  '입력했던 장소는 남아 있지만 오늘까지의 할 일 기록은 없어요.',
                  style: TextStyle(color: plannerMuted, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
