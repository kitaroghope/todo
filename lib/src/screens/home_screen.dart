import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/todo_provider.dart';

class HomeScreen extends StatefulWidget {
  static const route = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _title = TextEditingController();

  // Add loading state for individual todo operations
  final Map<String, bool> _operationLoading = {};

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  // Helper methods for managing operation loading states
  void _setOperationLoading(String operationId, bool loading) {
    setState(() {
      _operationLoading[operationId] = loading;
    });
  }

  bool _isOperationLoading(String operationId) {
    return _operationLoading[operationId] ?? false;
  }

  // Show process dialog for operations
  Future<void> _showProcessDialog(String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Row(
            children: [
              const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 16),
              Text(message, style: const TextStyle(fontSize: 16)),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // Update the todo provider when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final todos = context.read<TodoProvider?>();
      if (todos != null && auth.user != null) {
        print('🔄 [UI] Updating TodoProvider for user: ${auth.user!.id}');
        todos.updateUser(auth.user!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final todos = context.watch<TodoProvider?>();
    print(
      '🔨 [UI] HomeScreen building - todos count: ${todos?.items.length ?? 0}',
    );
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Todos',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Welcome back${auth.user?.email != null ? ', ${auth.user!.email}' : ''}!',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        tooltip: 'Sign out',
                        onPressed: auth.loading ? null : () => auth.signOut(),
                        icon: Icon(
                          Icons.logout_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Add Todo Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _title,
                                decoration: InputDecoration(
                                  hintText: 'What needs to be done?',
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 16,
                                  ),
                                ),
                                style: const TextStyle(fontSize: 16),
                                onSubmitted: (_) async {
                                  if (_title.text.trim().isEmpty ||
                                      todos == null)
                                    return;

                                  final title = _title.text.trim();
                                  final operationId = 'create_$title';

                                  _setOperationLoading(operationId, true);
                                  _showProcessDialog('Creating todo...');

                                  try {
                                    await todos.add(title);
                                    _title.clear();
                                    todos.clearError();
                                    Navigator.of(context).pop(); // Close dialog
                                  } catch (e) {
                                    Navigator.of(context).pop(); // Close dialog
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to create todo: $e',
                                        ),
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                    );
                                  } finally {
                                    _setOperationLoading(operationId, false);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.secondary,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: FilledButton(
                                onPressed: (todos == null)
                                    ? null
                                    : () async {
                                        if (_title.text.trim().isEmpty) return;

                                        final title = _title.text.trim();
                                        final operationId =
                                            'create_button_$title';

                                        _setOperationLoading(operationId, true);
                                        _showProcessDialog('Creating todo...');

                                        try {
                                          await todos.add(title);
                                          _title.clear();
                                          todos.clearError();
                                          Navigator.of(
                                            context,
                                          ).pop(); // Close dialog
                                        } catch (e) {
                                          Navigator.of(
                                            context,
                                          ).pop(); // Close dialog
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Failed to create todo: $e',
                                              ),
                                              backgroundColor: Theme.of(
                                                context,
                                              ).colorScheme.error,
                                            ),
                                          );
                                        } finally {
                                          _setOperationLoading(
                                            operationId,
                                            false,
                                          );
                                        }
                                      },
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                ),
                                child: const Text(
                                  'Add Todo',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Loading/Error States
                      if (todos == null || (todos.loading && !todos.hasData))
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 16),
                                  Text(
                                    todos?.loading == true
                                        ? 'Loading your todos...'
                                        : 'Initializing...',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else if (todos.error != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.error.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  todos.error!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        // Todo List
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: todos.items.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline,
                                          size: 64,
                                          color: Colors.grey.shade300,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No todos yet',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                color: Colors.grey.shade600,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Add your first todo above to get started!',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Colors.grey.shade500,
                                              ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: todos.items.length,
                                    itemBuilder: (context, i) {
                                      final t = todos.items[i];
                                      return Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: t.completed
                                              ? Colors.grey.shade50
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: t.completed
                                                ? Colors.grey.shade200
                                                : Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                      .withOpacity(0.2),
                                          ),
                                        ),
                                        child: Dismissible(
                                          key: ValueKey(t.id),
                                          background: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            alignment: Alignment.centerRight,
                                            padding: const EdgeInsets.only(
                                              right: 20,
                                            ),
                                            child: Icon(
                                              Icons.delete_outline,
                                              color: Colors.red.shade600,
                                            ),
                                          ),
                                          onDismissed: (_) async {
                                            final confirmed = await showDialog<bool>(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                  ),
                                                  title: const Text(
                                                    'Delete Todo',
                                                  ),
                                                  content: Text(
                                                    'Are you sure you want to delete "${t.title}"?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            context,
                                                          ).pop(false),
                                                      child: Text(
                                                        'Cancel',
                                                        style: TextStyle(
                                                          color: Colors
                                                              .grey
                                                              .shade600,
                                                        ),
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            context,
                                                          ).pop(true),
                                                      child: Text(
                                                        'Delete',
                                                        style: TextStyle(
                                                          color: Theme.of(
                                                            context,
                                                          ).colorScheme.error,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );

                                            if (confirmed != true) return;

                                            final operationId =
                                                'delete_${t.id}';
                                            _setOperationLoading(
                                              operationId,
                                              true,
                                            );
                                            _showProcessDialog(
                                              'Deleting todo...',
                                            );

                                            try {
                                              await todos.remove(t.id);
                                              todos.clearError();
                                              Navigator.of(
                                                context,
                                              ).pop(); // Close dialog
                                            } catch (e) {
                                              Navigator.of(
                                                context,
                                              ).pop(); // Close dialog
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Failed to delete todo: $e',
                                                  ),
                                                  backgroundColor: Theme.of(
                                                    context,
                                                  ).colorScheme.error,
                                                ),
                                              );
                                            } finally {
                                              _setOperationLoading(
                                                operationId,
                                                false,
                                              );
                                            }
                                          },
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: CheckboxListTile(
                                                  value: t.completed,
                                                  onChanged:
                                                      _isOperationLoading(
                                                        'toggle_${t.id}',
                                                      )
                                                      ? null
                                                      : (v) async {
                                                          final operationId =
                                                              'toggle_${t.id}';
                                                          _setOperationLoading(
                                                            operationId,
                                                            true,
                                                          );
                                                          _showProcessDialog(
                                                            'Updating todo...',
                                                          );

                                                          try {
                                                            await todos.toggle(
                                                              t.id,
                                                              v ?? false,
                                                            );
                                                            todos.clearError();
                                                            // Close dialog after a brief delay to show feedback
                                                            await Future.delayed(
                                                              const Duration(
                                                                milliseconds:
                                                                    300,
                                                              ),
                                                            );
                                                            if (mounted) {
                                                              Navigator.of(
                                                                context,
                                                              ).pop(); // Close dialog
                                                            }
                                                          } catch (e) {
                                                            if (mounted) {
                                                              Navigator.of(
                                                                context,
                                                              ).pop(); // Close dialog
                                                            }
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  'Failed to update todo: $e',
                                                                ),
                                                                backgroundColor:
                                                                    Theme.of(
                                                                          context,
                                                                        )
                                                                        .colorScheme
                                                                        .error,
                                                              ),
                                                            );
                                                          } finally {
                                                            _setOperationLoading(
                                                              operationId,
                                                              false,
                                                            );
                                                          }
                                                        },
                                                  title: Text(
                                                    t.title,
                                                    style: TextStyle(
                                                      decoration: t.completed
                                                          ? TextDecoration
                                                                .lineThrough
                                                          : null,
                                                      color: t.completed
                                                          ? Colors.grey.shade500
                                                          : Colors.black87,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  controlAffinity:
                                                      ListTileControlAffinity
                                                          .leading,
                                                  contentPadding:
                                                      const EdgeInsets.only(
                                                        left: 16,
                                                        right: 8,
                                                        top: 8,
                                                        bottom: 8,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.red.shade400,
                                                ),
                                                onPressed:
                                                    _isOperationLoading(
                                                      'delete_${t.id}',
                                                    )
                                                    ? null
                                                    : () async {
                                                        final confirmed = await showDialog<bool>(
                                                          context: context,
                                                          builder: (BuildContext context) {
                                                            return AlertDialog(
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      16,
                                                                    ),
                                                              ),
                                                              title: const Text(
                                                                'Delete Todo',
                                                              ),
                                                              content: Text(
                                                                'Are you sure you want to delete "${t.title}"?',
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () =>
                                                                      Navigator.of(
                                                                        context,
                                                                      ).pop(
                                                                        false,
                                                                      ),
                                                                  child: Text(
                                                                    'Cancel',
                                                                    style: TextStyle(
                                                                      color: Colors
                                                                          .grey
                                                                          .shade600,
                                                                    ),
                                                                  ),
                                                                ),
                                                                TextButton(
                                                                  onPressed: () =>
                                                                      Navigator.of(
                                                                        context,
                                                                      ).pop(
                                                                        true,
                                                                      ),
                                                                  child: Text(
                                                                    'Delete',
                                                                    style: TextStyle(
                                                                      color: Theme.of(
                                                                        context,
                                                                      ).colorScheme.error,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        );

                                                        if (confirmed != true)
                                                          return;

                                                        final operationId =
                                                            'delete_${t.id}';
                                                        _setOperationLoading(
                                                          operationId,
                                                          true,
                                                        );
                                                        _showProcessDialog(
                                                          'Deleting todo...',
                                                        );

                                                        try {
                                                          await todos.remove(
                                                            t.id,
                                                          );
                                                          todos.clearError();
                                                          Navigator.of(
                                                            context,
                                                          ).pop(); // Close dialog
                                                        } catch (e) {
                                                          Navigator.of(
                                                            context,
                                                          ).pop(); // Close dialog
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                'Failed to delete todo: $e',
                                                              ),
                                                              backgroundColor:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .error,
                                                            ),
                                                          );
                                                        } finally {
                                                          _setOperationLoading(
                                                            operationId,
                                                            false,
                                                          );
                                                        }
                                                      },
                                              ),
                                              const SizedBox(width: 8),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
