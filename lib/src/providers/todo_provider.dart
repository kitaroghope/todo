import 'dart:async';

import 'package:flutter/foundation.dart';

import '../interfaces/todo_repository.dart';
import '../models/todo.dart';

class TodoProvider extends ChangeNotifier {
  final TodoRepository _repository;

  bool _loading = false;
  String? _error;
  List<Todo> _items = const [];
  StreamSubscription<List<Todo>>? _sub;
  String? _currentUserId;

  TodoProvider(this._repository) {
    print('👀 [PROVIDER] TodoProvider created');
  }

  // Initialize or update the stream when user changes
  void _updateStreamForUser(String? userId) {
    print('🔄 [PROVIDER] Updating stream for user: $userId');
    // Cancel existing subscription
    _sub?.cancel();
    _sub = null;

    if (userId == null) {
      print('🔄 [PROVIDER] No user, clearing data');
      _items = [];
      _currentUserId = null;
      notifyListeners();
      return;
    }

    if (_currentUserId == userId) {
      print('🔄 [PROVIDER] Same user, no need to update stream');
      return;
    }

    print('🔄 [PROVIDER] Setting up new stream for user: $userId');
    _currentUserId = userId;
    _sub = _repository.streamTodos(userId).listen((data) {
      print('🔄 [PROVIDER] Received ${data.length} todos from stream');
      _items = data;
      notifyListeners();
      print('✅ [PROVIDER] Notified listeners of data change');
    });
  }

  bool get loading => _loading;
  String? get error => _error;
  List<Todo> get items => _items;
  bool get hasData => _items.isNotEmpty || (!_loading && _error == null);

  Future<void> refresh() async {
    if (_currentUserId == null) return;
    _setLoading(true);
    try {
      _items = await _repository.fetchTodos(_currentUserId!);
      _setError(null);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> add(String title) async {
    if (title.trim().isEmpty || _currentUserId == null) return;

    // Create a temporary todo with a placeholder ID
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    final tempTodo = Todo(
      id: tempId,
      userId: _currentUserId!,
      title: title.trim(),
      completed: false,
      insertedAt: now,
      updatedAt: now,
    );

    // Optimistically add to local list immediately
    _items = [..._items, tempTodo];
    notifyListeners();
    print('🎯 [PROVIDER] Optimistically added todo to local list with temp ID: $tempId');

    _setLoading(true);
    try {
      final newTodo = await _repository.addTodo(_currentUserId!, title.trim());

      // Replace the temporary todo with the real one from the server
      _items = _items.map((todo) => todo.id == tempId ? newTodo : todo).toList();
      notifyListeners();
      print('✅ [PROVIDER] Replaced temp todo with real todo (ID: ${newTodo.id})');

      _setError(null);
    } catch (e) {
      // Remove the temporary todo on error
      _items = _items.where((todo) => todo.id != tempId).toList();
      notifyListeners();
      print('⏪ [PROVIDER] Removed temp todo due to error');

      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggle(String id, bool completed) async {
    print('🔄 [PROVIDER] Toggle called for todo $id to completed: $completed');

    // Optimistically update the local list immediately
    final index = _items.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      _items = List.from(_items);
      _items[index] = _items[index].copyWith(completed: completed);
      notifyListeners();
      print('🎯 [PROVIDER] Optimistically updated todo in local list');
    }

    try {
      await _repository.toggleCompleted(id, completed);
      print('✅ [PROVIDER] Toggle completed successfully');
      _setError(null);
      // Stream will eventually sync the latest data
    } catch (e) {
      print('❌ [PROVIDER] Toggle failed: $e');
      // Revert the optimistic update on error
      if (index != -1) {
        _items = List.from(_items);
        _items[index] = _items[index].copyWith(completed: !completed);
        notifyListeners();
        print('⏪ [PROVIDER] Reverted optimistic update due to error');
      }
      _setError(e.toString());
      rethrow;
    }
  }

  Future<void> rename(String id, String title) async {
    // Optimistically update the local list immediately
    final index = _items.indexWhere((todo) => todo.id == id);
    String? oldTitle;
    if (index != -1) {
      oldTitle = _items[index].title;
      _items = List.from(_items);
      _items[index] = _items[index].copyWith(title: title);
      notifyListeners();
      print('🎯 [PROVIDER] Optimistically updated todo title in local list');
    }

    try {
      await _repository.updateTitle(id, title);
      _setError(null);
    } catch (e) {
      // Revert the optimistic update on error
      if (index != -1 && oldTitle != null) {
        _items = List.from(_items);
        _items[index] = _items[index].copyWith(title: oldTitle);
        notifyListeners();
        print('⏪ [PROVIDER] Reverted optimistic title update due to error');
      }
      _setError(e.toString());
      rethrow;
    }
  }

  Future<void> remove(String id) async {
    print('🗑️ [PROVIDER] Remove called for todo ID: $id');

    // Store the removed item for potential rollback
    final index = _items.indexWhere((todo) => todo.id == id);
    final Todo? removedItem = index != -1 ? _items[index] : null;

    // Optimistically remove from local list immediately
    if (index != -1) {
      _items = List.from(_items)..removeAt(index);
      notifyListeners();
      print('🎯 [PROVIDER] Optimistically removed todo from local list');
    }

    try {
      await _repository.deleteTodo(id);
      print('✅ [PROVIDER] Remove completed successfully');
      _setError(null);
      // Stream will eventually sync the latest data
    } catch (e) {
      print('❌ [PROVIDER] Remove failed: $e');
      // Revert the optimistic removal on error
      if (removedItem != null) {
        _items = List.from(_items)..insert(index, removedItem);
        notifyListeners();
        print('⏪ [PROVIDER] Reverted optimistic removal due to error');
      }
      _setError(e.toString());
      rethrow;
    }
  }

  void clearError() {
    _setError(null);
  }

  // Public method to update the user and refresh the stream
  void updateUser(String? userId) {
    print('🔄 [PROVIDER] Updating user from $userId');
    _updateStreamForUser(userId);
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  @override
  void dispose() {
    print(
      '💀 [PROVIDER] TodoProvider being disposed - cancelling stream subscription',
    );
    _sub?.cancel();
    super.dispose();
  }
}
