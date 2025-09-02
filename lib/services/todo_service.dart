import 'dart:async';
import 'package:flutter/material.dart';

enum TaskPriority { low, medium, high }
enum TaskStatus { pending, inProgress, completed }

class Task {
  final String id;
  final String title;
  final String description;
  final TaskPriority priority;
  TaskStatus status;
  final DateTime createdAt;
  DateTime? completedAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    this.status = TaskStatus.pending,
    required this.createdAt,
    this.completedAt,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  String get priorityText {
    switch (priority) {
      case TaskPriority.low:
        return 'Baja';
      case TaskPriority.medium:
        return 'Media';
      case TaskPriority.high:
        return 'Alta';
    }
  }

  String get statusText {
    switch (status) {
      case TaskStatus.pending:
        return 'Pendiente';
      case TaskStatus.inProgress:
        return 'En Progreso';
      case TaskStatus.completed:
        return 'Completada';
    }
  }

  Color get priorityColor {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
    }
  }

  Color get statusColor {
    switch (status) {
      case TaskStatus.pending:
        return Colors.grey;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.completed:
        return Colors.green;
    }
  }
}

class TodoService {
  // StreamControllers para diferentes aspectos de las tareas
  final StreamController<List<Task>> _tasksController = StreamController<List<Task>>.broadcast();
  final StreamController<List<Task>> _filteredTasksController = StreamController<List<Task>>.broadcast();
  final StreamController<String> _searchQueryController = StreamController<String>.broadcast();
  final StreamController<TaskPriority?> _priorityFilterController = StreamController<TaskPriority?>.broadcast();
  final StreamController<TaskStatus?> _statusFilterController = StreamController<TaskStatus?>.broadcast();
  final StreamController<int> _statsController = StreamController<int>.broadcast();

  // Getters para los streams
  Stream<List<Task>> get tasksStream => _tasksController.stream;
  Stream<List<Task>> get filteredTasksStream => _filteredTasksController.stream;
  Stream<String> get searchQueryStream => _searchQueryController.stream;
  Stream<TaskPriority?> get priorityFilterStream => _priorityFilterController.stream;
  Stream<TaskStatus?> get statusFilterStream => _statusFilterController.stream;
  Stream<int> get statsStream => _statsController.stream;

  // Estado interno
  List<Task> _tasks = [];
  String _searchQuery = '';
  TaskPriority? _priorityFilter;
  TaskStatus? _statusFilter;

  TodoService() {
    _initializeTasks();
    _applyFilters();
  }

  void _initializeTasks() {
    _tasks = [
      Task(
        id: '1',
        title: 'Completar proyecto Flutter',
        description: 'Terminar la aplicación de gestión de tareas',
        priority: TaskPriority.high,
        createdAt: DateTime.now().subtract(Duration(days: 2)),
      ),
      Task(
        id: '2',
        title: 'Revisar documentación',
        description: 'Leer la documentación oficial de Flutter',
        priority: TaskPriority.medium,
        createdAt: DateTime.now().subtract(Duration(days: 1)),
      ),
      Task(
        id: '3',
        title: 'Hacer ejercicio',
        description: 'Ir al gimnasio por 1 hora',
        priority: TaskPriority.low,
        createdAt: DateTime.now(),
      ),
      Task(
        id: '4',
        title: 'Comprar víveres',
        description: 'Ir al supermercado para la semana',
        priority: TaskPriority.medium,
        createdAt: DateTime.now(),
      ),
      Task(
        id: '5',
        title: 'Llamar al médico',
        description: 'Agendar cita médica',
        priority: TaskPriority.high,
        createdAt: DateTime.now(),
      ),
    ];

    _tasksController.add(_tasks);
    _updateStats();
  }

  void addTask(String title, String description, TaskPriority priority) {
    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      priority: priority,
      createdAt: DateTime.now(),
    );

    _tasks.add(task);
    _tasksController.add(_tasks);
    _applyFilters();
    _updateStats();
  }

  void updateTaskStatus(String taskId, TaskStatus newStatus) {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      _tasks[taskIndex] = _tasks[taskIndex].copyWith(
        status: newStatus,
        completedAt: newStatus == TaskStatus.completed ? DateTime.now() : null,
      );
      
      _tasksController.add(_tasks);
      _applyFilters();
      _updateStats();
    }
  }

  void deleteTask(String taskId) {
    _tasks.removeWhere((task) => task.id == taskId);
    _tasksController.add(_tasks);
    _applyFilters();
    _updateStats();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    _searchQueryController.add(query);
    _applyFilters();
  }

  void updatePriorityFilter(TaskPriority? priority) {
    _priorityFilter = priority;
    _priorityFilterController.add(priority);
    _applyFilters();
  }

  void updateStatusFilter(TaskStatus? status) {
    _statusFilter = status;
    _statusFilterController.add(status);
    _applyFilters();
  }

  void _applyFilters() {
    List<Task> filteredTasks = List.from(_tasks);

    // Filtro por búsqueda
    if (_searchQuery.isNotEmpty) {
      filteredTasks = filteredTasks.where((task) {
        return task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               task.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Filtro por prioridad
    if (_priorityFilter != null) {
      filteredTasks = filteredTasks.where((task) {
        return task.priority == _priorityFilter;
      }).toList();
    }

    // Filtro por estado
    if (_statusFilter != null) {
      filteredTasks = filteredTasks.where((task) {
        return task.status == _statusFilter;
      }).toList();
    }

    _filteredTasksController.add(filteredTasks);
  }

  void _updateStats() {
    final completedTasks = _tasks.where((task) => task.status == TaskStatus.completed).length;
    _statsController.add(completedTasks);
  }

  List<Task> getTasksByStatus(TaskStatus status) {
    return _tasks.where((task) => task.status == status).toList();
  }

  List<Task> getTasksByPriority(TaskPriority priority) {
    return _tasks.where((task) => task.priority == priority).toList();
  }

  void dispose() {
    _tasksController.close();
    _filteredTasksController.close();
    _searchQueryController.close();
    _priorityFilterController.close();
    _statusFilterController.close();
    _statsController.close();
  }
}
