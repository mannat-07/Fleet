import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../widgets/back_button_widget.dart';
import '../widgets/glass_input.dart';
import '../widgets/custom_button.dart';
import '../widgets/theme_toggle.dart';
import 'home_screen.dart';

class OrgProfileScreen extends StatefulWidget {
  const OrgProfileScreen({super.key});

  @override
  State<OrgProfileScreen> createState() => _OrgProfileScreenState();
}

class _OrgProfileScreenState extends State<OrgProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  bool _editing = false;
  bool _saving  = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _companyCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    final p = AppStore.profile;
    _nameCtrl    = TextEditingController(text: p.name);
    _emailCtrl   = TextEditingController(text: p.email);
    _phoneCtrl   = TextEditingController(text: p.phone);
    _companyCtrl = TextEditingController(text: p.company);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _phoneCtrl.dispose(); _companyCtrl.dispose();
    super.dispose();
  }

  void _save() async {
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    AppStore.profile = AppStore.profile.copyWith(
      name:    _nameCtrl.text.trim(),
      email:   _emailCtrl.text.trim(),
      phone:   _phoneCtrl.text.trim(),
      company: _companyCtrl.text.trim(),
    );
    setState(() { _saving = false; _editing = false; });
  }

  void _logout() async {
    await AuthService.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const HomeScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
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
                  Text('Organization Profile', style: TextStyle(color: c.text, fontSize: 22, fontWeight: FontWeight.w800)),
                  Text('Account & settings', style: TextStyle(color: c.textSub, fontSize: 13)),
                ],
              ),
            ),
            const ThemeToggle(),
          ],
        ),
      );

  Widget _buildAvatar(FleetColors c, UserProfile p) {
    final initials = p.avatarInitials.isNotEmpty ? p.avatarInitials : AppStore.initials(p.name);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: const Color(0xFF4FC3F7).withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                alignment: Alignment.center,
                child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: GestureDetector(
                  onTap: () => setState(() => _editing = true),
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle, border: Border.all(color: c.cardBorder, width: 2)),
                    child: Icon(Icons.edit, color: AppColors.orangeStart, size: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(p.name.isNotEmpty ? p.name : 'Organization', style: TextStyle(color: c.text, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.blue.withOpacity(0.3)),
            ),
            child: const Text('Organization', style: TextStyle(color: AppColors.blue, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          if (p.company.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(p.company, style: TextStyle(color: c.textSub, fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCards(FleetColors c, UserProfile p) {
    final items = [
      _InfoItem(Icons.email_outlined,   'Email',        p.email.isNotEmpty   ? p.email   : '—'),
      _InfoItem(Icons.phone_outlined,   'Phone',        p.phone.isNotEmpty   ? p.phone   : '—'),
      _InfoItem(Icons.business_outlined,'Organization', p.company.isNotEmpty ? p.company : '—'),
      _InfoItem(Icons.badge_outlined,   'Role',         'Organization'),
      _InfoItem(Icons.tag,              'User ID',      p.uid.isNotEmpty     ? p.uid     : '—'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Account Info', style: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.w700)),
              GestureDetector(
                onTap: () => setState(() => _editing = true),
                child: const Text('Edit', style: TextStyle(color: AppColors.orangeStart, fontSize: 14, fontWeight: FontWeight.w600)),
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
                final i = entry.key; final item = entry.value;
                return Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Row(children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: AppColors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Icon(item.icon, color: AppColors.blue, size: 18),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item.label, style: TextStyle(color: c.textSub, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(item.value, style: TextStyle(color: c.text, fontSize: 14, fontWeight: FontWeight.w600)),
                      ])),
                    ]),
                  ),
                  if (i < items.length - 1) Divider(height: 1, color: c.divider, indent: 18, endIndent: 18),
                ]);
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
                Text('Edit Profile', style: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.w700)),
                GestureDetector(onTap: () => setState(() => _editing = false),
                    child: Text('Cancel', style: TextStyle(color: c.textSub, fontSize: 14))),
              ],
            ),
            const SizedBox(height: 16),
            _Label('Organization Name', c),
            GlassInput(hint: 'Organization name', icon: Icons.business_outlined, controller: _nameCtrl),
            const SizedBox(height: 14),
            _Label('Email', c),
            GlassInput(hint: 'Email', icon: Icons.email_outlined, controller: _emailCtrl, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 14),
            _Label('Phone', c),
            GlassInput(hint: 'Phone', icon: Icons.phone_outlined, controller: _phoneCtrl, keyboardType: TextInputType.phone),
            const SizedBox(height: 14),
            _Label('Company / Facility', c),
            GlassInput(hint: 'Company or facility name', icon: Icons.warehouse_outlined, controller: _companyCtrl),
            const SizedBox(height: 24),
            CustomButton(label: 'Save Changes', onPressed: _save, isLoading: _saving),
          ],
        ),
      );

  Widget _buildActions(FleetColors c) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
        child: Column(children: [
          _ActionTile(icon: Icons.notifications_outlined, label: 'Notifications', c: c, onTap: () {}),
          _ActionTile(icon: Icons.help_outline, label: 'Help & Support', c: c, onTap: () {}),
          const SizedBox(height: 8),
          _ActionTile(icon: Icons.logout, label: 'Logout', c: c, color: AppColors.red, onTap: _logout),
        ]),
      );
}

class _InfoItem { final IconData icon; final String label, value; const _InfoItem(this.icon, this.label, this.value); }

class _Label extends StatelessWidget {
  final String text; final FleetColors c;
  const _Label(this.text, this.c);
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: TextStyle(color: c.textSub, fontSize: 12, fontWeight: FontWeight.w600)));
}

class _ActionTile extends StatelessWidget {
  final IconData icon; final String label; final FleetColors c;
  final Color? color; final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.c, required this.onTap, this.color});

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
          border: Border.all(color: color != null ? color!.withOpacity(0.2) : c.cardBorder),
        ),
        child: Row(children: [
          Icon(icon, color: col, size: 20), const SizedBox(width: 14),
          Expanded(child: Text(label, style: TextStyle(color: col, fontSize: 14, fontWeight: FontWeight.w600))),
          Icon(Icons.arrow_forward_ios, color: col.withOpacity(0.4), size: 14),
        ]),
      ),
    );
  }
}
