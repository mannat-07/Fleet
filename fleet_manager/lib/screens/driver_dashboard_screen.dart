import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../models/models.dart';
import '../widgets/theme_toggle.dart';
import 'profile_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen>
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

  @override
  Widget build(BuildContext context) {
    final c = FleetTheme.of(context).colors;
    return Scaffold(
      drawer: _buildDrawer(context, c),
      body: Container(
        decoration: BoxDecoration(gradient: c.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context, c)),
              SliverToBoxAdapter(child: _buildAssignedTruck(c)),
              SliverToBoxAdapter(child: _buildTripStatus(c)),
              SliverToBoxAdapter(child: _buildSensorData(c)),
              SliverToBoxAdapter(child: _buildAlerts(c)),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, FleetColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => GestureDetector(
              onTap: () => Scaffold.of(ctx).openDrawer(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.iconBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.cardBorder),
                ),
                child: Icon(Icons.menu, color: c.text, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Trip',
                    style: TextStyle(
                        color: c.text,
                        fontSize: 24,
                        fontWeight: FontWeight.w900)),
                Text('Driver Dashboard',
                    style: TextStyle(color: c.textSub, fontSize: 13)),
              ],
            ),
          ),
          const ThemeToggle(),
        ],
      ),
    );
  }

  Widget _buildAssignedTruck(FleetColors c) {
    return _animated(
      0,
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: _GlassCard(
          c: c,
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
                    child: const Icon(Icons.local_shipping,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Assigned Truck',
                      style: TextStyle(
                          color: c.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 16),
              _InfoRow(
                  label: 'Truck ID',
                  value: 'MH12 AB 1234',
                  icon: Icons.badge_outlined,
                  c: c),
              const SizedBox(height: 12),
              _InfoRow(
                  label: 'Model',
                  value: 'Tata Prima 4928.S',
                  icon: Icons.directions_car_outlined,
                  c: c),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripStatus(FleetColors c) {
    return _animated(
      1,
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: _GlassCard(
          c: c,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.route, color: AppColors.green, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Trip Status',
                      style: TextStyle(
                          color: c.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.green.withOpacity(0.3)),
                    ),
                    child: const Text('On Trip',
                        style: TextStyle(
                            color: AppColors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _InfoRow(
                  label: 'Start Time',
                  value: '08:30 AM',
                  icon: Icons.access_time,
                  c: c),
              const SizedBox(height: 12),
              _InfoRow(
                  label: 'Duration',
                  value: '4h 25m',
                  icon: Icons.timer_outlined,
                  c: c),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSensorData(FleetColors c) {
    return _animated(
      2,
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: _GlassCard(
          c: c,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.sensors, color: AppColors.blue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Live Sensor Data',
                      style: TextStyle(
                          color: c.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SensorCard(
                      label: 'Speed',
                      value: '65',
                      unit: 'km/h',
                      icon: Icons.speed,
                      color: AppColors.blue,
                      c: c,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SensorCard(
                      label: 'Fuel',
                      value: '78',
                      unit: '%',
                      icon: Icons.local_gas_station,
                      color: AppColors.green,
                      c: c,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SensorCard(
                      label: 'Load',
                      value: '85',
                      unit: '%',
                      icon: Icons.inventory_2_outlined,
                      color: AppColors.amber,
                      c: c,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SensorCard(
                      label: 'Door',
                      value: 'Closed',
                      unit: '',
                      icon: Icons.door_back_door_outlined,
                      color: AppColors.green,
                      c: c,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlerts(FleetColors c) {
    return _animated(
      3,
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: _GlassCard(
          c: c,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.warning_amber_rounded,
                        color: AppColors.red, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Alerts',
                      style: TextStyle(
                          color: c.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 16),
              _AlertItem(
                  message: 'Load at 85% - Near capacity',
                  time: '2 min ago',
                  color: AppColors.amber,
                  c: c),
              const SizedBox(height: 8),
              _AlertItem(
                  message: 'All systems normal',
                  time: 'Now',
                  color: AppColors.green,
                  c: c),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, FleetColors c) {
    return Drawer(
      backgroundColor: c.sheetBg,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.orangeStart.withOpacity(0.2),
                    child: Text(AppStore.profile.avatarInitials,
                        style: const TextStyle(
                            color: AppColors.orangeStart,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStore.profile.name,
                            style: TextStyle(
                                color: c.text,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        Text('Driver',
                            style: TextStyle(color: c.textSub, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: c.divider, height: 1),
            _DrawerItem(
                icon: Icons.dashboard_outlined,
                label: 'My Truck',
                onTap: () => Navigator.pop(context),
                c: c),
            _DrawerItem(
                icon: Icons.route,
                label: 'Trip Status',
                onTap: () => Navigator.pop(context),
                c: c),
            _DrawerItem(
                icon: Icons.warning_amber_rounded,
                label: 'Alerts',
                onTap: () => Navigator.pop(context),
                c: c),
            _DrawerItem(
                icon: Icons.person_outline,
                label: 'Profile',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ProfileScreen()));
                },
                c: c),
            const Spacer(),
            Divider(color: c.divider, height: 1),
            _DrawerItem(
                icon: Icons.logout,
                label: 'Logout',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/home', (_) => false);
                },
                c: c,
                isDestructive: true),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _animated(int index, Widget child) {
    return AnimatedBuilder(
      animation: _cardAnims[index],
      builder: (_, __) => Opacity(
        opacity: _cardAnims[index].value,
        child: Transform.translate(
          offset: Offset(0, 30 * (1 - _cardAnims[index].value)),
          child: child,
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final FleetColors c;
  const _GlassCard({required this.child, required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.cardBorder),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final FleetColors c;
  const _InfoRow(
      {required this.label,
      required this.value,
      required this.icon,
      required this.c});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: c.textSub, size: 18),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: c.textSub, fontSize: 14)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                color: c.text, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _SensorCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final FleetColors c;
  const _SensorCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: c.textSub, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: TextStyle(
                      color: c.text, fontSize: 20, fontWeight: FontWeight.w800)),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(unit,
                      style: TextStyle(color: c.textSub, fontSize: 12)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  final String message;
  final String time;
  final Color color;
  final FleetColors c;
  const _AlertItem(
      {required this.message,
      required this.time,
      required this.color,
      required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, color: color, size: 8),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message,
                    style: TextStyle(
                        color: c.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(time, style: TextStyle(color: c.textSub, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
