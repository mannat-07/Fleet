import 'package:flutter/material.dart';
import '../models/models.dart';
import '../models/org_models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../widgets/theme_toggle.dart';
import '../widgets/motion.dart';
import 'org_profile_screen.dart';
import 'home_screen.dart';

class OrgDashboardScreen extends StatefulWidget {
  const OrgDashboardScreen({super.key});

  @override
  State<OrgDashboardScreen> createState() => _OrgDashboardScreenState();
}

class _OrgDashboardScreenState extends State<OrgDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _staggerCtrl;
  final List<Animation<double>> _anims = [];
  final ScrollController _scrollCtrl = ScrollController();
  int _tabIndex = 0;

  // Data state
  FleetSummary? _summary;
  List<OrgTruck> _allTrucks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    for (int i = 0; i < 4; i++) {
      _anims.add(
        CurvedAnimation(
          parent: _staggerCtrl,
          curve: Interval(i * 0.14, 0.6 + i * 0.1, curve: Curves.easeOutCubic),
        ),
      );
    }
    _loadAll();
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiService.getFleetSummary(),
        ApiService.getActiveTrucks(),
      ]);

      final summaryJson = results[0] as Map<String, dynamic>?;
      final trucksJson = results[1] as List<Map<String, dynamic>>;

      FleetSummary? summary = summaryJson != null
          ? FleetSummary.fromJson(summaryJson)
          : null;
      List<OrgTruck> trucks = trucksJson.map(OrgTruck.fromJson).toList();

      // ── Demo fallback — shown when no real data exists yet ─────────────────
      if (trucks.isEmpty) trucks = _demoTrucks();
      if (summary == null || summary.totalTrucks == 0)
        summary = _demoSummary(trucks);
      // ───────────────────────────────────────────────────────────────────────

      if (!mounted) return;
      setState(() {
        _summary = summary;
        _allTrucks = trucks;
        _loading = false;
      });
      _staggerCtrl.reset();
      _staggerCtrl.forward();
    } catch (e) {
      // On error show demo data
      if (!mounted) return;
      final trucks = _demoTrucks();
      setState(() {
        _summary = _demoSummary(trucks);
        _allTrucks = trucks;
        _loading = false;
        _error = null;
      });
      _staggerCtrl.reset();
      _staggerCtrl.forward();
    }
  }

  // ── Demo data ───────────────────────────────────────────────────────────────
  static List<OrgTruck> _demoTrucks() => [
    OrgTruck(
      truckId: 'd1',
      plate: 'MH12 AB 1234',
      model: 'Tata Prima 4928.S',
      type: 'heavy',
      status: 'on_trip',
      lastLocation: 'Mumbai → Pune',
      lastSeen: DateTime.now().subtract(const Duration(minutes: 5)),
      sensor: SensorSnapshot(
        speed: 68,
        fuelLevel: 74,
        loadStatus: 'loaded',
        doorStatus: 'closed',
        receivedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ),
    OrgTruck(
      truckId: 'd2',
      plate: 'DL08 CD 5678',
      model: 'Ashok Leyland 3518',
      type: 'heavy',
      status: 'active',
      lastLocation: 'Delhi Hub',
      lastSeen: DateTime.now().subtract(const Duration(minutes: 12)),
      sensor: SensorSnapshot(
        speed: 0,
        fuelLevel: 88,
        loadStatus: 'empty',
        doorStatus: 'closed',
        receivedAt: DateTime.now().subtract(const Duration(minutes: 12)),
      ),
    ),
    OrgTruck(
      truckId: 'd3',
      plate: 'KA05 EF 9012',
      model: 'Eicher Pro 6031',
      type: 'medium',
      status: 'on_trip',
      lastLocation: 'Bangalore → Chennai',
      lastSeen: DateTime.now().subtract(const Duration(minutes: 3)),
      sensor: SensorSnapshot(
        speed: 72,
        fuelLevel: 55,
        loadStatus: 'partial',
        doorStatus: 'closed',
        receivedAt: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
    ),
    OrgTruck(
      truckId: 'd4',
      plate: 'GJ01 GH 3456',
      model: 'Tata LPT 3118',
      type: 'light',
      status: 'active',
      lastLocation: 'Ahmedabad Depot',
      lastSeen: DateTime.now().subtract(const Duration(minutes: 20)),
      sensor: SensorSnapshot(
        speed: 0,
        fuelLevel: 91,
        loadStatus: 'empty',
        doorStatus: 'locked',
        receivedAt: DateTime.now().subtract(const Duration(minutes: 20)),
      ),
    ),
    OrgTruck(
      truckId: 'd5',
      plate: 'TN22 IJ 7890',
      model: 'BharatBenz 3523R',
      type: 'tanker',
      status: 'on_trip',
      lastLocation: 'Chennai → Coimbatore',
      lastSeen: DateTime.now().subtract(const Duration(minutes: 8)),
      sensor: SensorSnapshot(
        speed: 58,
        fuelLevel: 43,
        loadStatus: 'loaded',
        doorStatus: 'closed',
        receivedAt: DateTime.now().subtract(const Duration(minutes: 8)),
      ),
    ),
  ];

  static FleetSummary _demoSummary(List<OrgTruck> trucks) => FleetSummary(
    totalTrucks: trucks.length,
    activeTrucks: trucks.where((t) => t.isInside).length,
    onTripTrucks: trucks.where((t) => t.isIncoming).length,
    idleTrucks: 0,
    totalDrivers: trucks.length,
    availableDrivers: trucks.where((t) => t.isInside).length,
  );

  List<OrgTruck> get _incoming =>
      _allTrucks.where((t) => t.isIncoming).toList();

  List<OrgTruck> get _inside => _allTrucks.where((t) => t.isInside).toList();

  List<OrgTruck> get _tabList => _tabIndex == 0 ? _incoming : _inside;

  List<ActivityLog> get _activityLogs {
    final logs = _allTrucks.map(ActivityLog.fromTruck).toList();
    logs.sort((a, b) => b.time.compareTo(a.time));
    return logs.take(10).toList();
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
        Text(
          'Loading dashboard…',
          style: TextStyle(color: c.textSub, fontSize: 14),
        ),
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
          Text(
            'Could not load data',
            style: TextStyle(
              color: c.text,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: TextStyle(color: c.textSub, fontSize: 13),
            textAlign: TextAlign.center,
          ),
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
        SliverToBoxAdapter(child: _buildSummaryRow(c)),
        SliverToBoxAdapter(child: _buildTabBar(c)),
        SliverToBoxAdapter(child: _buildTruckList(c)),
        SliverToBoxAdapter(child: _buildActivityFeed(c)),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    ),
  );

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, FleetColors c) => Padding(
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
              Text(
                'Truck Movement',
                style: TextStyle(
                  color: c.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Organization Dashboard',
                style: TextStyle(color: c.textSub, fontSize: 13),
              ),
            ],
          ),
        ),
        const ThemeToggle(),
      ],
    ),
  );

  // ── Summary Cards ────────────────────────────────────────────────────────────

  Widget _buildSummaryRow(FleetColors c) {
    final total = _summary?.totalTrucks ?? _allTrucks.length;
    final inside = _summary?.trucksInsideFacility ?? _inside.length;
    final onTrip = _summary?.onTripTrucks ?? _incoming.length;
    final drivers = _summary?.availableDrivers ?? 0;

    return _Animated(
      anim: _anims[0],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Total Trucks',
                    value: '$total',
                    icon: Icons.local_shipping,
                    color: AppColors.orangeStart,
                    c: c,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _SummaryCard(
                    label: 'Inside Facility',
                    value: '$inside',
                    icon: Icons.warehouse_outlined,
                    color: AppColors.blue,
                    c: c,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'On Trip',
                    value: '$onTrip',
                    icon: Icons.route,
                    color: AppColors.green,
                    c: c,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _SummaryCard(
                    label: 'Drivers Available',
                    value: '$drivers',
                    icon: Icons.person_outline,
                    color: AppColors.purple,
                    c: c,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab Bar ──────────────────────────────────────────────────────────────────

  Widget _buildTabBar(FleetColors c) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
    child: Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _Tab(
            label: 'Incoming (${_incoming.length})',
            selected: _tabIndex == 0,
            onTap: () => setState(() => _tabIndex = 0),
            c: c,
          ),
          _Tab(
            label: 'Inside (${_inside.length})',
            selected: _tabIndex == 1,
            onTap: () => setState(() => _tabIndex = 1),
            c: c,
          ),
        ],
      ),
    ),
  );

  // ── Truck List ───────────────────────────────────────────────────────────────

  Widget _buildTruckList(FleetColors c) {
    final list = _tabList;
    return _Animated(
      anim: _anims[1],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: list.isEmpty
            ? _EmptyCard(
                icon: Icons.local_shipping_outlined,
                message: _tabIndex == 0
                    ? 'No trucks currently on trip'
                    : 'No trucks inside facility',
                c: c,
              )
            : Column(
                children: list
                    .map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _TruckCard(truck: t, c: c),
                      ),
                    )
                    .toList(),
              ),
      ),
    );
  }

  // ── Activity Feed ────────────────────────────────────────────────────────────

  Widget _buildActivityFeed(FleetColors c) {
    final logs = _activityLogs;
    return _Animated(
      anim: _anims[2],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
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
                      gradient: AppColors.orangeGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.bolt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Live Activity Feed',
                    style: TextStyle(
                      color: c.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (logs.isEmpty)
                _EmptyCard(
                  icon: Icons.history_toggle_off,
                  message: 'No recent activity',
                  c: c,
                )
              else
                ...logs.asMap().entries.map(
                  (e) => _ActivityRow(
                    log: e.value,
                    isLast: e.key == logs.length - 1,
                    c: c,
                  ),
                ),
            ],
          ),
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
            _DrawerHeader(profile: profile, role: 'Organization', c: c),
            Divider(color: c.divider, height: 1),
            _DrawerItem(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              onTap: () {
                Navigator.pop(context);
                _scrollCtrl.animateTo(
                  0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                );
              },
              c: c,
            ),
            _DrawerItem(
              icon: Icons.arrow_circle_down_outlined,
              label: 'Incoming Trucks',
              onTap: () {
                Navigator.pop(context);
                setState(() => _tabIndex = 0);
                _scrollCtrl.animateTo(
                  320,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                );
              },
              c: c,
            ),
            _DrawerItem(
              icon: Icons.arrow_circle_up_outlined,
              label: 'Inside Facility',
              onTap: () {
                Navigator.pop(context);
                setState(() => _tabIndex = 1);
                _scrollCtrl.animateTo(
                  320,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                );
              },
              c: c,
            ),
            _DrawerItem(
              icon: Icons.history,
              label: 'Activity Feed',
              onTap: () {
                Navigator.pop(context);
                _scrollCtrl.animateTo(
                  _scrollCtrl.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                );
              },
              c: c,
            ),
            _DrawerItem(
              icon: Icons.person_outline,
              label: 'Profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  AppMotionRoute.fadeSlideScale(const OrgProfileScreen()),
                );
              },
              c: c,
            ),
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
                  AppMotionRoute.fadeSlideScale(const HomeScreen()),
                  (_) => false,
                );
              },
              c: c,
              isDestructive: true,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

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
        offset: Offset(0, 28 * (1 - anim.value)),
        child: child,
      ),
    ),
  );
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final FleetColors c;
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.c,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: c.cardBg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: c.cardBorder),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: c.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(label, style: TextStyle(color: c.textSub, fontSize: 11)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final FleetColors c;
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.c,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.orangeGradient : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : c.textSub,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    ),
  );
}

class _TruckCard extends StatelessWidget {
  final OrgTruck truck;
  final FleetColors c;
  const _TruckCard({required this.truck, required this.c});

  Color _statusColor() {
    switch (truck.status) {
      case 'on_trip':
        return AppColors.green;
      case 'active':
        return AppColors.blue;
      case 'idle':
        return AppColors.amber;
      case 'maintenance':
        return AppColors.red;
      default:
        return AppColors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.local_shipping, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      truck.plate,
                      style: TextStyle(
                        color: c.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (truck.model != null)
                      Text(
                        truck.model!,
                        style: TextStyle(color: c.textSub, fontSize: 12),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  truck.displayStatus,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (truck.sensor != null) ...[
            const SizedBox(height: 12),
            Divider(color: c.divider, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                if (truck.sensor!.speed != null)
                  _SensorChip(
                    icon: Icons.speed,
                    label: '${truck.sensor!.speed!.toStringAsFixed(0)} km/h',
                    c: c,
                  ),
                if (truck.sensor!.fuelLevel != null) ...[
                  const SizedBox(width: 8),
                  _SensorChip(
                    icon: Icons.local_gas_station,
                    label: '${truck.sensor!.fuelLevel!.toStringAsFixed(0)}%',
                    c: c,
                  ),
                ],
                if (truck.sensor!.doorStatus != null) ...[
                  const SizedBox(width: 8),
                  _SensorChip(
                    icon: Icons.door_back_door_outlined,
                    label: truck.sensor!.doorStatus!,
                    c: c,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SensorChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final FleetColors c;
  const _SensorChip({required this.icon, required this.label, required this.c});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: c.surfaceHigh,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: c.textSub, size: 12),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: c.textSub, fontSize: 11)),
      ],
    ),
  );
}

class _ActivityRow extends StatelessWidget {
  final ActivityLog log;
  final bool isLast;
  final FleetColors c;
  const _ActivityRow({
    required this.log,
    required this.isLast,
    required this.c,
  });

  Color _dotColor() {
    switch (log.type) {
      case ActivityType.arrival:
        return AppColors.green;
      case ActivityType.departure:
        return AppColors.red;
      case ActivityType.movement:
        return AppColors.orangeStart;
      case ActivityType.idle:
        return AppColors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dot = _dotColor();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
              ),
              if (!isLast)
                Container(width: 1, height: 28, color: dot.withOpacity(0.25)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.message,
                  style: TextStyle(
                    color: c.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  log.formattedTime,
                  style: TextStyle(color: c.textSub, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final FleetColors c;
  const _EmptyCard({
    required this.icon,
    required this.message,
    required this.c,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: c.cardBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: c.cardBorder),
    ),
    child: Row(
      children: [
        Icon(icon, color: c.textSub, size: 28),
        const SizedBox(width: 14),
        Text(message, style: TextStyle(color: c.textSub, fontSize: 14)),
      ],
    ),
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
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    ),
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

class _DrawerHeader extends StatelessWidget {
  final UserProfile profile;
  final String role;
  final FleetColors c;
  const _DrawerHeader({
    required this.profile,
    required this.role,
    required this.c,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.orangeStart.withOpacity(0.2),
          child: Text(
            profile.avatarInitials,
            style: const TextStyle(
              color: AppColors.orangeStart,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.name,
                style: TextStyle(
                  color: c.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(role, style: TextStyle(color: c.textSub, fontSize: 12)),
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
      title: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      onTap: onTap,
    );
  }
}
