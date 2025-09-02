import 'package:flutter/material.dart';
import 'package:stream_controller/services/todo_service.dart';

class AddTaskDialog extends StatefulWidget {
  final TodoService todoService;

  const AddTaskDialog({
    super.key,
    required this.todoService,
  });

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TaskPriority _selectedPriority = TaskPriority.medium;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Nueva Tarea'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa un título';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa una descripción';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<TaskPriority>(
              value: _selectedPriority,
              decoration: InputDecoration(
                labelText: 'Prioridad',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: TaskPriority.low,
                  child: Text('Baja'),
                ),
                DropdownMenuItem(
                  value: TaskPriority.medium,
                  child: Text('Media'),
                ),
                DropdownMenuItem(
                  value: TaskPriority.high,
                  child: Text('Alta'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPriority = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _addTask,
          child: Text('Agregar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
          ),
        ),
      ],
    );
  }

  void _addTask() {
    if (_formKey.currentState!.validate()) {
      widget.todoService.addTask(
        _titleController.text,
        _descriptionController.text,
        _selectedPriority,
      );
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tarea agregada exitosamente'),
          backgroundColor: Colors.green[600],
        ),
      );
    }
  }
}
