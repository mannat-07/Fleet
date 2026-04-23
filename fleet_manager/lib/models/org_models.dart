// ─── Org Truck Entry (derived from active trucks) ────────────────────────────
class OrgTruck {
  final String truckId;
  final String plate;
  final String? model;
  final String? type;
  final String status;       // active | on_trip | idle | maintenance
  final String? lastLocation;
  final DateTime? lastSeen;
  final SensorSnapshot? sensor;

  OrgTruck({
    required this.truckId,
    required this.plate,
    this.model,
    this.type,
    required this.status,
    this.lastLocation,
    this.lastSeen,
    this.sensor,
  });

  factory OrgTruck.fromJson(Map<String, dynamic> j) {
    final latestSensor = j['latestSensor'] as Map<String, dynamic>?;
    return OrgTruck(
      truckId:      j['truckId']  as String? ?? '',
      plate:        j['plate']    as String? ?? '',
      model:        j['model']    as String?,
      type:         j['type']     as String?,
      status:       j['status']   as String? ?? 'idle',
      lastLocation: j['lastLocation'] != null
          ? '${j['lastLocation']['lat']}, ${j['lastLocation']['lng']}'
          : null,
      lastSeen: _parseTs(j['lastSeen']),
      sensor:   latestSensor != null ? SensorSnapshot.fromJson(latestSensor) : null,
    );
  }

  static DateTime? _parseTs(dynamic ts) {
    if (ts == null) return null;
    if (ts is String) return DateTime.tryParse(ts);
    if (ts is Map && ts['_seconds'] != null) {
      return DateTime.fromMillisecondsSinceEpoch((ts['_seconds'] as int) * 1000);
    }
    return null;
  }

  /// Classify as incoming (on_trip heading to facility) or inside
  bool get isIncoming => status == 'on_trip';
  bool get isInside   => status == 'active';
  bool get isDeparted => status == 'idle' || status == 'maintenance';

  String get displayStatus {
    switch (status) {
      case 'on_trip':     return 'On Trip';
      case 'active':      return 'Active';
      case 'idle':        return 'Idle';
      case 'maintenance': return 'Maintenance';
      default:            return status;
    }
  }
}

class SensorSnapshot {
  final double? speed;
  final double? fuelLevel;
  final String? loadStatus;
  final String? doorStatus;
  final DateTime? receivedAt;

  SensorSnapshot({
    this.speed,
    this.fuelLevel,
    this.loadStatus,
    this.doorStatus,
    this.receivedAt,
  });

  factory SensorSnapshot.fromJson(Map<String, dynamic> j) => SensorSnapshot(
        speed:      (j['speed']     as num?)?.toDouble(),
        fuelLevel:  (j['fuelLevel'] as num?)?.toDouble(),
        loadStatus: j['loadStatus'] as String?,
        doorStatus: j['doorStatus'] as String?,
        receivedAt: _parseTs(j['receivedAt']),
      );

  static DateTime? _parseTs(dynamic ts) {
    if (ts == null) return null;
    if (ts is String) return DateTime.tryParse(ts);
    if (ts is Map && ts['_seconds'] != null) {
      return DateTime.fromMillisecondsSinceEpoch((ts['_seconds'] as int) * 1000);
    }
    return null;
  }
}

// ─── Fleet Summary ────────────────────────────────────────────────────────────
class FleetSummary {
  final int totalTrucks;
  final int activeTrucks;
  final int onTripTrucks;
  final int idleTrucks;
  final int totalDrivers;
  final int availableDrivers;

  FleetSummary({
    required this.totalTrucks,
    required this.activeTrucks,
    required this.onTripTrucks,
    required this.idleTrucks,
    required this.totalDrivers,
    required this.availableDrivers,
  });

  factory FleetSummary.fromJson(Map<String, dynamic> j) {
    final trucks  = j['trucks']  as Map<String, dynamic>? ?? {};
    final drivers = j['drivers'] as Map<String, dynamic>? ?? {};
    return FleetSummary(
      totalTrucks:      trucks['total']       as int? ?? 0,
      activeTrucks:     trucks['active']      as int? ?? 0,
      onTripTrucks:     trucks['onTrip']      as int? ?? 0,
      idleTrucks:       trucks['idle']        as int? ?? 0,
      totalDrivers:     drivers['total']      as int? ?? 0,
      availableDrivers: drivers['available']  as int? ?? 0,
    );
  }

  int get trucksInsideFacility => activeTrucks + onTripTrucks;
}

// ─── Activity Log entry (derived from truck events) ──────────────────────────
class ActivityLog {
  final String message;
  final DateTime time;
  final ActivityType type;

  ActivityLog({
    required this.message,
    required this.time,
    required this.type,
  });

  static ActivityLog fromTruck(OrgTruck truck) {
    switch (truck.status) {
      case 'on_trip':
        return ActivityLog(
          message: 'Truck ${truck.plate} is on trip',
          time: truck.lastSeen ?? DateTime.now(),
          type: ActivityType.movement,
        );
      case 'active':
        return ActivityLog(
          message: 'Truck ${truck.plate} is active at facility',
          time: truck.lastSeen ?? DateTime.now(),
          type: ActivityType.arrival,
        );
      case 'idle':
        return ActivityLog(
          message: 'Truck ${truck.plate} is idle',
          time: truck.lastSeen ?? DateTime.now(),
          type: ActivityType.idle,
        );
      default:
        return ActivityLog(
          message: 'Truck ${truck.plate} status: ${truck.displayStatus}',
          time: truck.lastSeen ?? DateTime.now(),
          type: ActivityType.movement,
        );
    }
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get formattedTime => _formatTime(time);
}

enum ActivityType { arrival, departure, movement, idle }
