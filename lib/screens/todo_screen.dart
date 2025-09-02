import 'package:flutter/material.dart';
import 'package:stream_controller/services/todo_service.dart';
import 'package:stream_controller/components/add_task_dialog.dart';
import 'package:intl/intl.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> with TickerProviderStateMixin {
  late TodoService _todoService;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _todoService = TodoService();
    _tabController = TabController(length: 3, vsync: this);
    
    // Escuchar cambios en la búsqueda
    _searchController.addListener(() {
      _todoService.updateSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _todoService.dispose();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestor de Tareas'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.list), text: 'Todas'),
            Tab(icon: Icon(Icons.pending), text: 'Pendientes'),
            Tab(icon: Icon(Icons.check_circle), text: 'Completadas'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barra de búsqueda y filtros
          _buildSearchAndFilters(),
          
          // Estadísticas
          _buildStats(),
          
          // Contenido de las pestañas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllTasksTab(),
                _buildPendingTasksTab(),
                _buildCompletedTasksTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: Icon(Icons.add),
        backgroundColor: Colors.blue[600],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar tareas...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          
          SizedBox(height: 16),
          
          // Filtros
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown<TaskPriority>(
                  label: 'Prioridad',
                  items: [
                    DropdownMenuItem(value: null, child: Text('Todas')),
                    DropdownMenuItem(value: TaskPriority.low, child: Text('Baja')),
                    DropdownMenuItem(value: TaskPriority.medium, child: Text('Media')),
                    DropdownMenuItem(value: TaskPriority.high, child: Text('Alta')),
                  ],
                  onChanged: (value) {
                    _todoService.updatePriorityFilter(value);
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown<TaskStatus>(
                  label: 'Estado',
                  items: [
                    DropdownMenuItem(value: null, child: Text('Todos')),
                    DropdownMenuItem(value: TaskStatus.pending, child: Text('Pendiente')),
                    DropdownMenuItem(value: TaskStatus.inProgress, child: Text('En Progreso')),
                    DropdownMenuItem(value: TaskStatus.completed, child: Text('Completada')),
                  ],
                  onChanged: (value) {
                    _todoService.updateStatusFilter(value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown<T>({
    required String label,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 4),
        DropdownButtonFormField<T>(
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return StreamBuilder<int>(
      stream: _todoService.statsStream,
      builder: (context, snapshot) {
        final completedTasks = snapshot.data ?? 0;
        
        return StreamBuilder<List<Task>>(
          stream: _todoService.tasksStream,
          builder: (context, tasksSnapshot) {
            final totalTasks = tasksSnapshot.data?.length ?? 0;
            
            return Container(
              padding: EdgeInsets.all(16),
              color: Colors.blue[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Total',
                    '$totalTasks',
                    Icons.list,
                    Colors.blue[700]!,
                  ),
                  _buildStatItem(
                    'Completadas',
                    '$completedTasks',
                    Icons.check_circle,
                    Colors.green[700]!,
                  ),
                  _buildStatItem(
                    'Pendientes',
                    '${totalTasks - completedTasks}',
                    Icons.pending,
                    Colors.orange[700]!,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildAllTasksTab() {
    return StreamBuilder<List<Task>>(
      stream: _todoService.filteredTasksStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'No se encontraron tareas',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                Text(
                  'Intenta cambiar los filtros o agregar una nueva tarea',
                  style: TextStyle(color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final task = snapshot.data![index];
            return _buildTaskCard(task);
          },
        );
      },
    );
  }

  Widget _buildPendingTasksTab() {
    return StreamBuilder<List<Task>>(
      stream: _todoService.tasksStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final pendingTasks = snapshot.data!.where(
          (task) => task.status == TaskStatus.pending
        ).toList();

        if (pendingTasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green[400]),
                SizedBox(height: 16),
                Text(
                  '¡No hay tareas pendientes!',
                  style: TextStyle(fontSize: 18, color: Colors.green[600]),
                ),
                SizedBox(height: 8),
                Text(
                  'Todas las tareas están completadas',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: pendingTasks.length,
          itemBuilder: (context, index) {
            final task = pendingTasks[index];
            return _buildTaskCard(task);
          },
        );
      },
    );
  }

  Widget _buildCompletedTasksTab() {
    return StreamBuilder<List<Task>>(
      stream: _todoService.tasksStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final completedTasks = snapshot.data!.where(
          (task) => task.status == TaskStatus.completed
        ).toList();

        if (completedTasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pending, size: 64, color: Colors.orange[400]),
                SizedBox(height: 16),
                Text(
                  'No hay tareas completadas',
                  style: TextStyle(fontSize: 18, color: Colors.orange[600]),
                ),
                SizedBox(height: 8),
                Text(
                  'Comienza a completar algunas tareas',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: completedTasks.length,
          itemBuilder: (context, index) {
            final task = completedTasks[index];
            return _buildTaskCard(task);
          },
        );
      },
    );
  }

  Widget _buildTaskCard(Task task) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        task.description,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<TaskStatus>(
                  onSelected: (status) {
                    _todoService.updateTaskStatus(task.id, status);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: TaskStatus.pending,
                      child: Text('Marcar como Pendiente'),
                    ),
                    PopupMenuItem(
                      value: TaskStatus.inProgress,
                      child: Text('Marcar en Progreso'),
                    ),
                    PopupMenuItem(
                      value: TaskStatus.completed,
                      child: Text('Marcar como Completada'),
                    ),
                  ],
                  child: Icon(Icons.more_vert),
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: task.priorityColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: task.priorityColor),
                  ),
                  child: Text(
                    task.priorityText,
                    style: TextStyle(
                      color: task.priorityColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: task.statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: task.statusColor),
                  ),
                  child: Text(
                    task.statusText,
                    style: TextStyle(
                      color: task.statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Spacer(),
                Text(
                  DateFormat('MMM dd').format(task.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            
            if (task.status == TaskStatus.completed && task.completedAt != null)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Completada el ${DateFormat('MMM dd, HH:mm').format(task.completedAt!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(todoService: _todoService),
    );
  }
}
