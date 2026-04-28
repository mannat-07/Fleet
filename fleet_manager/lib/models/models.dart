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
    id: j['truckId'] as String? ?? j['id'] as String? ?? '',
    plate: j['plate'] as String? ?? '',
    model: j['model'] as String? ?? '',
    type: j['type'] as String? ?? '',
    status: j['status'] as String? ?? 'idle',
    location: _locationStr(j['lastLocation']),
    year: j['year'] as int?,
    assignedDriverId: j['assignedDriverId'] as String?,
  );

  static String _locationStr(dynamic loc) {
    if (loc == null) return '';
    if (loc is Map) return '${loc['lat']}, ${loc['lng']}';
    return loc.toString();
  }

  TruckModel copyWith({
    String? id,
    String? plate,
    String? model,
    String? type,
    String? status,
    String? location,
    int? year,
    String? assignedDriverId,
  }) => TruckModel(
    id: id ?? this.id,
    plate: plate ?? this.plate,
    model: model ?? this.model,
    type: type ?? this.type,
    status: status ?? this.status,
    location: location ?? this.location,
    year: year ?? this.year,
    assignedDriverId: assignedDriverId ?? this.assignedDriverId,
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
    id: j['driverId'] as String? ?? j['id'] as String? ?? '',
    name: j['name'] as String? ?? '',
    phone: j['phone'] as String? ?? '',
    licenseNumber: j['licenseNumber'] as String? ?? '',
    assignedTruck: j['assignedTruckId'] as String? ?? '',
    status: _mapStatus(j['status'] as String? ?? 'available'),
    avatarInitials: AppStore.initials(j['name'] as String? ?? ''),
  );

  static String _mapStatus(String s) {
    switch (s) {
      case 'on_trip':
        return 'On Trip';
      case 'off_duty':
        return 'Off Duty';
      default:
        return 'Available';
    }
  }

  DriverModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? licenseNumber,
    String? assignedTruck,
    String? status,
    String? avatarInitials,
  }) => DriverModel(
    id: id ?? this.id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    licenseNumber: licenseNumber ?? this.licenseNumber,
    assignedTruck: assignedTruck ?? this.assignedTruck,
    status: status ?? this.status,
    avatarInitials: avatarInitials ?? this.avatarInitials,
  );
}

// ─── Insurance ───────────────────────────────────────────────────────────────
class InsuranceModel {
  final String insuranceId;
  final String truckId;
  final String truckPlate;
  final String policyNumber;
  final String provider;
  final String startDate;
  final String expiryDate;
  final String status;
  final int daysUntilExpiry;

  InsuranceModel({
    required this.insuranceId,
    required this.truckId,
    required this.truckPlate,
    required this.policyNumber,
    required this.provider,
    required this.startDate,
    required this.expiryDate,
    required this.status,
    required this.daysUntilExpiry,
  });

  factory InsuranceModel.fromJson(Map<String, dynamic> j) => InsuranceModel(
    insuranceId: j['insuranceId'] as String? ?? '',
    truckId: j['truckId'] as String? ?? '',
    truckPlate: j['truckPlate'] as String? ?? j['plate'] as String? ?? '',
    policyNumber: j['policyNumber'] as String? ?? '',
    provider: j['provider'] as String? ?? '',
    startDate: j['startDate'] as String? ?? '',
    expiryDate: j['expiryDate'] as String? ?? '',
    status: _mapStatus(j['status'] as String? ?? ''),
    daysUntilExpiry: (j['daysUntilExpiry'] as num?)?.toInt() ?? 0,
  );

  static String _mapStatus(String s) {
    switch (s.toLowerCase()) {
      case 'valid': return 'Valid';
      case 'expiring soon': return 'Expiring Soon';
      case 'expired': return 'Expired';
      case 'pending': return 'Pending';
      default: return s.isEmpty ? 'Pending' : s;
    }
  }

  /// Creates a pending-only entry for a truck with no insurance record
  factory InsuranceModel.pending({required String truckId, required String truckPlate}) =>
    InsuranceModel(
      insuranceId: '',
      truckId: truckId,
      truckPlate: truckPlate,
      policyNumber: '',
      provider: '',
      startDate: '',
      expiryDate: '',
      status: 'Pending',
      daysUntilExpiry: 0,
    );
}

// ─── Notification ─────────────────────────────────────────────────────────────
class NotificationModel {
  final String type;
  final String truckId;
  final String truckPlate;
  final int? daysUntilExpiry;
  final String message;

  NotificationModel({
    required this.type,
    required this.truckId,
    required this.truckPlate,
    this.daysUntilExpiry,
    required this.message,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> j) => NotificationModel(
    type: j['type'] as String? ?? '',
    truckId: j['truckId'] as String? ?? '',
    truckPlate: j['truckPlate'] as String? ?? '',
    daysUntilExpiry: (j['daysUntilExpiry'] as num?)?.toInt(),
    message: j['message'] as String? ?? '',
  );
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
    String? name,
    String? email,
    String? phone,
    String? company,
  }) => UserProfile(
    uid: uid,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    company: company ?? this.company,
    role: role,
    avatarInitials: avatarInitials,
  );
}

// ─── App Store — runtime state only, no hardcoded data ───────────────────────
class AppStore {
  // Lists populated from API — start empty
  static List<TruckModel> trucks = [];
  static List<DriverModel> drivers = [];
  static List<InsuranceModel> insurance = [];
  static List<NotificationModel> notifications = [];
  static int notificationCount = 0;

  // Profile populated after login
  static UserProfile profile = const UserProfile(
    uid: '',
    name: '',
    email: '',
    phone: '',
    company: '',
    role: 'Fleet Owner',
    avatarInitials: '?',
  );

  // Earnings populated from API
  static List<double> weeklyEarnings = [];
  static List<double> monthlyEarnings = [];
  static List<String> weekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  static List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];

  static String nextId(List list) => (list.length + 1).toString();

  static String initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

// ─── Demo data helpers ───────────────────────────────────────────────────────
class DemoData {
  static List<TruckModel> trucks() => [
    TruckModel(
      id: 'd1',
      plate: 'MH12 AB 1234',
      model: 'Tata Prima 4928.S',
      type: 'heavy',
      status: 'on_trip',
      location: 'Mumbai → Pune',
      year: 2021,
    ),
    TruckModel(
      id: 'd2',
      plate: 'DL08 CD 5678',
      model: 'Ashok Leyland 3518',
      type: 'heavy',
      status: 'active',
      location: 'Delhi Hub',
      year: 2020,
    ),
    TruckModel(
      id: 'd3',
      plate: 'KA05 EF 9012',
      model: 'Eicher Pro 6031',
      type: 'medium',
      status: 'idle',
      location: 'Bangalore Depot',
      year: 2022,
    ),
    TruckModel(
      id: 'd4',
      plate: 'GJ01 GH 3456',
      model: 'Tata LPT 3118',
      type: 'light',
      status: 'on_trip',
      location: 'Ahmedabad → Surat',
      year: 2019,
    ),
    TruckModel(
      id: 'd5',
      plate: 'TN22 IJ 7890',
      model: 'BharatBenz 3523R',
      type: 'tanker',
      status: 'active',
      location: 'Chennai Port',
      year: 2023,
    ),
  ];

  static List<DriverModel> drivers() => [
    DriverModel(
      id: 'd1',
      name: 'Rajesh Kumar',
      phone: '+91 98765 43210',
      licenseNumber: 'MH-0120110012345',
      assignedTruck: 'MH12 AB 1234',
      status: 'On Trip',
      avatarInitials: 'RK',
    ),
    DriverModel(
      id: 'd2',
      name: 'Suresh Patel',
      phone: '+91 87654 32109',
      licenseNumber: 'DL-0420190054321',
      assignedTruck: 'DL08 CD 5678',
      status: 'Available',
      avatarInitials: 'SP',
    ),
    DriverModel(
      id: 'd3',
      name: 'Vikram Yadav',
      phone: '+91 65432 10987',
      licenseNumber: 'GJ-0120170076543',
      assignedTruck: 'GJ01 GH 3456',
      status: 'On Trip',
      avatarInitials: 'VY',
    ),
  ];

  static List<InsuranceModel> insurance([List<TruckModel>? trucks]) {
    final providers = [
      'HDFC Ergo',
      'New India Assurance',
      'Bajaj Allianz',
      'ICICI Lombard',
      'Oriental Insurance',
    ];
    final statuses = ['Valid', 'Valid', 'Valid', 'Expiring Soon', 'Expired'];
    final policyNumbers = ['POL-12345', 'POL-67890', 'POL-11223', 'POL-44556', 'POL-77889'];
    final startDates = ['2025-01-15', '2024-08-22', '2025-11-10', '2025-05-30', '2025-03-01'];
    final expiries = ['2026-01-15', '2026-08-22', '2026-11-10', '2026-05-30', '2026-03-01'];
    final daysRemaining = [250, 300, 350, 30, -50];
    
    final source = (trucks != null && trucks.isNotEmpty)
        ? trucks
        : DemoData.trucks();
    return List.generate(
      source.length,
      (i) => InsuranceModel(
        insuranceId: 'demo-ins-$i',
        truckId: source[i].id,
        truckPlate: source[i].plate,
        policyNumber: policyNumbers[i % policyNumbers.length],
        provider: providers[i % providers.length],
        startDate: startDates[i % startDates.length],
        expiryDate: expiries[i % expiries.length],
        status: statuses[i % statuses.length],
        daysUntilExpiry: daysRemaining[i % daysRemaining.length],
      ),
    );
  }

  static Map<String, dynamic> earnings({required String period}) {
    final weeklyValues = [
      42000.0,
      58000.0,
      35000.0,
      71000.0,
      63000.0,
      80000.0,
      55000.0,
    ];
    final weeklyLabels = [
      '2024-05-13',
      '2024-05-14',
      '2024-05-15',
      '2024-05-16',
      '2024-05-17',
      '2024-05-18',
      '2024-05-19',
    ];
    final monthlyValues = [
      280000.0,
      320000.0,
      360000.0,
      410000.0,
      390000.0,
      450000.0,
    ];
    final monthlyLabels = [
      '2024-01-01',
      '2024-02-01',
      '2024-03-01',
      '2024-04-01',
      '2024-05-01',
      '2024-06-01',
    ];

    final values = period == 'monthly' ? monthlyValues : weeklyValues;
    final labels = period == 'monthly' ? monthlyLabels : weeklyLabels;
    final chartData = List.generate(
      values.length,
      (i) => {'date': labels[i], 'amount': values[i]},
    );
    final total = values.fold<double>(0, (a, b) => a + b);

    return {'total': total, 'records': values.length, 'chartData': chartData};
  }
}

// SampleData alias kept for backward compat — delegates to AppStore
class SampleData {
  static List<TruckModel> get trucks => AppStore.trucks;
  static List<DriverModel> get drivers => AppStore.drivers;
  static List<InsuranceModel> get insurance => AppStore.insurance;
  static List<double> get weeklyEarnings => AppStore.weeklyEarnings;
  static List<double> get monthlyEarnings => AppStore.monthlyEarnings;
  static List<String> get weekDays => AppStore.weekDays;
  static List<String> get months => AppStore.months;
}
