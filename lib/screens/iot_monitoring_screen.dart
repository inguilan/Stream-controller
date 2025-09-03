import 'package:flutter/material.dart';
import 'package:stream_controller/services/iot_monitoring_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class IoTSystemScreen extends StatefulWidget {
  const IoTSystemScreen({super.key});

  @override
  State<IoTSystemScreen> createState() => _IoTSystemScreenState();
}

class _IoTSystemScreenState extends State<IoTSystemScreen> with TickerProviderStateMixin {
  late IoTSystemService _iotService;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _iotService = IoTSystemService();
    _tabController = TabController(length: 4, vsync: this);
    
    // Escuchar cambios en la búsqueda
    _searchController.addListener(() {
      _iotService.updateSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _iotService.dispose();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sistema IoT - Monitoreo'),
        backgroundColor: Colors.indigo[800],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.sensors), text: 'Sensores'),
            Tab(icon: Icon(Icons.devices), text: 'Dispositivos'),
            Tab(icon: Icon(Icons.warning), text: 'Alertas'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barra de búsqueda y filtros
          _buildSearchAndFilters(),
          
          // Estadísticas del sistema
          _buildSystemStats(),
          
          // Contenido de las pestañas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                _buildSensorsTab(),
                _buildDevicesTab(),
                _buildAlertsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.indigo[50],
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar sensores, dispositivos o alertas...',
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
                child: _buildFilterDropdown<SensorType>(
                  label: 'Tipo de Sensor',
                  items: [
                    DropdownMenuItem(value: null, child: Text('Todos')),
                    DropdownMenuItem(value: SensorType.temperature, child: Text('Temperatura')),
                    DropdownMenuItem(value: SensorType.humidity, child: Text('Humedad')),
                    DropdownMenuItem(value: SensorType.pressure, child: Text('Presión')),
                    DropdownMenuItem(value: SensorType.light, child: Text('Luz')),
                    DropdownMenuItem(value: SensorType.motion, child: Text('Movimiento')),
                  ],
                  onChanged: (value) {
                    _iotService.updateSensorTypeFilter(value);
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown<AlertLevel>(
                  label: 'Nivel de Alerta',
                  items: [
                    DropdownMenuItem(value: null, child: Text('Todos')),
                    DropdownMenuItem(value: AlertLevel.info, child: Text('Información')),
                    DropdownMenuItem(value: AlertLevel.warning, child: Text('Advertencia')),
                    DropdownMenuItem(value: AlertLevel.critical, child: Text('Crítico')),
                  ],
                  onChanged: (value) {
                    _iotService.updateAlertLevelFilter(value);
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
            color: Colors.indigo[600],
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

  Widget _buildSystemStats() {
    return StreamBuilder<IoTSystemStats>(
      stream: _iotService.statsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final stats = snapshot.data!;
        
        return Container(
          padding: EdgeInsets.all(16),
          color: Colors.indigo[100],
          child: Column(
            children: [
              Text(
                'Estado del Sistema',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo[800],
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Dispositivos',
                    '${stats.onlineDevices}/${stats.totalDevices}',
                    Icons.devices,
                    Colors.green[700]!,
                  ),
                  _buildStatItem(
                    'Sensores',
                    '${stats.activeSensors}',
                    Icons.sensors,
                    Colors.blue[700]!,
                  ),
                  _buildStatItem(
                    'Alertas',
                    '${stats.unacknowledgedAlerts}',
                    Icons.warning,
                    stats.unacknowledgedAlerts > 0 ? Colors.orange[700]! : Colors.grey[700]!,
                  ),
                  _buildStatItem(
                    'Salud',
                    '${stats.systemHealth.toStringAsFixed(1)}%',
                    Icons.health_and_safety,
                    _getHealthColor(stats.systemHealth),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getHealthColor(double health) {
    if (health >= 80) return Colors.green[700]!;
    if (health >= 60) return Colors.orange[700]!;
    return Colors.red[700]!;
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Gráfico de tendencias
          _buildTrendsChart(),
          SizedBox(height: 24),
          
          // Últimas alertas
          _buildRecentAlerts(),
          SizedBox(height: 24),
          
          // Estado de dispositivos
          _buildDevicesStatus(),
        ],
      ),
    );
  }

  Widget _buildTrendsChart() {
    return StreamBuilder<Map<SensorType, List<double>>>(
      stream: _iotService.historicalDataStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final historicalData = snapshot.data!;
        final temperatureData = historicalData[SensorType.temperature] ?? [];
        final humidityData = historicalData[SensorType.humidity] ?? [];

        if (temperatureData.isEmpty || humidityData.isEmpty) {
          return Container(
            height: 200,
            child: Center(child: Text('No hay datos disponibles')),
          );
        }

        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tendencias de Sensores',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toStringAsFixed(0),
                                style: TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() % 20 == 0) {
                                return Text(
                                  '${value.toInt()}',
                                  style: TextStyle(fontSize: 10),
                                );
                              }
                              return Text('');
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: temperatureData.asMap().entries.map((entry) {
                            return FlSpot(entry.key.toDouble(), entry.value);
                          }).toList(),
                          isCurved: true,
                          color: Colors.red[600],
                          barWidth: 2,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.red[100]!.withOpacity(0.3),
                          ),
                        ),
                        LineChartBarData(
                          spots: humidityData.asMap().entries.map((entry) {
                            return FlSpot(entry.key.toDouble(), entry.value);
                          }).toList(),
                          isCurved: true,
                          color: Colors.blue[600],
                          barWidth: 2,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blue[100]!.withOpacity(0.3),
                          ),
                        ),
                      ],
                      minY: 0,
                      maxY: 100,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: Colors.red[600],
                    ),
                    SizedBox(width: 4),
                    Text('Temperatura'),
                    SizedBox(width: 16),
                    Container(
                      width: 12,
                      height: 12,
                      color: Colors.blue[600],
                    ),
                    SizedBox(width: 4),
                    Text('Humedad'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentAlerts() {
    return StreamBuilder<List<Alert>>(
      stream: _iotService.alertsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final alerts = snapshot.data!.take(5).toList();

        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alertas Recientes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                if (alerts.isEmpty)
                  Center(
                    child: Text(
                      'No hay alertas recientes',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                else
                  ...alerts.map((alert) => _buildAlertItem(alert)).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDevicesStatus() {
    return StreamBuilder<List<Device>>(
      stream: _iotService.devicesStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final devices = snapshot.data!;

        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado de Dispositivos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                ...devices.map((device) => _buildDeviceStatusItem(device)).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSensorsTab() {
    return StreamBuilder<List<SensorData>>(
      stream: _iotService.sensorDataStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final sensorData = snapshot.data!;

        if (sensorData.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sensors_off, size: 64, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'No hay datos de sensores',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: sensorData.length,
          itemBuilder: (context, index) {
            final data = sensorData[index];
            return _buildSensorDataCard(data);
          },
        );
      },
    );
  }

  Widget _buildDevicesTab() {
    return StreamBuilder<List<Device>>(
      stream: _iotService.devicesStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final devices = snapshot.data!;

        return ListView.builder(
          itemCount: devices.length,
          itemBuilder: (context, index) {
            final device = devices[index];
            return _buildDeviceCard(device);
          },
        );
      },
    );
  }

  Widget _buildAlertsTab() {
    return StreamBuilder<List<Alert>>(
      stream: _iotService.alertsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final alerts = snapshot.data!;

        if (alerts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green[400]),
                SizedBox(height: 16),
                Text(
                  'No hay alertas activas',
                  style: TextStyle(fontSize: 18, color: Colors.green[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: alerts.length,
          itemBuilder: (context, index) {
            final alert = alerts[index];
            return _buildAlertCard(alert);
          },
        );
      },
    );
  }

  Widget _buildSensorDataCard(SensorData data) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getSensorTypeColor(data.type).withOpacity(0.2),
          child: Icon(
            _getSensorTypeIcon(data.type),
            color: _getSensorTypeColor(data.type),
          ),
        ),
        title: Text(
          '${_getSensorTypeText(data.type)} - ${data.sensorId}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Última lectura: ${DateFormat('HH:mm:ss').format(data.timestamp)}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${data.value.toStringAsFixed(2)}${data.unit}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getSensorTypeColor(data.type),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: data.isActive ? Colors.green[100] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                data.isActive ? 'Activo' : 'Inactivo',
                style: TextStyle(
                  fontSize: 10,
                  color: data.isActive ? Colors.green[700] : Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCard(Device device) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getDeviceStatusColor(device.status).withOpacity(0.2),
          child: Icon(
            Icons.devices,
            color: _getDeviceStatusColor(device.status),
          ),
        ),
        title: Text(
          device.name,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(device.location),
            Text(
              'Sensores: ${device.supportedSensors.map((s) => _getSensorTypeText(s)).join(', ')}',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getDeviceStatusColor(device.status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getDeviceStatusColor(device.status)),
              ),
              child: Text(
                _getDeviceStatusText(device.status),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _getDeviceStatusColor(device.status),
                ),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Visto: ${DateFormat('HH:mm').format(device.lastSeen)}',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
        onTap: () => _showDeviceControlDialog(device),
      ),
    );
  }

  Widget _buildAlertCard(Alert alert) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: alert.levelColor.withOpacity(0.2),
          child: Icon(
            alert.levelIcon,
            color: alert.levelColor,
          ),
        ),
        title: Text(
          alert.message,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nivel: ${_getAlertLevelText(alert.level)}',
              style: TextStyle(fontSize: 12),
            ),
            Text(
              'Hora: ${DateFormat('HH:mm:ss').format(alert.timestamp)}',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!alert.isAcknowledged)
              IconButton(
                icon: Icon(Icons.check, color: Colors.green[600]),
                onPressed: () => _iotService.acknowledgeAlert(alert.id),
                tooltip: 'Marcar como leída',
              ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red[600]),
              onPressed: () => _iotService.deleteAlert(alert.id),
              tooltip: 'Eliminar alerta',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItem(Alert alert) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: alert.levelColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: alert.levelColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(alert.levelIcon, size: 16, color: alert.levelColor),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              alert.message,
              style: TextStyle(
                fontSize: 12,
                color: alert.levelColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceStatusItem(Device device) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _getDeviceStatusColor(device.status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getDeviceStatusColor(device.status).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.devices, size: 16, color: _getDeviceStatusColor(device.status)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '${device.name} - ${_getDeviceStatusText(device.status)}',
              style: TextStyle(
                fontSize: 12,
                color: _getDeviceStatusColor(device.status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeviceControlDialog(Device device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Control de Dispositivo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Dispositivo: ${device.name}'),
            Text('Ubicación: ${device.location}'),
            Text('Estado actual: ${_getDeviceStatusText(device.status)}'),
            SizedBox(height: 16),
            Text('Cambiar estado:'),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _iotService.updateDeviceStatus(device.id, DeviceStatus.online);
                      Navigator.of(context).pop();
                    },
                    child: Text('En Línea'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600]),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _iotService.updateDeviceStatus(device.id, DeviceStatus.offline);
                      Navigator.of(context).pop();
                    },
                    child: Text('Desconectar'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // Métodos de utilidad
  Color _getSensorTypeColor(SensorType type) {
    switch (type) {
      case SensorType.temperature:
        return Colors.red[600]!;
      case SensorType.humidity:
        return Colors.blue[600]!;
      case SensorType.pressure:
        return Colors.purple[600]!;
      case SensorType.light:
        return Colors.orange[600]!;
      case SensorType.motion:
        return Colors.green[600]!;
    }
  }

  IconData _getSensorTypeIcon(SensorType type) {
    switch (type) {
      case SensorType.temperature:
        return Icons.thermostat;
      case SensorType.humidity:
        return Icons.water_drop;
      case SensorType.pressure:
        return Icons.compress;
      case SensorType.light:
        return Icons.lightbulb;
      case SensorType.motion:
        return Icons.motion_photos_on;
    }
  }

  String _getSensorTypeText(SensorType type) {
    switch (type) {
      case SensorType.temperature:
        return 'Temperatura';
      case SensorType.humidity:
        return 'Humedad';
      case SensorType.pressure:
        return 'Presión';
      case SensorType.light:
        return 'Luz';
      case SensorType.motion:
        return 'Movimiento';
    }
  }

  Color _getDeviceStatusColor(DeviceStatus status) {
    switch (status) {
      case DeviceStatus.online:
        return Colors.green[600]!;
      case DeviceStatus.offline:
        return Colors.red[600]!;
      case DeviceStatus.maintenance:
        return Colors.orange[600]!;
    }
  }

  String _getDeviceStatusText(DeviceStatus status) {
    switch (status) {
      case DeviceStatus.online:
        return 'En línea';
      case DeviceStatus.offline:
        return 'Desconectado';
      case DeviceStatus.maintenance:
        return 'Mantenimiento';
    }
  }

  String _getAlertLevelText(AlertLevel level) {
    switch (level) {
      case AlertLevel.info:
        return 'Información';
      case AlertLevel.warning:
        return 'Advertencia';
      case AlertLevel.critical:
        return 'Crítico';
    }
  }
}

