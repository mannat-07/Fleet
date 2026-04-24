import 'package:flutter/material.dart';
import '../models/models.dart';
import '../models/driver_models.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../widgets/back_button_widget.dart';
import '../widgets/glass_input.dart';
import '../widgets/custom_button.dart';
import '../widgets/theme_toggle.dart';
import '../widgets/motion.dart';
import 'home_screen.dart';

class DriverProfileScreen extends StatefulWidget {
  final DriverProfile? driverProfile;
  final AssignedTruck? assignedTruck;
  const DriverProfileScreen({
    super.key,
    this.driverProfile,
    this.assignedTruck,
  });

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  bool _editing = false;
  bool _saving = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    final p = AppStore.profile;
    _nameCtrl = TextEditingController(
      text: widget.driverProfile?.name ?? p.name,
    );
    _phoneCtrl = TextEditingController(
      text: widget.driverProfile?.phone ?? p.phone,
    );
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _save() async {
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    AppStore.profile = AppStore.profile.copyWith(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
    );
    setState(() {
      _saving = false;
      _editing = false;
    });
  }

  void _logout() async {
    await AuthService.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      AppMotionRoute.fadeSlideScale(const HomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = FleetTheme.of(context).colors;
    final p = AppStore.profile;
    final driver = widget.driverProfile;
    final truck = widget.assignedTruck;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: c.backgroundGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(c)),
                SliverToBoxAdapter(child: _buildAvatar(c, p, driver)),
                SliverToBoxAdapter(child: _buildTruckInfo(c, truck)),
                SliverToBoxAdapter(
                  child: _editing
                      ? _buildEditForm(c)
                      : _buildInfoCards(c, p, driver),
                ),
                SliverToBoxAdapter(child: _buildActions(c)),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(FleetColors c) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
    child: Row(
      children: [
        const FleetBackButton(),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Profile',
                style: TextStyle(
                  color: c.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Driver account',
                style: TextStyle(color: c.textSub, fontSize: 13),
              ),
            ],
          ),
        ),
        const ThemeToggle(),
      ],
    ),
  );

  Widget _buildAvatar(FleetColors c, UserProfile p, DriverProfile? driver) {
    final name = driver?.name.isNotEmpty == true ? driver!.name : p.name;
    final initials = AppStore.initials(name);
    final status = driver?.status ?? 'available';
    final statusLabel = status == 'on_trip'
        ? 'On Trip'
        : status == 'off_duty'
        ? 'Off Duty'
        : 'Available';
    final statusColor = status == 'on_trip'
        ? AppColors.green
        : status == 'off_duty'
        ? AppColors.red
        : AppColors.blue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4FC3F7).withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => setState(() => _editing = true),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: c.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.cardBorder, width: 2),
                    ),
                    child: Icon(
                      Icons.edit,
                      color: AppColors.orangeStart,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: TextStyle(
              color: c.text,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTruckInfo(FleetColors c, AssignedTruck? truck) {
    if (truck == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.orangeStart.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppColors.orangeGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_shipping,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assigned Truck',
                    style: TextStyle(color: c.textSub, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    truck.plate,
                    style: TextStyle(
                      color: c.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (truck.model != null)
                    Text(
                      '${truck.model} • ${truck.type ?? ''}',
                      style: TextStyle(color: c.textSub, fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCards(FleetColors c, UserProfile p, DriverProfile? driver) {
    final items = [
      _InfoItem(
        Icons.email_outlined,
        'Email',
        p.email.isNotEmpty ? p.email : '—',
      ),
      _InfoItem(Icons.phone_outlined, 'Phone', driver?.phone ?? p.phone),
      _InfoItem(Icons.badge_outlined, 'License', driver?.licenseNumber ?? '—'),
      _InfoItem(Icons.shield_outlined, 'Role', 'Driver'),
      _InfoItem(Icons.tag, 'User ID', p.uid.isNotEmpty ? p.uid : '—'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Account Info',
                style: TextStyle(
                  color: c.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _editing = true),
                child: const Text(
                  'Edit',
                  style: TextStyle(
                    color: AppColors.orangeStart,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: c.isDark ? const Color(0x0DFFFFFF) : c.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.cardBorder),
            ),
            child: Column(
              children: items.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.orangeStart.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              item.icon,
                              color: AppColors.orangeStart,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    color: c.textSub,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.value,
                                  style: TextStyle(
                                    color: c.text,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < items.length - 1)
                      Divider(
                        height: 1,
                        color: c.divider,
                        indent: 18,
                        endIndent: 18,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm(FleetColors c) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Edit Profile',
              style: TextStyle(
                color: c.text,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _editing = false),
              child: Text(
                'Cancel',
                style: TextStyle(color: c.textSub, fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Label('Full Name', c),
        GlassInput(
          hint: 'Full Name',
          icon: Icons.person_outline,
          controller: _nameCtrl,
        ),
        const SizedBox(height: 14),
        _Label('Phone', c),
        GlassInput(
          hint: 'Phone',
          icon: Icons.phone_outlined,
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 24),
        CustomButton(
          label: 'Save Changes',
          onPressed: _save,
          isLoading: _saving,
        ),
      ],
    ),
  );

  Widget _buildActions(FleetColors c) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
    child: Column(
      children: [
        _ActionTile(
          icon: Icons.notifications_outlined,
          label: 'Notifications',
          c: c,
          onTap: () {},
        ),
        _ActionTile(
          icon: Icons.help_outline,
          label: 'Help & Support',
          c: c,
          onTap: () {},
        ),
        const SizedBox(height: 8),
        _ActionTile(
          icon: Icons.logout,
          label: 'Logout',
          c: c,
          color: AppColors.red,
          onTap: _logout,
        ),
      ],
    ),
  );
}

class _InfoItem {
  final IconData icon;
  final String label, value;
  const _InfoItem(this.icon, this.label, this.value);
}

class _Label extends StatelessWidget {
  final String text;
  final FleetColors c;
  const _Label(this.text, this.c);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: TextStyle(
        color: c.textSub,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final FleetColors c;
  final Color? color;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.c,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final col = color ?? c.text;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: c.isDark ? const Color(0x0DFFFFFF) : c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color != null ? color!.withOpacity(0.2) : c.cardBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: col, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: col,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: col.withOpacity(0.4),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
