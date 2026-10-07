import 'model_json.dart';

class DayReflection {
  DayReflection({
    required String good,
    required String needsWork,
    required String improve,
  }) : good = good.trim(),
       needsWork = needsWork.trim(),
       improve = improve.trim();

  final String good;
  final String needsWork;
  final String improve;

  bool get isEmpty => good.isEmpty && needsWork.isEmpty && improve.isEmpty;

  Map<String, dynamic> toJson() => {
    'good': good,
    'needsWork': needsWork,
    'improve': improve,
  };

  factory DayReflection.fromJson(Map<String, dynamic> json) => DayReflection(
    good: jsonString(json, 'good'),
    needsWork: jsonString(json, 'needsWork'),
    improve: jsonString(json, 'improve'),
  );
}
