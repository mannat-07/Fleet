// ─── Truck ───────────────────────────────────────────────────────────────────
class TruckModel {
  final String id;
  final String plate;
  final String model;
  final String type;
  final String status;
  final String location;
  final int? year;
  final String? assignedDriverId;

  TruckModel({
    required this.id,
    required this.plate,
    required this.model,
    required this.type,
    required this.status,
    required this.location,
    this.year,
    this.assignedDriverId,
  });

  factory TruckModel.fromJson(Map<String, dynamic> j) => TruckModel(
        id:               j['truckId']         as String? ?? j['id'] as String? ?? '',
        plate:            j['plate']            as String? ?? '',
        model:            j['model']            as String? ?? '',
        type:             j['type']             as String? ?? '',
        status:           j['status']           as String? ?? 'idle',
        location:         _locationStr(j['lastLocation']),
        year:             j['year']             as int?,
        assignedDriverId: j['assignedDriverId'] as String?,
      );

  static String _locationStr(dynamic loc) {
    if (loc == null) return '';
    if (loc is Map) return '${loc['lat']}, ${loc['lng']}';
    return loc.toString();
  }

  TruckModel copyWith({
    String? id, String? plate, String? model, String? type,
    String? status, String? location, int? year, String? assignedDriverId,
  }) => TruckModel(
    id: id ?? this.id, plate: plate ?? this.plate,
    model: model ?? this.model, type: type ?? this.type,
    status: status ?? this.status, location: location ?? this.location,
    year: year ?? this.year, assignedDriverId: assignedDriverId ?? this.assignedDriverId,
  );
}

// ─── Driver ──────────────────────────────────────────────────────────────────
class DriverModel {
  final String id;
  final String name;
  final String phone;
  final String licenseNumber;
  final String assignedTruck;
  final String status;
  final String avatarInitials;

  DriverModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.licenseNumber,
    required this.assignedTruck,
    required this.status,
    required this.avatarInitials,
  });

  factory DriverModel.fromJson(Map<String, dynamic> j) => DriverModel(
        id:             j['driverId']       as String? ?? j['id'] as String? ?? '',
        name:           j['name']           as String? ?? '',
        phone:          j['phone']          as String? ?? '',
        licenseNumber:  j['licenseNumber']  as String? ?? '',
        assignedTruck:  j['assignedTruckId'] as String? ?? '',
        status:         _mapStatus(j['status'] as String? ?? 'available'),
        avatarInitials: AppStore.initials(j['name'] as String? ?? ''),
      );

  static String _mapStatus(String s) {
    switch (s) {
      case 'on_trip':   return 'On Trip';
      case 'off_duty':  return 'Off Duty';
      default:          return 'Available';
    }
  }

  DriverModel copyWith({
    String? id, String? name, String? phone, String? licenseNumber,
    String? assignedTruck, String? status, String? avatarInitials,
  }) => DriverModel(
    id: id ?? this.id, name: name ?? this.name,
    phone: phone ?? this.phone, licenseNumber: licenseNumber ?? this.licenseNumber,
    assignedTruck: assignedTruck ?? this.assignedTruck,
    status: status ?? this.status, avatarInitials: avatarInitials ?? this.avatarInitials,
  );
}

// ─── Insurance ───────────────────────────────────────────────────────────────
class InsuranceModel {
  final String truckPlate;
  final String status;
  final String expiryDate;
  final String provider;

  InsuranceModel({
    required this.truckPlate,
    required this.status,
    required this.expiryDate,
    required this.provider,
  });

  factory InsuranceModel.fromJson(Map<String, dynamic> j) => InsuranceModel(
        truckPlate: j['plate']      as String? ?? j['truckPlate'] as String? ?? '',
        status:     _mapStatus(j['insuranceStatus'] as String? ?? j['status'] as String? ?? ''),
        expiryDate: j['insuranceExpiry'] as String? ?? j['expiryDate'] as String? ?? '',
        provider:   j['insuranceProvider'] as String? ?? j['provider'] as String? ?? '',
      );

  static String _mapStatus(String s) {
    final lower = s.toLowerCase();
    if (lower == 'valid')    return 'Valid';
    if (lower == 'expiring') return 'Expiring';
    if (lower == 'expired')  return 'Expired';
    return 'Unknown';
  }
}

// ─── User / Profile ──────────────────────────────────────────────────────────
class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String company;
  final String role;
  final String avatarInitials;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.company,
    required this.role,
    required this.avatarInitials,
  });

  UserProfile copyWith({
    String? name, String? email, String? phone, String? company,
  }) => UserProfile(
    uid: uid, name: name ?? this.name, email: email ?? this.email,
    phone: phone ?? this.phone, company: company ?? this.company,
    role: role, avatarInitials: avatarInitials,
  );
}

// ─── App Store — runtime state only, no hardcoded data ───────────────────────
class AppStore {
  // Lists populated from API — start empty
  static List<TruckModel>     trucks    = [];
  static List<DriverModel>    drivers   = [];
  static List<InsuranceModel> insurance = [];

  // Profile populated after login
  static UserProfile profile = const UserProfile(
    uid: '', name: '', email: '', phone: '', company: '',
    role: 'Fleet Owner', avatarInitials: '?',
  );

  // Earnings populated from API
  static List<double> weeklyEarnings  = [];
  static List<double> monthlyEarnings = [];
  static List<String> weekDays  = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static List<String> months    = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];

  static String nextId(List list) => (list.length + 1).toString();

  static String initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

// SampleData alias kept for backward compat — delegates to AppStore
class SampleData {
  static List<TruckModel>     get trucks    => AppStore.trucks;
  static List<DriverModel>    get drivers   => AppStore.drivers;
  static List<InsuranceModel> get insurance => AppStore.insurance;
  static List<double> get weeklyEarnings    => AppStore.weeklyEarnings;
  static List<double> get monthlyEarnings   => AppStore.monthlyEarnings;
  static List<String> get weekDays          => AppStore.weekDays;
  static List<String> get months            => AppStore.months;
}
