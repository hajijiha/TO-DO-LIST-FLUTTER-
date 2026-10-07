DateTime normalizeDate(DateTime date) {
  if (date.year < 1 || date.year > 9999) {
    throw ArgumentError.value(date, 'date', 'Year must be 1 through 9999.');
  }
  return DateTime(date.year, date.month, date.day);
}

String dateKey(DateTime date) {
  final day = normalizeDate(date);
  return '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}

DateTime dateFromKey(String key) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key)) {
    throw FormatException('Invalid date key: $key');
  }
  final parts = key.split('-').map(int.parse).toList();
  if (parts[0] < 1 ||
      parts[1] < 1 ||
      parts[1] > 12 ||
      parts[2] < 1 ||
      parts[2] > 31) {
    throw FormatException('Invalid date key: $key');
  }
  final day = DateTime(parts[0], parts[1], parts[2]);
  if (dateKey(day) != key) throw FormatException('Invalid date key: $key');
  return day;
}
