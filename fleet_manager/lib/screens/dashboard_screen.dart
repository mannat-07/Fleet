import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/theme_toggle.dart';
import '../widgets/motion.dart';
import 'trucks_screen.dart';
import 'drivers_screen.dart';
import 'insurance_screen.dart';
import 'earnings_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'ml_recommendations_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _staggerController;
  final List<Animation<double>> _cardAnims = [];

  // API data
  Map<String, dynamic>? _summary;
  List<double> _chartSpots = [];
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    for (int i = 0; i < 4; i++) {
      _cardAnims.add(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(i * 0.15, 0.6 + i * 0.1, curve: Curves.easeOutCubic),
        ),
      );
    }
    // Pre-fill with demo data immediately — UI is never blank
    _seedDemoData();
    _staggerController.forward();
    _loadSummary();
  }

  /// Fills AppStore with demo data right away so tiles show content instantly.
  /// Real API data overwrites this once it loads.
  void _seedDemoData() {
    if (AppStore.trucks.isEmpty) AppStore.trucks = DemoData.trucks();
    if (AppStore.drivers.isEmpty) AppStore.drivers = DemoData.drivers();
    if (AppStore.insurance.isEmpty)
      AppStore.insurance = DemoData.insurance(AppStore.trucks);
    if (_chartSpots.isEmpty) _chartSpots = _demoEarningsSpots();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    // Don't show loading skeleton — demo data is already visible
    try {
      final results = await Future.wait([
        ApiService.getFleetSummary(),
        ApiService.getEarnings(period: 'weekly'),
        ApiService.getTrucks(),
        ApiService.getDrivers(),
        ApiService.getNotifications(),
      ]);

      final summary = results[0] as Map<String, dynamic>?;
      final earnings = results[1] as Map<String, dynamic>?;
      final trucksRaw = results[2] as List<Map<String, dynamic>>;
      final driversRaw = results[3] as List<Map<String, dynamic>>;
      final notifData = results[4] as Map<String, dynamic>;

      final chartData = (earnings?['chartData'] as List? ?? [])
          .map((e) => ((e as Map)['amount'] as num?)?.toDouble() ?? 0.0)
          .toList();

      if (!mounted) return;

      // Overwrite demo with real data only if API returned something
      if (trucksRaw.isNotEmpty)
        AppStore.trucks = trucksRaw.map(TruckModel.fromJson).toList();
      if (driversRaw.isNotEmpty)
        AppStore.drivers = driversRaw.map(DriverModel.fromJson).toList();

      // Rebuild insurance from real trucks (or keep demo if trucks still empty)
      AppStore.insurance = DemoData.insurance(AppStore.trucks);

      final notifCount = notifData['count'] as int? ?? 0;
      AppStore.notificationCount = notifCount;

      setState(() {
        _summary = summary;
        _chartSpots = chartData.isNotEmpty ? chartData : _demoEarningsSpots();
        _notificationCount = notifCount;
      });
    } catch (_) {
      // API failed — demo data already showing, just clear loading flag
      if (mounted) setState(() {});
    }
  }

  // ── Demo data ───────────────────────────────────────────────────────────────
  static List<double> _demoEarningsSpots() {
    final chartData = DemoData.earnings(period: 'weekly')['chartData'] as List;
    return chartData
        .map((e) => ((e as Map)['amount'] as num?)?.toDouble() ?? 0.0)
        .toList();
  }

  void _pushAndRefresh(Widget screen) async {
    await Navigator.push(context, AppMotionRoute.fadeSlideScale(screen));
    if (mounted) {
      setState(() {});
      _loadSummary();
    }
  }

  // Getters — use API summary when available, else derive from AppStore (demo or real)
  int _summaryCount(String group, String key, int fallback) {
    final v = (_summary?[group] as Map?)?[key] as int?;
    return (v != null && v > 0) ? v : fallback;
  }

  int get _totalTrucks {
    return _summaryCount('trucks', 'total', AppStore.trucks.length);
  }

  int get _activeTrucks {
    return _summaryCount(
      'trucks',
      'active',
      AppStore.trucks.where((t) => t.status == 'active').length,
    );
  }

  int get _onTripTrucks {
    return _summaryCount(
      'trucks',
      'onTrip',
      AppStore.trucks.where((t) => t.status == 'on_trip').length,
    );
  }

  int get _totalDrivers {
    return _summaryCount('drivers', 'total', AppStore.drivers.length);
  }

  int get _availDrivers {
    return _summaryCount(
      'drivers',
      'available',
      AppStore.drivers.where((d) => d.status == 'Available').length,
    );
  }

  int get _totalInsurance => AppStore.insurance.length;
  int get _validInsurance =>
      AppStore.insurance.where((i) => i.status == 'Valid').length;
  int get _expiringIns =>
      AppStore.insurance.where((i) => i.status == 'Expiring').length;

  @override
  Widget build(BuildContext context) {
    final c = FleetTheme.of(context).colors;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: c.backgroundGradient),
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.orangeStart,
            backgroundColor: c.surface,
            onRefresh: _loadSummary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context, c)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    delegate: SliverChildListDelegate([
                      _animated(
                        0,
                        _DashTile(
                          onTap: () => _pushAndRefresh(const TrucksScreen()),
                          icon: Icons.local_shipping,
                          iconColor: AppColors.orangeStart,
                          title: '$_totalTrucks',
                          label: 'Total Trucks',
                          sub:
                              '$_activeTrucks Active  •  $_onTripTrucks On Trip',
                        ),
                      ),
                      _animated(
                        1,
                        _DashTile(
                          onTap: () => _pushAndRefresh(const DriversScreen()),
                          icon: Icons.people,
                          iconColor: AppColors.blue,
                          title: '$_totalDrivers',
                          label: 'Total Drivers',
                          sub: '$_availDrivers Available',
                        ),
                      ),
                      _animated(
                        2,
                        _DashTile(
                          onTap: () => _pushAndRefresh(const InsuranceScreen()),
                          icon: Icons.shield_outlined,
                          iconColor: AppColors.green,
                          title: '$_totalInsurance',
                          label: 'Insurance',
                          sub:
                              '$_validInsurance Valid  •  $_expiringIns Expiring',
                        ),
                      ),
                      _animated(
                        3,
                        _EarningsTile(
                          onTap: () => _pushAndRefresh(const EarningsScreen()),
                          chartSpots: _chartSpots,
                        ),
                      ),
                    ]),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.88,
                        ),
                  ),
                ),
                SliverToBoxAdapter(child: _buildActivity(c)),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _animated(int i, Widget child) => AnimatedBuilder(
    animation: _cardAnims[i],
    builder: (_, __) => Opacity(
      opacity: _cardAnims[i].value,
      child: Transform.translate(
        offset: Offset(0, 30 * (1 - _cardAnims[i].value)),
        child: child,
      ),
    ),
  );

  Widget _buildHeader(BuildContext context, FleetColors c) {
    final p = AppStore.profile;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: TextStyle(
                    color: c.text,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Overview of your fleet',
                  style: TextStyle(color: c.textSub, fontSize: 14),
                ),
              ],
            ),
          ),
          const ThemeToggle(),
          const SizedBox(width: 10),
          _NotificationBell(
            c: c,
            count: _notificationCount,
            onTap: () async {
              await Navigator.push(
                context,
                AppMotionRoute.fadeSlideScale(const NotificationsScreen()),
              );
              if (mounted) {
                setState(() {});
                _loadSummary();
              }
            },
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _pushAndRefresh(const ProfileScreen()),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: AppColors.orangeGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                p.avatarInitials.isEmpty ? '?' : p.avatarInitials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivity(FleetColors c) {
    // Build activity from live AppStore data (populated by sub-screens)
    final items = <_Act>[];
    for (final t in AppStore.trucks.take(2)) {
      if (t.status == 'On Trip' || t.status == 'on_trip') {
        items.add(
          _Act(
            Icons.local_shipping,
            '${t.plate} is on trip',
            t.location.isNotEmpty ? t.location : 'In transit',
            AppColors.orangeStart,
          ),
        );
      }
    }
    for (final i
        in AppStore.insurance.where((i) => i.status == 'Expiring').take(1)) {
      items.add(
        _Act(
          Icons.warning_amber,
          'Insurance expiring',
          '${i.truckPlate} — ${i.expiryDate}',
          AppColors.amber,
        ),
      );
    }
    for (final d
        in AppStore.drivers.where((d) => d.status == 'On Trip').take(1)) {
      items.add(
        _Act(
          Icons.person,
          '${d.name} on trip',
          'Truck: ${d.assignedTruck}',
          AppColors.green,
        ),
      );
    }
    if (items.isEmpty) {
      items.addAll([
        const _Act(
          Icons.local_shipping,
          'MH12 AB 1234 dispatched',
          'Mumbai Hub → Pune Route',
          AppColors.orangeStart,
        ),
        const _Act(
          Icons.person,
          'Rajesh Kumar started trip',
          'Truck: MH12 AB 1234',
          AppColors.green,
        ),
        const _Act(
          Icons.warning_amber,
          'Insurance renewal due soon',
          'DL08 CD 5678 — 22 Aug 2026',
          AppColors.amber,
        ),
      ]);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Recent Activity',
            style: TextStyle(
              color: c.text,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          ...items.map((item) => _ActivityRow(item: item, c: c)),
        ],
      ),
    );
  }
}

class _Act {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  const _Act(this.icon, this.title, this.subtitle, this.color);
}

class _ActivityRow extends StatelessWidget {
  final _Act item;
  final FleetColors c;
  const _ActivityRow({required this.item, required this.c});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: c.isDark ? const Color(0x0AFFFFFF) : c.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: c.cardBorder),
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: item.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(item.icon, color: item.color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: TextStyle(
                  color: c.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.subtitle,
                style: TextStyle(color: c.textSub, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _NotificationBell extends StatelessWidget {
  final FleetColors c;
  final int count;
  final VoidCallback onTap;
  const _NotificationBell({
    required this.c,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: c.isDark ? const Color(0x12FFFFFF) : c.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.cardBorder),
              ),
              child: Icon(Icons.notifications_outlined, color: c.text, size: 20),
            ),
            if (count > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      );
}

// ─── Tiles ────────────────────────────────────────────────────────────────────

class _DashTile extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Color iconColor;
  final String title, label, sub;

  const _DashTile({
    required this.onTap,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.label,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final c = FleetTheme.of(context).colors;
    return GestureDetector(
      onTap: onTap,
      child: FloatMotion(
        child: PressScale(
          onTap: onTap,
          child: _TileShell(
            c: c,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Breathing(
                        child: Icon(icon, color: iconColor, size: 20),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_forward_ios, color: c.textSub, size: 12),
                  ],
                ),
                const Spacer(),
                if (int.tryParse(title) != null)
                  CountUpText(
                    value: int.parse(title),
                    style: TextStyle(
                      color: c.text,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                else
                  Text(
                    title,
                    style: TextStyle(
                      color: c.text,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: c.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sub,
                  style: TextStyle(color: c.textSub, fontSize: 11),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EarningsTile extends StatelessWidget {
  final VoidCallback onTap;
  final List<double> chartSpots;

  const _EarningsTile({required this.onTap, required this.chartSpots});

  @override
  Widget build(BuildContext context) {
    final c = FleetTheme.of(context).colors;
    final total = chartSpots.fold(0.0, (a, b) => a + b);
    final label = total > 0 ? '₹${(total / 100000).toStringAsFixed(2)}L' : '—';

    return FloatMotion(
      child: PressScale(
        onTap: onTap,
        child: _TileShell(
          c: c,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.purple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Breathing(
                      child: Icon(
                        Icons.payments,
                        color: AppColors.purple,
                        size: 20,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, color: c.textSub, size: 12),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  color: c.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Earnings',
                style: TextStyle(color: c.textSub, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: chartSpots.length >= 2
                    ? _MiniChart(spots: chartSpots, c: c)
                    : Center(
                        child: Text(
                          'No data',
                          style: TextStyle(color: c.textSub, fontSize: 11),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniChart extends StatelessWidget {
  final List<double> spots;
  final FleetColors c;
  const _MiniChart({required this.spots, required this.c});

  @override
  Widget build(BuildContext context) => LineChart(
    LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineTouchData: const LineTouchData(enabled: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), e.value / 1000))
              .toList(),
          isCurved: true,
          gradient: const LinearGradient(
            colors: [AppColors.purple, Color(0xFF7B1FA2)],
          ),
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppColors.purple.withOpacity(c.isDark ? 0.2 : 0.1),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    ),
  );
}

class _TileShell extends StatelessWidget {
  final FleetColors c;
  final Widget child;
  const _TileShell({required this.c, required this.child});

  @override
  Widget build(BuildContext context) {
    if (c.isDark) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFFFFF).withOpacity(0.07),
                  const Color(0xFFFFFFFF).withOpacity(0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x1AFFFFFF)),
            ),
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.cardBorder),
        boxShadow: [
          const BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.orangeStart.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}
