import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/glass_input.dart';
import '../widgets/glass_card.dart';
import '../widgets/back_button_widget.dart';
import '../widgets/theme_toggle.dart';
import '../widgets/motion.dart';
import 'dashboard_screen.dart';
import 'driver_dashboard_screen.dart';
import 'org_dashboard_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String _selectedRole = 'Fleet Owner';
  bool _loading = false;
  String? _error;

  static const _roles = ['Fleet Owner', 'Driver', 'Organization'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String _roleToFirestore(String role) {
    switch (role) {
      case 'Driver':
        return 'driver';
      case 'Organization':
        return 'organization';
      default:
        return 'owner';
    }
  }

  Future<void> _signup() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'All fields are required.');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (pass != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AuthService.signUp(
        name: name,
        email: email,
        password: pass,
        role: _roleToFirestore(_selectedRole),
      );

      if (!mounted) return;
      setState(() => _loading = false);

      Widget destination;
      if (_selectedRole == 'Driver') {
        destination = const DriverDashboardScreen();
      } else if (_selectedRole == 'Organization') {
        destination = const OrgDashboardScreen();
      } else {
        destination = const DashboardScreen();
      }

      Navigator.pushAndRemoveUntil(
        context,
        AppMotionRoute.fadeSlideScale(destination),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AuthService.friendlyError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = FleetTheme.of(context).colors;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: c.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    StaggerReveal(
                      child: Row(
                        children: [
                          const FleetBackButton(),
                          const Spacer(),
                          const ThemeToggle(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    StaggerReveal(
                      delay: const Duration(milliseconds: 80),
                      child: Text(
                        'Create\nAccount',
                        style: TextStyle(
                          color: c.text,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join FleetOS and manage your fleet',
                      style: TextStyle(color: c.textSub, fontSize: 15),
                    ),
                    const SizedBox(height: 28),

                    if (_error != null) ...[
                      _ErrorBanner(_error!),
                      const SizedBox(height: 16),
                    ],

                    StaggerReveal(
                      delay: const Duration(milliseconds: 160),
                      child: GlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GlassInput(
                              hint: 'Full Name',
                              icon: Icons.person_outline,
                              controller: _nameCtrl,
                            ),
                            const SizedBox(height: 16),
                            GlassInput(
                              hint: 'Email address',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              controller: _emailCtrl,
                            ),
                            const SizedBox(height: 16),
                            GlassInput(
                              hint: 'Password',
                              icon: Icons.lock_outline,
                              obscure: true,
                              controller: _passCtrl,
                            ),
                            const SizedBox(height: 16),
                            GlassInput(
                              hint: 'Confirm Password',
                              icon: Icons.lock_outline,
                              obscure: true,
                              controller: _confirmCtrl,
                            ),
                            const SizedBox(height: 20),

                            // ── Role selector ──────────────────────────────────
                            Text(
                              'I am a',
                              style: TextStyle(
                                color: c.textSub,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: _roles.map((role) {
                                final selected = _selectedRole == role;
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _selectedRole = role),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      margin: EdgeInsets.only(
                                        right: role != _roles.last ? 8 : 0,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: selected
                                            ? AppColors.orangeGradient
                                            : null,
                                        color: selected ? null : c.surfaceHigh,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: selected
                                              ? Colors.transparent
                                              : c.cardBorder,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          role,
                                          style: TextStyle(
                                            color: selected
                                                ? Colors.white
                                                : c.textSub,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 24),
                            CustomButton(
                              label: 'Create Account',
                              onPressed: _loading ? () {} : _signup,
                              isLoading: _loading,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),
                    StaggerReveal(
                      delay: const Duration(milliseconds: 240),
                      child: Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: RichText(
                            text: TextSpan(
                              text: 'Already have an account? ',
                              style: TextStyle(color: c.textSub, fontSize: 14),
                              children: const [
                                TextSpan(
                                  text: 'Login',
                                  style: TextStyle(
                                    color: AppColors.orangeStart,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.red.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.red.withOpacity(0.35)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: AppColors.red, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: AppColors.red, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}
