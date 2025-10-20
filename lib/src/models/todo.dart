class Todo {
  final String id;
  final String userId;
  final String title;
  final bool completed;
  final DateTime insertedAt;
  final DateTime updatedAt;

  const Todo({
    required this.id,
    required this.userId,
    required this.title,
    required this.completed,
    required this.insertedAt,
    required this.updatedAt,
  });

  Todo copyWith({
    String? id,
    String? userId,
    String? title,
    bool? completed,
    DateTime? insertedAt,
    DateTime? updatedAt,
  }) {
    return Todo(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      insertedAt: insertedAt ?? this.insertedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      completed: (map['completed'] as bool?) ?? false,
      insertedAt: DateTime.parse(map['inserted_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'completed': completed,
      'inserted_at': insertedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

