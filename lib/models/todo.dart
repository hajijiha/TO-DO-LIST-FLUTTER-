class Todo {
  const Todo({required this.id, required this.title, this.isCompleted = false});

  final int id;
  final String title;
  final bool isCompleted;

  Todo copyWith({bool? isCompleted}) =>
      Todo(id: id, title: title, isCompleted: isCompleted ?? this.isCompleted);
}
