import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../models/models.dart';
import '../widgets/theme_toggle.dart';
import 'profile_screen.dart';

class OrgDashboardScreen extends StatefulWidget {
  const OrgDashboardScreen({super.key});

  @override
  State<OrgDashboardScreen> createState() => _OrgDashboardScreenState();
}

class _OrgDashboardScreenState extends State<OrgDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _staggerController;
  final List<Animation<double>> _cardAnims = [];
  int _selectedIndex = 0;

  final List<OrgTruckEntry> _incoming = [
    OrgTruckEntry(plate: 'MH12 AB 1234', time: '10:30 AM', status: 'Arrived'),
    OrgTruckEntry(plate: 'DL08 CD 5678', time: '11:15 AM', status: 'Waiting'),
    OrgTruckEntry(plate: 'KA05 EF 9012', time: '12:00 PM', status: 'Unloading'),
  ];

  final List<OrgTruckEntry> _outgoing = [
    OrgTruckEntry(plate: 'GJ01 GH 3456', time: '09:45 AM', status: 'Departed'),
    OrgTruckEntry(plate: 'TN22 IJ 7890', time: '10:00 AM', status: 'Loading'),
  ];

  final List<ActivityEntry> _activity = [
    ActivityEntry(message: 'Truck MH12 AB 1234 entered facility', time: '10:30 AM'),
    ActivityEntry(message: 'Truck GJ01 GH 3456 departed', time: '09:45 AM'),
    ActivityEntry(message: 'Truck KA05 EF 9012 started unloading', time: '09:30 AM'),
    ActivityEntry(message: 'Truck DL08 CD 5678 arrived at gate', time: '09:00 AM'),
  ];

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    for (int i = 0; i < 5; i++) {
      _cardAnims.add(CurvedAnimation(
        parent: _staggerController,
        curve: Interval(i * 0.12, 0.6 + i * 0.08, curve: Curves.easeOutCubic),
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
              SliverToBoxAdapter(child: _buildSummaryCards(c)),
              SliverToBoxAdapter(child: _buildTabBar(c)),
              SliverToBoxAdapter(child: _buildTabContent(c)),
              SliverToBoxAdapter(child: _buildActivityFeed(c)),
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
                Text('Truck Movement',
                    style: TextStyle(
                        color: c.text,
                        fontSize: 24,
                        fontWeight: FontWeight.w900)),
                Text('Organization Dashboard',
                    style: TextStyle(color: c.textSub, fontSize: 13)),
              ],
            ),
          ),
          const ThemeToggle(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(FleetColors c) {
    return _animated(
      0,
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Total Today',
                value: '${_incoming.length + _outgoing.length}',
                icon: Icons.local_shipping,
                color: AppColors.orangeStart,
                c: c,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _SummaryCard(
                label: 'Inside Facility',
                value: '${_incoming.where((t) => t.status != 'Departed').length}',
                icon: Icons.warehouse_outlined,
                color: AppColors.blue,
                c: c,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(FleetColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: c.surfaceHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _Tab(label: 'Incoming', selected: _selectedIndex == 0,
                onTap: () => setState(() => _selectedIndex = 0), c: c),
            _Tab(label: 'Outgoing', selected: _selectedIndex == 1,
                onTap: () => setState(() => _selectedIndex = 1), c: c),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(FleetColors c) {
    final list = _selectedIndex == 0 ? _incoming : _outgoing;
    return _animated(
      1,
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          children: list
              .map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TruckEntryCard(entry: entry, c: c),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildActivityFeed(FleetColors c) {
    return _animated(
      2,
      Padding(
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
                    child: const Icon(Icons.bolt, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Live Activity Feed',
                      style: TextStyle(
                          color: c.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 16),
              ..._activity.map((a) => _ActivityItem(entry: a, c: c)),
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
                        Text('Organization',
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
                label: 'Dashboard',
                onTap: () => Navigator.pop(context),
                c: c),
            _DrawerItem(
                icon: Icons.arrow_downward,
                label: 'Incoming Trucks',
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedIndex = 0);
                },
                c: c),
            _DrawerItem(
                icon: Icons.arrow_upward,
                label: 'Outgoing Trucks',
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedIndex = 1);
                },
                c: c),
            _DrawerItem(
                icon: Icons.history,
                label: 'Logs / History',
                onTap: () => Navigator.pop(context),
                c: c),
            _DrawerItem(
                icon: Icons.person_outline,
                label: 'Profile',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()));
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

// ─── Data models ──────────────────────────────────────────────────────────────
class OrgTruckEntry {
  final String plate;
  final String time;
  final String status;
  OrgTruckEntry({required this.plate, required this.time, required this.status});
}

class ActivityEntry {
  final String message;
  final String time;
  ActivityEntry({required this.message, required this.time});
}

// ─── Widgets ──────────────────────────────────────────────────────────────────
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(
                  color: c.text, fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: c.textSub, fontSize: 13)),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final FleetColors c;
  const _Tab(
      {required this.label,
      required this.selected,
      required this.onTap,
      required this.c});

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
            child: Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : c.textSub,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ),
        ),
      ),
    );
  }
}

class _TruckEntryCard extends StatelessWidget {
  final OrgTruckEntry entry;
  final FleetColors c;
  const _TruckEntryCard({required this.entry, required this.c});

  Color _statusColor() {
    switch (entry.status) {
      case 'Arrived':
        return AppColors.green;
      case 'Waiting':
        return AppColors.amber;
      case 'Unloading':
        return AppColors.blue;
      case 'Loading':
        return AppColors.purple;
      case 'Departed':
        return AppColors.red;
      default:
        return AppColors.green;
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
      child: Row(
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
                Text(entry.plate,
                    style: TextStyle(
                        color: c.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(entry.time,
                    style: TextStyle(color: c.textSub, fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(entry.status,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final ActivityEntry entry;
  final FleetColors c;
  const _ActivityItem({required this.entry, required this.c});

  @override
  Widget build(BuildContext context) {
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
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.orangeGradient,
                ),
              ),
              Container(width: 1, height: 28, color: AppColors.orangeStart.withOpacity(0.3)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.message,
                    style: TextStyle(
                        color: c.text, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(entry.time,
                    style: TextStyle(color: c.textSub, fontSize: 11)),
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
