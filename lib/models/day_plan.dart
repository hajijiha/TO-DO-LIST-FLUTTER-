import 'dart:math' as math;

import 'model_json.dart';

class DayPlan {
  DayPlan({
    required this.requiredCount,
    required this.requiredMinutes,
    required this.targetScore,
  }) {
    if (requiredCount < 1) {
      throw ArgumentError.value(requiredCount, 'requiredCount');
    }
    if (requiredMinutes < 1) {
      throw ArgumentError.value(requiredMinutes, 'requiredMinutes');
    }
    if (!targetScore.isFinite || targetScore < 0 || targetScore > 10) {
      throw ArgumentError.value(targetScore, 'targetScore');
    }
  }

  final int requiredCount;
  final int requiredMinutes;
  final double targetScore;

  DayPlan ensureAtLeast({required int count, required int minutes}) => DayPlan(
    requiredCount: math.max(requiredCount, count),
    requiredMinutes: math.max(requiredMinutes, minutes),
    targetScore: targetScore,
  );

  Map<String, dynamic> toJson() => {
    'requiredCount': requiredCount,
    'requiredMinutes': requiredMinutes,
    'targetScore': targetScore,
  };

  factory DayPlan.fromJson(Map<String, dynamic> json) => DayPlan(
    requiredCount: jsonInt(json, 'requiredCount'),
    requiredMinutes: jsonInt(json, 'requiredMinutes'),
    targetScore: jsonDouble(json, 'targetScore'),
  );
}
