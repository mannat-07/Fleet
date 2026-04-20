import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/theme.dart';
import '../models/models.dart';
import '../widgets/theme_toggle.dart';
import 'trucks_screen.dart';
import 'drivers_screen.dart';
import 'insurance_screen.dart';
import 'earnings_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _staggerController;
  final List<Animation<double>> _cardAnims = [];

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    for (int i = 0; i < 4; i++) {
      _cardAnims.add(CurvedAnimation(
        parent: _staggerController,
        curve: Interval(i * 0.15, 0.6 + i * 0.1, curve: Curves.easeOutCubic),
      ));
    }
    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  // Refresh dashboard counts when returning from sub-screens
  void _pushAndRefresh(Widget screen) async {
    await Navigator.push(context, _fadeRoute(screen));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = FleetTheme.of(context).colors;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: c.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context, c)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  delegate: SliverChildListDelegate([
                    _animated(0, _TrucksTile(anim: _cardAnims[0], onTap: () => _pushAndRefresh(const TrucksScreen()))),
                    _animated(1, _DriversTile(anim: _cardAnims[1], onTap: () => _pushAndRefresh(const DriversScreen()))),
                    _animated(2, _InsuranceTile(anim: _cardAnims[2], onTap: () => _pushAndRefresh(const InsuranceScreen()))),
                    _animated(3, _EarningsTile(anim: _cardAnims[3], onTap: () => _pushAndRefresh(const EarningsScreen()))),
                  ]),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
    );
  }

  Widget _animated(int i, Widget child) => AnimatedBuilder(
    animation: _cardAnims[i],
    builder: (_, __) => Opacity(
      opacity: _cardAnims[i].value,
      child: Transform.translate(
          offset: Offset(0, 30 * (1 - _cardAnims[i].value)), child: child),
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
                Text('Dashboard',
                    style: TextStyle(
                        color: c.text, fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text('Overview of your fleet',
                    style: TextStyle(color: c.textSub, fontSize: 14)),
              ],
            ),
          ),
          const ThemeToggle(),
          const SizedBox(width: 10),
          _NotificationBell(c: c),
          const SizedBox(width: 10),
          // Avatar → Profile
          GestureDetector(
            onTap: () => _pushAndRefresh(const ProfileScreen()),
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                  gradient: AppColors.orangeGradient,
                  borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Text(p.avatarInitials,
                  style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivity(FleetColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('Recent Activity',
              style: TextStyle(
                  color: c.text, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          ..._items.map((item) => _ActivityRow(item: item, c: c)),
        ],
      ),
    );
  }

  static const _items = [
    _Act(Icons.local_shipping, 'MH12 AB 1234 started trip',
        'Mumbai → Pune • 2 min ago', AppColors.orangeStart),
    _Act(Icons.person, 'Rajesh Kumar checked in',
        'Driver verified • 15 min ago', AppColors.green),
    _Act(Icons.warning_amber, 'Insurance expiring soon',
        'DL08 CD 5678 • 10 days left', AppColors.amber),
    _Act(Icons.payments, 'Payment received',
        '₹71,000 • Today 09:30 AM', AppColors.green),
  ];
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
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.isDark ? const Color(0x0AFFFFFF) : c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.cardBorder),
        boxShadow: c.isDark
            ? []
            : [BoxShadow(color: const Color(0x08000000), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                color: item.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: TextStyle(
                        color: c.text, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(item.subtitle,
                    style: TextStyle(color: c.textSub, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final FleetColors c;
  const _NotificationBell({required this.c});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: c.isDark ? const Color(0x12FFFFFF) : c.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.cardBorder),
            boxShadow: c.isDark
                ? []
                : [BoxShadow(color: const Color(0x08000000), blurRadius: 8)],
          ),
          child: Icon(Icons.notifications_outlined, color: c.text, size: 20),
        ),
        Positioned(
          top: 8, right: 8,
          child: Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(
                  color: AppColors.orangeStart, shape: BoxShape.circle)),
        ),
      ],
    );
  }
}

// ─── Tiles ────────────────────────────────────────────────────────────────────

class _TrucksTile extends StatelessWidget {
  final Animation<double> anim;
  final VoidCallback onTap;
  const _TrucksTile({required this.anim, required this.onTap});

  @override
  Widget build(BuildContext context) => _DashTile(
    onTap: onTap,
    icon: Icons.local_shipping, iconColor: AppColors.orangeStart,
    title: '${AppStore.trucks.length}', label: 'Total Trucks',
    sub: '${AppStore.trucks.where((t) => t.status == 'Active').length} Active  •  ${AppStore.trucks.where((t) => t.status == 'On Trip').length} On Trip',
  );
}

class _DriversTile extends StatelessWidget {
  final Animation<double> anim;
  final VoidCallback onTap;
  const _DriversTile({required this.anim, required this.onTap});

  @override
  Widget build(BuildContext context) => _DashTile(
    onTap: onTap,
    icon: Icons.people, iconColor: AppColors.blue,
    title: '${AppStore.drivers.length}', label: 'Total Drivers',
    sub: '${AppStore.drivers.where((d) => d.status == 'Available').length} Available',
  );
}

class _InsuranceTile extends StatelessWidget {
  final Animation<double> anim;
  final VoidCallback onTap;
  const _InsuranceTile({required this.anim, required this.onTap});

  @override
  Widget build(BuildContext context) => _DashTile(
    onTap: onTap,
    icon: Icons.shield_outlined, iconColor: AppColors.green,
    title: '${AppStore.insurance.length}', label: 'Insurance',
    sub: '${AppStore.insurance.where((i) => i.status == 'Valid').length} Valid  •  ${AppStore.insurance.where((i) => i.status == 'Expiring').length} Expiring',
  );
}

class _EarningsTile extends StatelessWidget {
  final Animation<double> anim;
  final VoidCallback onTap;
  const _EarningsTile({required this.anim, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = FleetTheme.of(context).colors;
    return GestureDetector(
      onTap: onTap,
      child: _TileShell(
        c: c,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                    color: AppColors.purple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.payments, color: AppColors.purple, size: 20),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, color: c.textSub, size: 12),
            ]),
            const SizedBox(height: 10),
            Text('₹4.04L',
                style: TextStyle(
                    color: c.text, fontSize: 22, fontWeight: FontWeight.w900)),
            Text('Earnings', style: TextStyle(color: c.textSub, fontSize: 12)),
            const SizedBox(height: 8),
            Expanded(child: _MiniChart(c: c)),
          ],
        ),
      ),
    );
  }
}

class _MiniChart extends StatelessWidget {
  final FleetColors c;
  const _MiniChart({required this.c});

  @override
  Widget build(BuildContext context) {
    return LineChart(LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineTouchData: const LineTouchData(enabled: false),
      lineBarsData: [
        LineChartBarData(
          spots: AppStore.weeklyEarnings
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), e.value / 1000))
              .toList(),
          isCurved: true,
          gradient: const LinearGradient(
              colors: [AppColors.purple, Color(0xFF7B1FA2)]),
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppColors.purple.withOpacity(c.isDark ? 0.2 : 0.1),
                Colors.transparent
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    ));
  }
}

class _DashTile extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Color iconColor;
  final String title, label, sub;

  const _DashTile({
    required this.onTap, required this.icon, required this.iconColor,
    required this.title, required this.label, required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final c = FleetTheme.of(context).colors;
    return GestureDetector(
      onTap: onTap,
      child: _TileShell(
        c: c,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, color: c.textSub, size: 12),
            ]),
            const Spacer(),
            Text(title,
                style: TextStyle(
                    color: c.text, fontSize: 32, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: c.text, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(sub,
                style: TextStyle(color: c.textSub, fontSize: 11), maxLines: 2),
          ],
        ),
      ),
    );
  }
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
          BoxShadow(
              color: const Color(0x0F000000),
              blurRadius: 16,
              offset: const Offset(0, 4)),
          BoxShadow(
              color: AppColors.orangeStart.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

PageRouteBuilder _fadeRoute(Widget page) => PageRouteBuilder(
  pageBuilder: (_, a, __) => page,
  transitionsBuilder: (_, anim, __, child) => FadeTransition(
    opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
    child: SlideTransition(
      position: Tween<Offset>(
              begin: const Offset(0, 0.05), end: Offset.zero)
          .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
      child: child,
    ),
  ),
  transitionDuration: const Duration(milliseconds: 350),
);
