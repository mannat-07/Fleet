import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/glass_input.dart';
import '../widgets/glass_card.dart';
import '../widgets/back_button_widget.dart';
import '../widgets/theme_toggle.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'dashboard_screen.dart';
import 'driver_dashboard_screen.dart';
import 'org_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool    _loading    = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
    _fadeAnim  = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final profile = await AuthService.signIn(email: email, password: password);

      if (!mounted) return;
      setState(() => _loading = false);

      // Role-based routing
      Widget destination;
      final role = profile.role.toLowerCase();
      if (role == 'driver') {
        destination = const DriverDashboardScreen();
      } else if (role == 'organization') {
        destination = const OrgDashboardScreen();
      } else {
        destination = const DashboardScreen();
      }

      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a, __) => destination,
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
        (_) => false,
      );
    } catch (e) {
      // Catches FirebaseAuthException, TimeoutException, and anything else
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error   = AuthService.friendlyError(e);
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
          child: Stack(
            children: [
              Positioned(
                top: -60, right: -40,
                child: Container(
                  width: 200, height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      AppColors.orangeStart.withOpacity(c.isDark ? 0.2 : 0.1),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 32),
                        Row(children: [
                          const FleetBackButton(),
                          const Spacer(),
                          const ThemeToggle(),
                        ]),
                        const SizedBox(height: 40),

                        ShaderMask(
                          shaderCallback: (b) =>
                              AppColors.orangeGradient.createShader(b),
                          child: const Text('Welcome\nBack',
                              style: TextStyle(
                                  color: Color(0xFFFFFFFF),
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1)),
                        ),
                        const SizedBox(height: 8),
                        Text('Sign in to manage your fleet',
                            style: TextStyle(color: c.textSub, fontSize: 15)),
                        const SizedBox(height: 28),

                        if (_error != null) ...[
                          _ErrorBanner(_error!),
                          const SizedBox(height: 16),
                        ],

                        GlassCard(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
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
                                controller: _passwordCtrl,
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: () => Navigator.push(context,
                                      _slideRoute(const ForgotPasswordScreen())),
                                  child: const Text('Forgot Password?',
                                      style: TextStyle(
                                          color: AppColors.orangeStart,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ),
                              const SizedBox(height: 24),
                              CustomButton(
                                label: 'Login',
                                onPressed: _loading ? () {} : _login,
                                isLoading: _loading,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),
                        Center(
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                                context, _slideRoute(const SignupScreen())),
                            child: RichText(
                              text: TextSpan(
                                text: "Don't have an account? ",
                                style: TextStyle(color: c.textSub, fontSize: 14),
                                children: const [
                                  TextSpan(
                                    text: 'Create Account',
                                    style: TextStyle(
                                        color: AppColors.orangeStart,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ],
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
            ],
          ),
        ),
      ),
    );
  }

  PageRouteBuilder _slideRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (_, a, __) => page,
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 400),
      );
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
        child: Row(children: [
          const Icon(Icons.error_outline, color: AppColors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message,
                  style: const TextStyle(color: AppColors.red, fontSize: 13))),
        ]),
      );
}
