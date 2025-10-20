import 'package:supabase_flutter/supabase_flutter.dart';

import '../interfaces/todo_repository.dart';
import '../models/todo.dart';

class SupabaseTodoRepository implements TodoRepository {
  final SupabaseClient _client;

  SupabaseTodoRepository(SupabaseClient client) : _client = client;

  @override
  Stream<List<Todo>> streamTodos(String userId) {
    print('📡 [REPO] Setting up real-time stream for user: $userId');
    return _client
        .from('todos')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('inserted_at')
        .map((rows) {
          print('📡 [REPO] Stream received ${rows.length} todos');
          return rows.map((e) => Todo.fromMap(e)).toList();
        });
  }

  @override
  Future<List<Todo>> fetchTodos(String userId) async {
    final res = await _client
        .from('todos')
        .select()
        .eq('user_id', userId)
        .order('inserted_at');
    return (res as List)
        .map((e) => Todo.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Todo> addTodo(String userId, String title) async {
    final res = await _client
        .from('todos')
        .insert({'user_id': userId, 'title': title})
        .select()
        .single();
    return Todo.fromMap(res as Map<String, dynamic>);
  }

  @override
  Future<Todo> toggleCompleted(String id, bool completed) async {
    print('🔄 [REPO] Toggling todo $id to completed: $completed');
    final res = await _client
        .from('todos')
        .update({'completed': completed})
        .eq('id', id)
        .select()
        .single();
    final updatedTodo = Todo.fromMap(res as Map<String, dynamic>);
    print(
      '✅ [REPO] Toggle completed for todo: ${updatedTodo.title} (ID: ${updatedTodo.id})',
    );
    return updatedTodo;
  }

  @override
  Future<void> updateTitle(String id, String title) async {
    await _client.from('todos').update({'title': title}).eq('id', id);
  }

  @override
  Future<String> deleteTodo(String id) async {
    print('🗑️ [REPO] Deleting todo with ID: $id');
    await _client.from('todos').delete().eq('id', id);
    print('✅ [REPO] Delete completed for todo ID: $id');
    return id; // Return the deleted ID for stream updates
  }
}
