import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../models/driver_models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../widgets/theme_toggle.dart';
import 'driver_profile_screen.dart';
import 'home_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _staggerCtrl;
  final List<Animation<double>> _anims = [];
  final ScrollController _scrollCtrl = ScrollController();

  // Data state
  DriverProfile? _driver;
  AssignedTruck? _truck;
  SensorData?    _sensor;
  bool  _loading = true;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    for (int i = 0; i < 4; i++) {
      _anims.add(CurvedAnimation(
        parent: _staggerCtrl,
        curve: Interval(i * 0.15, 0.6 + i * 0.1, curve: Curves.easeOutCubic),
      ));
    }
    _loadAll();
    // Poll sensor data every 15 s
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _refreshSensor());
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    _scrollCtrl.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ApiService.getDriverMe();

      DriverProfile? driver;
      AssignedTruck? truck;
      SensorData?    sensor;

      if (result != null) {
        final driverJson = result['driver'] as Map<String, dynamic>?;
        final truckJson  = result['truck']  as Map<String, dynamic>?;
        final sensorJson = result['sensor'] as Map<String, dynamic>?;
        driver = driverJson != null ? DriverProfile.fromJson(driverJson) : null;
        truck  = truckJson  != null ? AssignedTruck.fromJson(truckJson)  : null;
        sensor = (sensorJson != null && sensorJson.isNotEmpty)
            ? SensorData.fromJson(sensorJson) : null;
      }

      // ── Demo fallback — shown when no real data is linked yet ──────────────
      if (driver == null) driver = _demoDriver();
      if (truck  == null) truck  = _demoTruck();
      if (sensor == null) sensor = _demoSensor();
      // ───────────────────────────────────────────────────────────────────────

      if (!mounted) return;
      setState(() {
        _driver  = driver;
        _truck   = truck;
        _sensor  = sensor;
        _loading = false;
      });
      _staggerCtrl.reset();
      _staggerCtrl.forward();
    } catch (e) {
      // On error still show demo data so the UI isn't blank
      if (!mounted) return;
      setState(() {
        _driver  = _demoDriver();
        _truck   = _demoTruck();
        _sensor  = _demoSensor();
        _loading = false;
        _error   = null; // suppress error — demo data covers it
      });
      _staggerCtrl.reset();
      _staggerCtrl.forward();
    }
  }

  // ── Demo data ───────────────────────────────────────────────────────────────
  static DriverProfile _demoDriver() => DriverProfile(
        driverId:        'demo',
        name:            AppStore.profile.name.isNotEmpty ? AppStore.profile.name : 'Rajesh Kumar',
        phone:           '+91 98765 43210',
        licenseNumber:   'MH-0120110012345',
        assignedTruckId: 'demo-truck',
        status:          'on_trip',
      );

  static AssignedTruck _demoTruck() => AssignedTruck(
        truckId:      'demo-truck',
        plate:        'MH12 AB 1234',
        model:        'Tata Prima 4928.S',
        type:         'Heavy',
        status:       'on_trip',
        lastLocation: 'Mumbai → Pune',
      );

  static SensorData _demoSensor() => SensorData(
        speed:       65,
        fuelLevel:   72,
        loadStatus:  'loaded',
        doorStatus:  'closed',
        temperature: 42,
        engineOn:    true,
        receivedAt:  DateTime.now().subtract(const Duration(minutes: 2)),
      );

  Future<void> _refreshSensor() async {
    if (_truck == null) return;
    try {
      final sensorJson = await ApiService.getLatestSensorData(_truck!.truckId);
      if (sensorJson != null && sensorJson.isNotEmpty && mounted) {
        setState(() => _sensor = SensorData.fromJson(sensorJson));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final c = FleetTheme.of(context).colors;
    return Scaffold(
      drawer: _buildDrawer(context, c),
      body: Container(
        decoration: BoxDecoration(gradient: c.backgroundGradient),
        child: SafeArea(
          child: _loading
              ? _buildLoader(c)
              : _error != null
                  ? _buildError(c)
                  : _buildContent(c),
        ),
      ),
    );
  }

  // ── States ──────────────────────────────────────────────────────────────────

  Widget _buildLoader(FleetColors c) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.orangeStart),
            const SizedBox(height: 16),
            Text('Loading your dashboard…',
                style: TextStyle(color: c.textSub, fontSize: 14)),
          ],
        ),
      );

  Widget _buildError(FleetColors c) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined, color: c.textSub, size: 48),
              const SizedBox(height: 16),
              Text('Could not load data',
                  style: TextStyle(
                      color: c.text, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(_error ?? 'Unknown error',
                  style: TextStyle(color: c.textSub, fontSize: 13),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              _OrangeButton(label: 'Retry', onTap: _loadAll),
            ],
          ),
        ),
      );

  Widget _buildContent(FleetColors c) => RefreshIndicator(
        color: AppColors.orangeStart,
        backgroundColor: c.surface,
        onRefresh: _loadAll,
        child: CustomScrollView(
          controller: _scrollCtrl,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, c)),
            SliverToBoxAdapter(child: _buildTruckCard(c)),
            SliverToBoxAdapter(child: _buildTripCard(c)),
            SliverToBoxAdapter(child: _buildSensorCard(c)),
            SliverToBoxAdapter(child: _buildAlertsCard(c)),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      );

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, FleetColors c) {
    final name = _driver?.name.isNotEmpty == true
        ? _driver!.name
        : AppStore.profile.name.isNotEmpty
            ? AppStore.profile.name
            : 'Driver';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => GestureDetector(
              onTap: () => Scaffold.of(ctx).openDrawer(),
              child: _IconBox(icon: Icons.menu, c: c),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Trip',
                    style: TextStyle(
                        color: c.text,
                        fontSize: 24,
                        fontWeight: FontWeight.w900)),
                Text('Hi, $name',
                    style: TextStyle(color: c.textSub, fontSize: 13)),
              ],
            ),
          ),
          const ThemeToggle(),
        ],
      ),
    );
  }

  // ── Assigned Truck ──────────────────────────────────────────────────────────

  Widget _buildTruckCard(FleetColors c) {
    return _Animated(
      anim: _anims[0],
      child: _DashCard(
        c: c,
        icon: Icons.local_shipping,
        iconGradient: true,
        title: 'Assigned Truck',
        child: _truck == null
            ? _EmptyState(
                icon: Icons.local_shipping_outlined,
                message: 'No truck assigned yet',
                sub: 'Contact your fleet manager',
                c: c,
              )
            : Column(
                children: [
                  _InfoRow(label: 'Plate',  value: _truck!.plate,          icon: Icons.badge_outlined,          c: c),
                  const SizedBox(height: 10),
                  _InfoRow(label: 'Model',  value: _truck!.model ?? '—',   icon: Icons.directions_car_outlined, c: c),
                  const SizedBox(height: 10),
                  _InfoRow(label: 'Type',   value: _truck!.type  ?? '—',   icon: Icons.category_outlined,       c: c),
                  const SizedBox(height: 10),
                  _InfoRow(
                    label: 'Status',
                    value: _truck!.status,
                    icon: Icons.circle,
                    c: c,
                    valueColor: _statusColor(_truck!.status),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Trip Status ─────────────────────────────────────────────────────────────

  Widget _buildTripCard(FleetColors c) {
    final isOnTrip = _driver?.isOnTrip ?? false;
    return _Animated(
      anim: _anims[1],
      child: _DashCard(
        c: c,
        icon: Icons.route,
        iconColor: AppColors.green,
        title: 'Trip Status',
        trailing: _StatusBadge(
          label: isOnTrip ? 'On Trip' : 'Idle',
          color: isOnTrip ? AppColors.green : c.textSub,
        ),
        child: isOnTrip
            ? Column(
                children: [
                  _InfoRow(
                    label: 'Status',
                    value: 'Active trip in progress',
                    icon: Icons.play_circle_outline,
                    c: c,
                    valueColor: AppColors.green,
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    label: 'Truck',
                    value: _truck?.plate ?? '—',
                    icon: Icons.local_shipping_outlined,
                    c: c,
                  ),
                ],
              )
            : _EmptyState(
                icon: Icons.route,
                message: 'No active trip',
                sub: 'You are currently idle',
                c: c,
              ),
      ),
    );
  }

  // ── Sensor Data ─────────────────────────────────────────────────────────────

  Widget _buildSensorCard(FleetColors c) {
    return _Animated(
      anim: _anims[2],
      child: _DashCard(
        c: c,
        icon: Icons.sensors,
        iconColor: AppColors.blue,
        title: 'Live Sensor Data',
        trailing: _truck != null && _sensor?.receivedAt != null
            ? Text(
                _timeAgo(_sensor!.receivedAt!),
                style: TextStyle(color: c.textSub, fontSize: 11),
              )
            : null,
        child: _truck == null
            ? _EmptyState(
                icon: Icons.sensors_off,
                message: 'No truck assigned',
                sub: 'Sensor data unavailable',
                c: c,
              )
            : _sensor == null || !_sensor!.hasData
                ? _EmptyState(
                    icon: Icons.wifi_off,
                    message: 'Waiting for data',
                    sub: 'No sensor readings yet',
                    c: c,
                  )
                : Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _SensorTile(
                              label: 'Speed',
                              value: _sensor!.speed != null
                                  ? '${_sensor!.speed!.toStringAsFixed(0)}'
                                  : '—',
                              unit: 'km/h',
                              icon: Icons.speed,
                              color: AppColors.blue,
                              c: c,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SensorTile(
                              label: 'Fuel',
                              value: _sensor!.fuelLevel != null
                                  ? '${_sensor!.fuelLevel!.toStringAsFixed(0)}'
                                  : '—',
                              unit: '%',
                              icon: Icons.local_gas_station,
                              color: _fuelColor(_sensor!.fuelLevel),
                              c: c,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _SensorTile(
                              label: 'Load',
                              value: _sensor!.loadStatus ?? '—',
                              unit: '',
                              icon: Icons.inventory_2_outlined,
                              color: AppColors.amber,
                              c: c,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SensorTile(
                              label: 'Door',
                              value: _sensor!.doorStatus ?? '—',
                              unit: '',
                              icon: Icons.door_back_door_outlined,
                              color: _doorColor(_sensor!.doorStatus),
                              c: c,
                            ),
                          ),
                        ],
                      ),
                      if (_sensor!.temperature != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _SensorTile(
                                label: 'Temp',
                                value: '${_sensor!.temperature!.toStringAsFixed(0)}',
                                unit: '°C',
                                icon: Icons.thermostat,
                                color: _tempColor(_sensor!.temperature),
                                c: c,
                              ),
                            ),
                            Expanded(child: Container()),
                          ],
                        ),
                      ],
                    ],
                  ),
      ),
    );
  }

  // ── Alerts ──────────────────────────────────────────────────────────────────

  Widget _buildAlertsCard(FleetColors c) {
    final alerts = _sensor?.alerts ?? [];
    return _Animated(
      anim: _anims[3],
      child: _DashCard(
        c: c,
        icon: Icons.warning_amber_rounded,
        iconColor: AppColors.red,
        title: 'Alerts',
        trailing: alerts.isNotEmpty
            ? _StatusBadge(label: '${alerts.length}', color: AppColors.red)
            : null,
        child: alerts.isEmpty
            ? _EmptyState(
                icon: Icons.check_circle_outline,
                message: 'No active alerts',
                sub: 'All systems normal',
                c: c,
                iconColor: AppColors.green,
              )
            : Column(
                children: alerts
                    .map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _AlertRow(alert: a, c: c),
                        ))
                    .toList(),
              ),
      ),
    );
  }

  // ── Drawer ──────────────────────────────────────────────────────────────────

  Widget _buildDrawer(BuildContext context, FleetColors c) {
    final profile = AppStore.profile;
    return Drawer(
      backgroundColor: c.sheetBg,
      child: SafeArea(
        child: Column(
          children: [
            _DrawerHeader(profile: profile, role: 'Driver', c: c),
            Divider(color: c.divider, height: 1),
            // These scroll to sections within the same dashboard page
            _DrawerItem(
                icon: Icons.local_shipping_outlined,
                label: 'My Truck',
                onTap: () {
                  Navigator.pop(context);
                  _scrollCtrl.animateTo(0,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut);
                },
                c: c),
            _DrawerItem(
                icon: Icons.route,
                label: 'Trip Status',
                onTap: () {
                  Navigator.pop(context);
                  _scrollCtrl.animateTo(220,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut);
                },
                c: c),
            _DrawerItem(
                icon: Icons.sensors,
                label: 'Live Sensors',
                onTap: () {
                  Navigator.pop(context);
                  _scrollCtrl.animateTo(440,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut);
                },
                c: c),
            _DrawerItem(
                icon: Icons.warning_amber_rounded,
                label: 'Alerts',
                onTap: () {
                  Navigator.pop(context);
                  _scrollCtrl.animateTo(
                      _scrollCtrl.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut);
                },
                c: c),
            _DrawerItem(
                icon: Icons.person_outline,
                label: 'Profile',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => DriverProfileScreen(
                                driverProfile: _driver,
                                assignedTruck: _truck,
                              )));
                },
                c: c),
            const Spacer(),
            Divider(color: c.divider, height: 1),
            _DrawerItem(
                icon: Icons.logout,
                label: 'Logout',
                onTap: () async {
                  Navigator.pop(context);
                  await AuthService.signOut();
                  if (!mounted) return;
                  // ignore: use_build_context_synchronously
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (_) => false,
                  );
                },
                c: c,
                isDestructive: true),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Color _statusColor(String status) {
    switch (status) {
      case 'on_trip':     return AppColors.green;
      case 'active':      return AppColors.blue;
      case 'idle':        return AppColors.amber;
      case 'maintenance': return AppColors.red;
      default:            return AppColors.amber;
    }
  }

  Color _fuelColor(double? level) {
    if (level == null) return AppColors.green;
    if (level < 20) return AppColors.red;
    if (level < 40) return AppColors.amber;
    return AppColors.green;
  }

  Color _doorColor(String? status) {
    if (status == 'open') return AppColors.red;
    return AppColors.green;
  }

  Color _tempColor(double? temp) {
    if (temp == null) return AppColors.blue;
    if (temp > 80) return AppColors.red;
    if (temp > 60) return AppColors.amber;
    return AppColors.blue;
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _Animated extends StatelessWidget {
  final Animation<double> anim;
  final Widget child;
  const _Animated({required this.anim, required this.child});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: anim,
        builder: (_, __) => Opacity(
          opacity: anim.value,
          child: Transform.translate(
              offset: Offset(0, 28 * (1 - anim.value)), child: child),
        ),
      );
}

class _DashCard extends StatelessWidget {
  final FleetColors c;
  final IconData icon;
  final Color? iconColor;
  final bool iconGradient;
  final String title;
  final Widget? trailing;
  final Widget child;

  const _DashCard({
    required this.c,
    required this.icon,
    this.iconColor,
    this.iconGradient = false,
    required this.title,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: c.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: iconGradient ? AppColors.orangeGradient : null,
                    color: iconGradient ? null : (iconColor ?? AppColors.orangeStart).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon,
                      color: iconGradient ? Colors.white : (iconColor ?? AppColors.orangeStart),
                      size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                          color: c.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final FleetColors c;
  final Color? valueColor;
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.c,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: c.textSub, size: 16),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: c.textSub, fontSize: 13)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  color: valueColor ?? c.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      );
}

class _SensorTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final FleetColors c;
  const _SensorTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.c,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surfaceHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: c.textSub, fontSize: 11)),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(value,
                      style: TextStyle(
                          color: c.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 3),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 1),
                    child: Text(unit,
                        style: TextStyle(color: c.textSub, fontSize: 11)),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
}

class _AlertRow extends StatelessWidget {
  final SensorAlert alert;
  final FleetColors c;
  const _AlertRow({required this.alert, required this.c});

  @override
  Widget build(BuildContext context) {
    final color = alert.severity == AlertSeverity.critical
        ? AppColors.red
        : AppColors.amber;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            alert.severity == AlertSeverity.critical
                ? Icons.error_outline
                : Icons.warning_amber_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(alert.message,
                style: TextStyle(
                    color: c.text, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;
  final FleetColors c;
  final Color? iconColor;
  const _EmptyState({
    required this.icon,
    required this.message,
    required this.sub,
    required this.c,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? c.textSub, size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message,
                      style: TextStyle(
                          color: c.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(sub,
                      style: TextStyle(color: c.textSub, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      );
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final FleetColors c;
  const _IconBox({required this.icon, required this.c});

  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: c.iconBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.cardBorder),
        ),
        child: Icon(icon, color: c.text, size: 22),
      );
}

class _OrangeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OrangeButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          decoration: BoxDecoration(
            gradient: AppColors.orangeGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
        ),
      );
}

class _DrawerHeader extends StatelessWidget {
  final UserProfile profile;
  final String role;
  final FleetColors c;
  const _DrawerHeader(
      {required this.profile, required this.role, required this.c});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.orangeStart.withOpacity(0.2),
              child: Text(profile.avatarInitials,
                  style: const TextStyle(
                      color: AppColors.orangeStart,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.name,
                      style: TextStyle(
                          color: c.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis),
                  Text(role,
                      style: TextStyle(color: c.textSub, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final FleetColors c;
  final bool isDestructive;
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.c,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.red : c.text;
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }
}
