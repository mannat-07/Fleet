// ─── Truck ───────────────────────────────────────────────────────────────────
class TruckModel {
  final String id;
  final String plate;
  final String model;
  final String type;       // heavy | medium | light | tanker | flatbed
  final String status;     // Active | On Trip | Idle | Maintenance
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

  TruckModel copyWith({
    String? id, String? plate, String? model, String? type,
    String? status, String? location, int? year, String? assignedDriverId,
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
  final String status;       // On Trip | Available | Off Duty
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

  DriverModel copyWith({
    String? id, String? name, String? phone, String? licenseNumber,
    String? assignedTruck, String? status, String? avatarInitials,
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
    uid: uid,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    company: company ?? this.company,
    role: role,
    avatarInitials: avatarInitials,
  );
}

// ─── Sample / In-memory store ─────────────────────────────────────────────────
class AppStore {
  // Mutable lists so add/delete works in-memory
  static List<TruckModel> trucks = [
    TruckModel(id: '1', plate: 'MH12 AB 1234', model: 'Tata Prima 4928.S',   type: 'heavy',   status: 'On Trip',     location: 'Mumbai → Pune',      year: 2021),
    TruckModel(id: '2', plate: 'DL08 CD 5678', model: 'Ashok Leyland 3518',  type: 'heavy',   status: 'Active',      location: 'Delhi Hub',           year: 2020),
    TruckModel(id: '3', plate: 'KA05 EF 9012', model: 'Eicher Pro 6031',     type: 'medium',  status: 'Idle',        location: 'Bangalore Depot',     year: 2022),
    TruckModel(id: '4', plate: 'GJ01 GH 3456', model: 'Tata LPT 3118',       type: 'light',   status: 'On Trip',     location: 'Ahmedabad → Surat',   year: 2019),
    TruckModel(id: '5', plate: 'TN22 IJ 7890', model: 'BharatBenz 3523R',    type: 'tanker',  status: 'Active',      location: 'Chennai Port',        year: 2023),
  ];

  static List<DriverModel> drivers = [
    DriverModel(id: '1', name: 'Rajesh Kumar',  phone: '+91 98765 43210', licenseNumber: 'MH-0120110012345', assignedTruck: 'MH12 AB 1234', status: 'On Trip',   avatarInitials: 'RK'),
    DriverModel(id: '2', name: 'Suresh Patel',  phone: '+91 87654 32109', licenseNumber: 'DL-0420190054321', assignedTruck: 'DL08 CD 5678', status: 'Available', avatarInitials: 'SP'),
    DriverModel(id: '3', name: 'Mohan Singh',   phone: '+91 76543 21098', licenseNumber: 'KA-0520180098765', assignedTruck: 'KA05 EF 9012', status: 'Available', avatarInitials: 'MS'),
    DriverModel(id: '4', name: 'Vikram Yadav',  phone: '+91 65432 10987', licenseNumber: 'GJ-0120170076543', assignedTruck: 'GJ01 GH 3456', status: 'On Trip',   avatarInitials: 'VY'),
    DriverModel(id: '5', name: 'Arjun Nair',    phone: '+91 54321 09876', licenseNumber: 'TN-0920210032109', assignedTruck: 'TN22 IJ 7890', status: 'Available', avatarInitials: 'AN'),
  ];

  static List<InsuranceModel> insurance = [
    InsuranceModel(truckPlate: 'MH12 AB 1234', status: 'Valid',    expiryDate: '15 Dec 2026', provider: 'HDFC Ergo'),
    InsuranceModel(truckPlate: 'DL08 CD 5678', status: 'Expiring', expiryDate: '30 May 2026', provider: 'New India'),
    InsuranceModel(truckPlate: 'KA05 EF 9012', status: 'Valid',    expiryDate: '22 Aug 2026', provider: 'Bajaj Allianz'),
    InsuranceModel(truckPlate: 'GJ01 GH 3456', status: 'Expired',  expiryDate: '01 Mar 2026', provider: 'ICICI Lombard'),
    InsuranceModel(truckPlate: 'TN22 IJ 7890', status: 'Valid',    expiryDate: '10 Nov 2026', provider: 'Oriental'),
  ];

  static UserProfile profile = const UserProfile(
    uid:            'usr_001',
    name:           'Ramesh Kapoor',
    email:          'ramesh.kapoor@fleetosindia.com',
    phone:          '+91 98100 12345',
    company:        'Kapoor Logistics Pvt. Ltd.',
    role:           'Fleet Owner',
    avatarInitials: 'RK',
  );

  static List<double> weeklyEarnings  = [42000, 58000, 35000, 71000, 63000, 80000, 55000];
  static List<double> monthlyEarnings = [320000, 410000, 380000, 520000, 490000, 610000];
  static List<String> weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static List<String> months   = ['Nov', 'Dec', 'Jan', 'Feb', 'Mar', 'Apr'];

  // ── helpers ──
  static String nextId(List list) => (list.length + 1).toString();

  static String initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

// Keep SampleData as alias for backward compat
class SampleData {
  static List<TruckModel>    get trucks    => AppStore.trucks;
  static List<DriverModel>   get drivers   => AppStore.drivers;
  static List<InsuranceModel> get insurance => AppStore.insurance;
  static List<double> get weeklyEarnings   => AppStore.weeklyEarnings;
  static List<double> get monthlyEarnings  => AppStore.monthlyEarnings;
  static List<String> get weekDays         => AppStore.weekDays;
  static List<String> get months           => AppStore.months;
}
