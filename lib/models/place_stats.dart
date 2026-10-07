class PlaceStats {
  const PlaceStats({
    required this.category,
    required this.location,
    required this.plannedCount,
    required this.completedCount,
    required this.qualityAverage,
    required this.successCount,
    required this.successRate,
    required this.completedMinutes,
  });

  final String category;
  final String location;
  final int plannedCount;
  final int completedCount;
  final double? qualityAverage;
  final int successCount;
  final double? successRate;
  final int completedMinutes;
}

String normalizeCategory(String value) => _normalizeLabel(value, '기타');

String normalizeLocation(String value) => _normalizeLabel(value, '미지정');

String _normalizeLabel(String value, String fallback) {
  final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  return normalized.isEmpty ? fallback : normalized;
}
