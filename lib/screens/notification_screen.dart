import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stream_controller/components/notification_badge.dart';
import 'package:stream_controller/components/notification_list.dart';
import 'package:stream_controller/services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // Crear una instancia del servicio
  final NotificationService _notificationService = NotificationService();
  int _counter = 0;

  @override
  void initState() {
    super.initState();

    // Simular la llegada de notificaciones cada 3 segundos
    Timer.periodic(Duration(seconds: 3), (timer) {
      _counter++;
      _notificationService
          .addNotification(_counter); // Emitir nueva notificación
    });
  }

  @override
  void dispose() {
    // Cerrar el servicio cuando el widget se elimina
    _notificationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notificaciones en tiempo real'),
        actions: [
          // Widget 1: Contador de notificaciones en la barra de navegación
          NotificationBadge(notificationService: _notificationService),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Notificaciones recibidas:',
              style: TextStyle(fontSize: 20),
            ),
            // Widget 2: Lista de notificaciones
            NotificationList(notificationService: _notificationService),
          ],
        ),
      ),
    );
  }
}
