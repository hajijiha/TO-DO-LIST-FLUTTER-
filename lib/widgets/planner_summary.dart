import 'package:flutter/material.dart';

import '../models/planner_stats.dart';
import 'planner_style.dart';

class PlannerSummary extends StatelessWidget {
  const PlannerSummary({
    super.key,
    required this.stats,
    required this.history,
    required this.onDetails,
  });

  final DayStats stats;
  final HistoryStats history;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlannerPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '선택한 날의 하루 점수',
                style: TextStyle(color: plannerMuted, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  Text(
                    stats.dailyScore.toStringAsFixed(1),
                    key: const ValueKey('daily-score'),
                    style: const TextStyle(
                      color: plannerTeal,
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                  const Text('/ 10', style: TextStyle(color: plannerMuted)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '목표 ${stats.targetScore.toStringAsFixed(1)}점',
                key: const ValueKey('target-score'),
                style: const TextStyle(
                  color: plannerTeal,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                stats.hasRecord ? '평점과 해낸 양을 함께 반영해요.' : '아직 이 날짜의 기록이 없어요.',
                style: const TextStyle(color: plannerMuted, fontSize: 12),
              ),
              const Divider(height: 28),
              Text(
                '완료 평점 평균  ${stats.qualityAverage?.toStringAsFixed(1) ?? '아직 없음'}',
                key: const ValueKey('quality-average'),
                style: const TextStyle(color: plannerTeal, fontSize: 13),
              ),
              const SizedBox(height: 16),
              _progress(
                '완료 개수',
                '${stats.completedCount} / ${stats.requiredCount}개',
                stats.quantityFactor,
                'completed-count',
              ),
              const SizedBox(height: 16),
              _progress(
                '완료 예상시간',
                '${stats.completedMinutes} / ${stats.requiredMinutes}분',
                stats.timeFactor,
                'completed-minutes',
              ),
              const SizedBox(height: 14),
              TextButton.icon(
                key: const ValueKey('score-details-button'),
                onPressed: onDetails,
                icon: const Icon(Icons.info_outline_rounded, size: 18),
                label: const Text('점수는 어떻게 계산하나요?'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PlannerPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '최근 14기록일의 평소 페이스',
                style: TextStyle(
                  color: plannerTeal,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                history.days.isEmpty
                    ? '기록이 쌓이면 평소 페이스를 보여드려요.'
                    : '선택 날짜까지의 최근 ${history.days.length}기록일',
                style: const TextStyle(color: plannerMuted, fontSize: 12),
              ),
              const SizedBox(height: 14),
              _line(
                '하루 점수 평균',
                history.averageScore == null
                    ? '아직 없음'
                    : '${history.averageScore!.toStringAsFixed(1)}점',
                key: 'history-average',
              ),
              _line(
                '평소 완료 개수',
                '${history.averageCompletedCount.toStringAsFixed(1)}개',
              ),
              _line(
                '평소 완료 예상시간',
                '${history.averageCompletedMinutes.toStringAsFixed(0)}분',
              ),
              const Divider(height: 22),
              _line('다음 새 기록일 목표', '${history.nextTarget.toStringAsFixed(1)}점'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _line(String label, String value, {String? key}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: plannerMuted, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            key: key == null ? null : ValueKey(key),
            style: const TextStyle(
              color: plannerTeal,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _progress(String label, String value, double factor, String key) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: plannerMuted, fontSize: 12),
              ),
            ),
            Text(
              value,
              key: ValueKey(key),
              style: const TextStyle(color: plannerTeal, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 7),
        LinearProgressIndicator(
          value: factor.clamp(0.0, 1.0),
          backgroundColor: const Color(0xFFE5ECE7),
          color: plannerTeal,
          minHeight: 6,
          borderRadius: BorderRadius.circular(6),
        ),
        const SizedBox(height: 4),
        Text(
          '${(factor * 100).toStringAsFixed(0)}% 달성',
          style: const TextStyle(color: plannerMuted, fontSize: 11),
        ),
      ],
    );
  }
}
