import '../models/todo.dart';

abstract class TodoRepository {
  Stream<List<Todo>> streamTodos(String userId);
  Future<List<Todo>> fetchTodos(String userId);
  Future<Todo> addTodo(String userId, String title);
  Future<void> toggleCompleted(String id, bool completed);
  Future<void> updateTitle(String id, String title);
  Future<void> deleteTodo(String id);
}

