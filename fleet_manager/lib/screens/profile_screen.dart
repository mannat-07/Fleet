import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../widgets/back_button_widget.dart';
import '../widgets/glass_input.dart';
import '../widgets/custom_button.dart';
import '../widgets/theme_toggle.dart';
import '../widgets/motion.dart';
import 'home_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  bool _editing = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _companyCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _initControllers();
  }

  void _initControllers() {
    final p = AppStore.profile;
    _nameCtrl = TextEditingController(text: p.name);
    _emailCtrl = TextEditingController(text: p.email);
    _phoneCtrl = TextEditingController(text: p.phone);
    _companyCtrl = TextEditingController(text: p.company);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _companyCtrl.dispose();
    super.dispose();
  }

  void _save() async {
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    AppStore.profile = AppStore.profile.copyWith(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      company: _companyCtrl.text.trim(),
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

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: c.backgroundGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(c)),
                SliverToBoxAdapter(child: _buildAvatar(c, p)),
                SliverToBoxAdapter(child: _buildStats(c)),
                SliverToBoxAdapter(
                  child: _editing ? _buildEditForm(c) : _buildInfoCards(c, p),
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

  Widget _buildHeader(FleetColors c) {
    return Padding(
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
                  'Profile',
                  style: TextStyle(
                    color: c.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Account & settings',
                  style: TextStyle(color: c.textSub, fontSize: 13),
                ),
              ],
            ),
          ),
          const ThemeToggle(),
        ],
      ),
    );
  }

  Widget _buildAvatar(FleetColors c, UserProfile p) {
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
                  gradient: AppColors.orangeGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.orangeStart.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  p.avatarInitials,
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
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
            p.name,
            style: TextStyle(
              color: c.text,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.orangeStart.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.orangeStart.withOpacity(0.3)),
            ),
            child: Text(
              p.role,
              style: const TextStyle(
                color: AppColors.orangeStart,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(p.company, style: TextStyle(color: c.textSub, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildStats(FleetColors c) {
    // Stats come from AppStore which is populated by API calls in sub-screens
    final truckCount = AppStore.trucks.length;
    final driverCount = AppStore.drivers.length;
    final activeCount = AppStore.trucks
        .where(
          (t) =>
              t.status == 'Active' ||
              t.status == 'active' ||
              t.status == 'On Trip' ||
              t.status == 'on_trip',
        )
        .length;

    final stats = [
      _Stat(
        'Trucks',
        '$truckCount',
        Icons.local_shipping,
        AppColors.orangeStart,
      ),
      _Stat('Drivers', '$driverCount', Icons.people, AppColors.blue),
      _Stat(
        'Active',
        '$activeCount',
        Icons.check_circle_outline,
        AppColors.green,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Row(
        children: stats
            .map(
              (s) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: s == stats.last ? 0 : 10),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: c.isDark ? const Color(0x0DFFFFFF) : c.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.cardBorder),
                    boxShadow: c.isDark
                        ? []
                        : [
                            BoxShadow(
                              color: const Color(0x08000000),
                              blurRadius: 8,
                            ),
                          ],
                  ),
                  child: Column(
                    children: [
                      Icon(s.icon, color: s.color, size: 22),
                      const SizedBox(height: 6),
                      CountUpText(
                        value: int.tryParse(s.value) ?? 0,
                        style: TextStyle(
                          color: c.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        s.label,
                        style: TextStyle(color: c.textSub, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildInfoCards(FleetColors c, UserProfile p) {
    final items = [
      _InfoItem(Icons.email_outlined, 'Email', p.email),
      _InfoItem(Icons.phone_outlined, 'Phone', p.phone),
      _InfoItem(Icons.business_outlined, 'Company', p.company),
      _InfoItem(Icons.badge_outlined, 'Role', p.role),
      _InfoItem(Icons.tag, 'User ID', p.uid),
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
                child: Text(
                  'Edit',
                  style: const TextStyle(
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
              boxShadow: c.isDark
                  ? []
                  : [BoxShadow(color: const Color(0x08000000), blurRadius: 10)],
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

  Widget _buildEditForm(FleetColors c) {
    return Padding(
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
          _Label('Email', c),
          GlassInput(
            hint: 'Email',
            icon: Icons.email_outlined,
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          _Label('Phone', c),
          GlassInput(
            hint: 'Phone',
            icon: Icons.phone_outlined,
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          _Label('Company', c),
          GlassInput(
            hint: 'Company',
            icon: Icons.business_outlined,
            controller: _companyCtrl,
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
  }

  Widget _buildActions(FleetColors c) {
    return Padding(
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
            icon: Icons.security_outlined,
            label: 'Security & Password',
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
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
class _Stat {
  final String label, value;
  final IconData icon;
  final Color color;
  const _Stat(this.label, this.value, this.icon, this.color);
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
          boxShadow: c.isDark
              ? []
              : [BoxShadow(color: const Color(0x08000000), blurRadius: 8)],
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
