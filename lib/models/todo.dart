import 'calendar.dart';
import 'model_json.dart';
import 'place_stats.dart';

class Todo {
  Todo({
    required this.id,
    required String title,
    required String location,
    required this.estimatedMinutes,
    required DateTime date,
    String category = '기타',
    this.score,
  }) : title = title.trim(),
       category = normalizeCategory(category),
       location = normalizeLocation(location),
       date = normalizeDate(date) {
    if (id < 1) throw ArgumentError.value(id, 'id');
    if (this.title.isEmpty) throw ArgumentError.value(title, 'title');
    if (estimatedMinutes < 1 || estimatedMinutes > 1440) {
      throw ArgumentError.value(estimatedMinutes, 'estimatedMinutes');
    }
    if (score != null && (score! < 0 || score! > 10)) {
      throw ArgumentError.value(score, 'score');
    }
  }

  final int id;
  final String title;
  final String category;
  final String location;
  final int estimatedMinutes;
  final DateTime date;
  final int? score;

  bool get isCompleted => score != null;

  Todo copyWith({
    int? id,
    String? title,
    String? category,
    String? location,
    int? estimatedMinutes,
    DateTime? date,
    int? score,
    bool clearScore = false,
  }) => Todo(
    id: id ?? this.id,
    title: title ?? this.title,
    category: category ?? this.category,
    location: location ?? this.location,
    estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
    date: date ?? this.date,
    score: clearScore ? null : score ?? this.score,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'location': location,
    'estimatedMinutes': estimatedMinutes,
    'date': dateKey(date),
    'score': score,
  };

  factory Todo.fromJson(Map<String, dynamic> json) {
    final score = json['score'];
    if (!json.containsKey('score') || (score != null && score is! int)) {
      throw const FormatException('score must be an integer or null.');
    }
    return Todo(
      id: jsonInt(json, 'id'),
      title: jsonString(json, 'title'),
      category: json.containsKey('category')
          ? jsonString(json, 'category')
          : '기타',
      location: jsonString(json, 'location'),
      estimatedMinutes: jsonInt(json, 'estimatedMinutes'),
      date: dateFromKey(jsonString(json, 'date')),
      score: score as int?,
    );
  }
}
