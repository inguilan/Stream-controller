import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

enum SensorType { temperature, humidity, motion, light, pressure }
enum AlertLevel { info, warning, critical }
enum DeviceStatus { online, offline, maintenance }

class SensorData {
  final String sensorId;
  final SensorType type;
  final double value;
  final String unit;
  final DateTime timestamp;
  final bool isActive;

  SensorData({
    required this.sensorId,
    required this.type,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.isActive = true,
  });

  SensorData copyWith({
    String? sensorId,
    SensorType? type,
    double? value,
    String? unit,
    DateTime? timestamp,
    bool? isActive,
  }) {
    return SensorData(
      sensorId: sensorId ?? this.sensorId,
      type: type ?? this.type,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      timestamp: timestamp ?? this.timestamp,
      isActive: isActive ?? this.isActive,
    );
  }
}

class Alert {
  final String id;
  final String message;
  final AlertLevel level;
  final SensorType? sensorType;
  final String? sensorId;
  final DateTime timestamp;
  final bool isAcknowledged;

  Alert({
    required this.id,
    required this.message,
    required this.level,
    this.sensorType,
    this.sensorId,
    required this.timestamp,
    this.isAcknowledged = false,
  });

  Alert copyWith({
    String? id,
    String? message,
    AlertLevel? level,
    SensorType? sensorType,
    String? sensorId,
    DateTime? timestamp,
    bool? isAcknowledged,
  }) {
    return Alert(
      id: id ?? this.id,
      message: message ?? this.message,
      level: level ?? this.level,
      sensorType: sensorType ?? this.sensorType,
      sensorId: sensorId ?? this.sensorId,
      timestamp: timestamp ?? this.timestamp,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
    );
  }

  Color get levelColor {
    switch (level) {
      case AlertLevel.info:
        return Colors.blue;
      case AlertLevel.warning:
        return Colors.orange;
      case AlertLevel.critical:
        return Colors.red;
    }
  }

  IconData get levelIcon {
    switch (level) {
      case AlertLevel.info:
        return Icons.info;
      case AlertLevel.warning:
        return Icons.warning;
      case AlertLevel.critical:
        return Icons.error;
    }
  }
}

class Device {
  final String id;
  final String name;
  final String location;
  final DeviceStatus status;
  final List<SensorType> supportedSensors;
  final DateTime lastSeen;
  final Map<String, dynamic> metadata;

  Device({
    required this.id,
    required this.name,
    required this.location,
    required this.status,
    required this.supportedSensors,
    required this.lastSeen,
    this.metadata = const {},
  });

  Device copyWith({
    String? id,
    String? name,
    String? location,
    DeviceStatus? status,
    List<SensorType>? supportedSensors,
    DateTime? lastSeen,
    Map<String, dynamic>? metadata,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      status: status ?? this.status,
      supportedSensors: supportedSensors ?? this.supportedSensors,
      lastSeen: lastSeen ?? this.lastSeen,
      metadata: metadata ?? this.metadata,
    );
  }
}

class ThresholdConfig {
  final SensorType sensorType;
  final double minValue;
  final double maxValue;
  final bool enabled;
  final AlertLevel alertLevel;

  ThresholdConfig({
    required this.sensorType,
    required this.minValue,
    required this.maxValue,
    this.enabled = true,
    this.alertLevel = AlertLevel.warning,
  });
}

class IoTSystemStats {
  final int totalDevices;
  final int onlineDevices;
  final int totalSensors;
  final int activeSensors;
  final int totalAlerts;
  final int unacknowledgedAlerts;
  final double systemHealth;

  IoTSystemStats({
    required this.totalDevices,
    required this.onlineDevices,
    required this.totalSensors,
    required this.activeSensors,
    required this.totalAlerts,
    required this.unacknowledgedAlerts,
    required this.systemHealth,
  });
}

class IoTSystemService {
  // StreamControllers principales
  final StreamController<List<Device>> _devicesController = StreamController<List<Device>>.broadcast();
  final StreamController<List<SensorData>> _sensorDataController = StreamController<List<SensorData>>.broadcast();
  final StreamController<List<Alert>> _alertsController = StreamController<List<Alert>>.broadcast();
  final StreamController<IoTSystemStats> _statsController = StreamController<IoTSystemStats>.broadcast();
  
  // StreamControllers para filtros y búsquedas
  final StreamController<SensorType?> _sensorTypeFilterController = StreamController<SensorType?>.broadcast();
  final StreamController<String> _searchQueryController = StreamController<String>.broadcast();
  final StreamController<AlertLevel?> _alertLevelFilterController = StreamController<AlertLevel?>.broadcast();
  
  // StreamControllers para datos específicos
  final StreamController<Map<SensorType, List<double>>> _historicalDataController = StreamController<Map<SensorType, List<double>>>.broadcast();
  final StreamController<Map<String, List<SensorData>>> _deviceDataController = StreamController<Map<String, List<SensorData>>>.broadcast();

  // Getters para los streams
  Stream<List<Device>> get devicesStream => _devicesController.stream;
  Stream<List<SensorData>> get sensorDataStream => _sensorDataController.stream;
  Stream<List<Alert>> get alertsStream => _alertsController.stream;
  Stream<IoTSystemStats> get statsStream => _statsController.stream;
  Stream<SensorType?> get sensorTypeFilterStream => _sensorTypeFilterController.stream;
  Stream<String> get searchQueryStream => _searchQueryController.stream;
  Stream<AlertLevel?> get alertLevelFilterStream => _alertLevelFilterController.stream;
  Stream<Map<SensorType, List<double>>> get historicalDataStream => _historicalDataController.stream;
  Stream<Map<String, List<SensorData>>> get deviceDataStream => _deviceDataController.stream;

  // Estado interno
  List<Device> _devices = [];
  List<SensorData> _sensorData = [];
  List<Alert> _alerts = [];
  Map<SensorType, List<double>> _historicalData = {};
  Map<String, List<SensorData>> _deviceData = {};
  Map<SensorType, ThresholdConfig> _thresholds = {};
  
  // Filtros
  SensorType? _sensorTypeFilter;
  String _searchQuery = '';
  AlertLevel? _alertLevelFilter;
  
  // Timers para simulación
  Timer? _dataUpdateTimer;
  Timer? _deviceStatusTimer;
  Timer? _alertCheckTimer;

  IoTSystemService() {
    _initializeSystem();
    _startSimulation();
  }

  void _initializeSystem() {
    // Inicializar dispositivos
    _devices = [
      Device(
        id: 'device_001',
        name: 'Sensor Hub Principal',
        location: 'Sala de Servidores',
        status: DeviceStatus.online,
        supportedSensors: [SensorType.temperature, SensorType.humidity, SensorType.pressure],
        lastSeen: DateTime.now(),
      ),
      Device(
        id: 'device_002',
        name: 'Monitor de Ambiente',
        location: 'Oficina Principal',
        status: DeviceStatus.online,
        supportedSensors: [SensorType.temperature, SensorType.humidity, SensorType.light],
        lastSeen: DateTime.now(),
      ),
      Device(
        id: 'device_003',
        name: 'Sistema de Seguridad',
        location: 'Entrada Principal',
        status: DeviceStatus.online,
        supportedSensors: [SensorType.motion, SensorType.light],
        lastSeen: DateTime.now(),
      ),
      Device(
        id: 'device_004',
        name: 'Monitor Industrial',
        location: 'Área de Producción',
        status: DeviceStatus.maintenance,
        supportedSensors: [SensorType.temperature, SensorType.pressure],
        lastSeen: DateTime.now().subtract(Duration(hours: 2)),
      ),
    ];

    // Inicializar umbrales
    _thresholds = {
      SensorType.temperature: ThresholdConfig(
        sensorType: SensorType.temperature,
        minValue: 18.0,
        maxValue: 25.0,
        alertLevel: AlertLevel.warning,
      ),
      SensorType.humidity: ThresholdConfig(
        sensorType: SensorType.humidity,
        minValue: 30.0,
        maxValue: 70.0,
        alertLevel: AlertLevel.warning,
      ),
      SensorType.pressure: ThresholdConfig(
        sensorType: SensorType.pressure,
        minValue: 1000.0,
        maxValue: 1100.0,
        alertLevel: AlertLevel.critical,
      ),
      SensorType.light: ThresholdConfig(
        sensorType: SensorType.light,
        minValue: 0.0,
        maxValue: 1000.0,
        alertLevel: AlertLevel.info,
      ),
      SensorType.motion: ThresholdConfig(
        sensorType: SensorType.motion,
        minValue: 0.0,
        maxValue: 1.0,
        alertLevel: AlertLevel.info,
      ),
    };

    // Inicializar datos históricos
    for (var sensorType in SensorType.values) {
      _historicalData[sensorType] = List.generate(100, (index) {
        return _generateRandomValue(sensorType);
      });
    }

    _updateStats();
    _emitAllData();
  }

  void _startSimulation() {
    // Timer para actualizar datos de sensores
    _dataUpdateTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      _updateSensorData();
    });

    // Timer para verificar estado de dispositivos
    _deviceStatusTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      _updateDeviceStatus();
    });

    // Timer para verificar alertas
    _alertCheckTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      _checkThresholds();
    });
  }

  void _updateSensorData() {
    final random = Random();
    final newData = <SensorData>[];

    for (var device in _devices.where((d) => d.status == DeviceStatus.online)) {
      for (var sensorType in device.supportedSensors) {
        final sensorId = '${device.id}_${sensorType.name}';
        final currentValue = _generateRandomValue(sensorType);
        
        final sensorData = SensorData(
          sensorId: sensorId,
          type: sensorType,
          value: currentValue,
          unit: _getUnitForSensorType(sensorType),
          timestamp: DateTime.now(),
        );

        newData.add(sensorData);
        
        // Actualizar datos históricos
        if (_historicalData.containsKey(sensorType)) {
          _historicalData[sensorType]!.add(currentValue);
          if (_historicalData[sensorType]!.length > 100) {
            _historicalData[sensorType]!.removeAt(0);
          }
        }

        // Actualizar datos por dispositivo
        if (!_deviceData.containsKey(device.id)) {
          _deviceData[device.id] = [];
        }
        _deviceData[device.id]!.add(sensorData);
        if (_deviceData[device.id]!.length > 50) {
          _deviceData[device.id]!.removeAt(0);
        }
      }
    }

    _sensorData = newData;
    _sensorDataController.add(_sensorData);
    _historicalDataController.add(_historicalData);
    _deviceDataController.add(_deviceData);
    _updateStats();
  }

  void _updateDeviceStatus() {
    final random = Random();
    
    for (int i = 0; i < _devices.length; i++) {
      if (random.nextDouble() < 0.1) { // 10% de probabilidad de cambio de estado
        DeviceStatus newStatus;
        if (_devices[i].status == DeviceStatus.online) {
          newStatus = random.nextBool() ? DeviceStatus.offline : DeviceStatus.maintenance;
        } else {
          newStatus = DeviceStatus.online;
        }

        _devices[i] = _devices[i].copyWith(
          status: newStatus,
          lastSeen: newStatus == DeviceStatus.online ? DateTime.now() : _devices[i].lastSeen,
        );

        // Crear alerta por cambio de estado
        _createAlert(
          'Dispositivo ${_devices[i].name} cambió a estado: ${_getStatusText(newStatus)}',
          newStatus == DeviceStatus.offline ? AlertLevel.warning : AlertLevel.info,
          sensorType: null,
          sensorId: _devices[i].id,
        );
      }
    }

    _devicesController.add(_devices);
    _updateStats();
  }

  void _checkThresholds() {
    for (var sensorData in _sensorData) {
      final threshold = _thresholds[sensorData.type];
      if (threshold != null && threshold.enabled) {
        if (sensorData.value < threshold.minValue || sensorData.value > threshold.maxValue) {
          final message = '${_getSensorTypeText(sensorData.type)} fuera de rango: ${sensorData.value}${sensorData.unit} (Rango: ${threshold.minValue}-${threshold.maxValue}${sensorData.unit})';
          _createAlert(message, threshold.alertLevel, sensorType: sensorData.type, sensorId: sensorData.sensorId);
        }
      }
    }
  }

  void _createAlert(String message, AlertLevel level, {SensorType? sensorType, String? sensorId}) {
    final alert = Alert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      level: level,
      sensorType: sensorType,
      sensorId: sensorId,
      timestamp: DateTime.now(),
    );

    _alerts.add(alert);
    _alertsController.add(_alerts);
    _updateStats();
  }

  void _updateStats() {
    final stats = IoTSystemStats(
      totalDevices: _devices.length,
      onlineDevices: _devices.where((d) => d.status == DeviceStatus.online).length,
      totalSensors: _sensorData.length,
      activeSensors: _sensorData.where((s) => s.isActive).length,
      totalAlerts: _alerts.length,
      unacknowledgedAlerts: _alerts.where((a) => !a.isAcknowledged).length,
      systemHealth: _calculateSystemHealth(),
    );

    _statsController.add(stats);
  }

  double _calculateSystemHealth() {
    if (_devices.isEmpty) return 0.0;
    
    final onlineRatio = _devices.where((d) => d.status == DeviceStatus.online).length / _devices.length;
    final alertRatio = _alerts.isEmpty ? 1.0 : (1.0 - (_alerts.where((a) => a.level == AlertLevel.critical).length / _alerts.length));
    
    return (onlineRatio * 0.7 + alertRatio * 0.3) * 100;
  }

  void _emitAllData() {
    _devicesController.add(_devices);
    _sensorDataController.add(_sensorData);
    _alertsController.add(_alerts);
    _historicalDataController.add(_historicalData);
    _deviceDataController.add(_deviceData);
  }

  // Métodos públicos para filtros
  void updateSensorTypeFilter(SensorType? sensorType) {
    _sensorTypeFilter = sensorType;
    _sensorTypeFilterController.add(sensorType);
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    _searchQueryController.add(query);
  }

  void updateAlertLevelFilter(AlertLevel? level) {
    _alertLevelFilter = level;
    _alertLevelFilterController.add(level);
  }

  // Métodos para gestión de alertas
  void acknowledgeAlert(String alertId) {
    final alertIndex = _alerts.indexWhere((alert) => alert.id == alertId);
    if (alertIndex != -1) {
      _alerts[alertIndex] = _alerts[alertIndex].copyWith(isAcknowledged: true);
      _alertsController.add(_alerts);
      _updateStats();
    }
  }

  void deleteAlert(String alertId) {
    _alerts.removeWhere((alert) => alert.id == alertId);
    _alertsController.add(_alerts);
    _updateStats();
  }

  // Métodos para gestión de dispositivos
  void updateDeviceStatus(String deviceId, DeviceStatus status) {
    final deviceIndex = _devices.indexWhere((device) => device.id == deviceId);
    if (deviceIndex != -1) {
      _devices[deviceIndex] = _devices[deviceIndex].copyWith(
        status: status,
        lastSeen: status == DeviceStatus.online ? DateTime.now() : _devices[deviceIndex].lastSeen,
      );
      _devicesController.add(_devices);
      _updateStats();
    }
  }

  // Métodos para gestión de umbrales
  void updateThreshold(SensorType sensorType, double minValue, double maxValue, AlertLevel alertLevel) {
    _thresholds[sensorType] = ThresholdConfig(
      sensorType: sensorType,
      minValue: minValue,
      maxValue: maxValue,
      alertLevel: alertLevel,
    );
  }

  // Métodos de utilidad
  double _generateRandomValue(SensorType sensorType) {
    final random = Random();
    switch (sensorType) {
      case SensorType.temperature:
        return 20.0 + (random.nextDouble() - 0.5) * 10; // 15-25°C
      case SensorType.humidity:
        return 50.0 + (random.nextDouble() - 0.5) * 40; // 30-70%
      case SensorType.pressure:
        return 1013.0 + (random.nextDouble() - 0.5) * 100; // 963-1063 hPa
      case SensorType.light:
        return 500.0 + random.nextDouble() * 500; // 500-1000 lux
      case SensorType.motion:
        return random.nextBool() ? 1.0 : 0.0; // 0 o 1
    }
  }

  String _getUnitForSensorType(SensorType sensorType) {
    switch (sensorType) {
      case SensorType.temperature:
        return '°C';
      case SensorType.humidity:
        return '%';
      case SensorType.pressure:
        return 'hPa';
      case SensorType.light:
        return 'lux';
      case SensorType.motion:
        return '';
    }
  }

  String _getSensorTypeText(SensorType sensorType) {
    switch (sensorType) {
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

  String _getStatusText(DeviceStatus status) {
    switch (status) {
      case DeviceStatus.online:
        return 'En línea';
      case DeviceStatus.offline:
        return 'Desconectado';
      case DeviceStatus.maintenance:
        return 'Mantenimiento';
    }
  }

  void dispose() {
    _dataUpdateTimer?.cancel();
    _deviceStatusTimer?.cancel();
    _alertCheckTimer?.cancel();
    
    _devicesController.close();
    _sensorDataController.close();
    _alertsController.close();
    _statsController.close();
    _sensorTypeFilterController.close();
    _searchQueryController.close();
    _alertLevelFilterController.close();
    _historicalDataController.close();
    _deviceDataController.close();
  }
}
