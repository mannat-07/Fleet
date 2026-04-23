// ─── Assigned Truck (from backend truck document) ────────────────────────────
class AssignedTruck {
  final String truckId;
  final String plate;
  final String? model;
  final String? type;
  final String status;
  final String? lastLocation;

  AssignedTruck({
    required this.truckId,
    required this.plate,
    this.model,
    this.type,
    required this.status,
    this.lastLocation,
  });

  factory AssignedTruck.fromJson(Map<String, dynamic> j) => AssignedTruck(
        truckId:      j['truckId']      as String? ?? '',
        plate:        j['plate']        as String? ?? '',
        model:        j['model']        as String?,
        type:         j['type']         as String?,
        status:       j['status']       as String? ?? 'idle',
        lastLocation: j['lastLocation'] != null
            ? '${j['lastLocation']['lat']}, ${j['lastLocation']['lng']}'
            : null,
      );
}

// ─── Sensor Data (from IoT endpoint) ─────────────────────────────────────────
class SensorData {
  final double? speed;
  final double? fuelLevel;
  final String? loadStatus;
  final String? doorStatus;
  final double? temperature;
  final bool?   engineOn;
  final DateTime? receivedAt;

  SensorData({
    this.speed,
    this.fuelLevel,
    this.loadStatus,
    this.doorStatus,
    this.temperature,
    this.engineOn,
    this.receivedAt,
  });

  factory SensorData.fromJson(Map<String, dynamic> j) => SensorData(
        speed:       (j['speed']       as num?)?.toDouble(),
        fuelLevel:   (j['fuelLevel']   as num?)?.toDouble(),
        loadStatus:  j['loadStatus']   as String?,
        doorStatus:  j['doorStatus']   as String?,
        temperature: (j['temperature'] as num?)?.toDouble(),
        engineOn:    j['engineOn']     as bool?,
        receivedAt:  _parseTs(j['receivedAt']),
      );

  static DateTime? _parseTs(dynamic ts) {
    if (ts == null) return null;
    if (ts is String) return DateTime.tryParse(ts);
    // Firestore Timestamp serialised as { _seconds, _nanoseconds }
    if (ts is Map && ts['_seconds'] != null) {
      return DateTime.fromMillisecondsSinceEpoch(
          (ts['_seconds'] as int) * 1000);
    }
    return null;
  }

  bool get hasData =>
      speed != null ||
      fuelLevel != null ||
      loadStatus != null ||
      doorStatus != null;

  /// Derive alerts from sensor readings
  List<SensorAlert> get alerts {
    final list = <SensorAlert>[];
    if (fuelLevel != null && fuelLevel! < 20) {
      list.add(SensorAlert(
        message: 'Low fuel — ${fuelLevel!.toStringAsFixed(0)}% remaining',
        severity: AlertSeverity.critical,
      ));
    }
    if (loadStatus == 'loaded' && fuelLevel != null && fuelLevel! < 30) {
      list.add(SensorAlert(
        message: 'Loaded truck with low fuel',
        severity: AlertSeverity.warning,
      ));
    }
    if (doorStatus == 'open') {
      list.add(SensorAlert(
        message: 'Door is open while on trip',
        severity: AlertSeverity.warning,
      ));
    }
    if (speed != null && speed! > 90) {
      list.add(SensorAlert(
        message: 'Overspeeding — ${speed!.toStringAsFixed(0)} km/h',
        severity: AlertSeverity.critical,
      ));
    }
    if (temperature != null && temperature! > 80) {
      list.add(SensorAlert(
        message: 'High engine temperature — ${temperature!.toStringAsFixed(0)}°C',
        severity: AlertSeverity.warning,
      ));
    }
    return list;
  }
}

enum AlertSeverity { warning, critical }

class SensorAlert {
  final String message;
  final AlertSeverity severity;
  SensorAlert({required this.message, required this.severity});
}

// ─── Driver Profile (from backend driver document) ────────────────────────────
class DriverProfile {
  final String driverId;
  final String name;
  final String? phone;
  final String? licenseNumber;
  final String? assignedTruckId;
  final String status;

  DriverProfile({
    required this.driverId,
    required this.name,
    this.phone,
    this.licenseNumber,
    this.assignedTruckId,
    required this.status,
  });

  factory DriverProfile.fromJson(Map<String, dynamic> j) => DriverProfile(
        driverId:       j['driverId']       as String? ?? '',
        name:           j['name']           as String? ?? '',
        phone:          j['phone']          as String?,
        licenseNumber:  j['licenseNumber']  as String?,
        assignedTruckId: j['assignedTruckId'] as String?,
        status:         j['status']         as String? ?? 'available',
      );

  bool get isOnTrip => status == 'on_trip';
}
