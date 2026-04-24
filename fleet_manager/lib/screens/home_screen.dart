import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/theme_toggle.dart';
import '../widgets/motion.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _glowController;
  late AnimationController _truckController;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _truckAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _truckController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _glowAnim = Tween<double>(begin: 0.3, end: 0.7).animate(_glowController);
    _truckAnim = Tween<double>(begin: 0, end: 1).animate(_truckController);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _glowController.dispose();
    _truckController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ft = FleetTheme.of(context);
    final c = ft.colors;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: c.backgroundGradient),
        child: SafeArea(
          child: Stack(
            children: [
              // Glow blobs
              AnimatedBuilder(
                animation: _glowAnim,
                builder: (_, __) => Positioned(
                  top: -80,
                  left: -60,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.orangeStart.withOpacity(
                            _glowAnim.value * (c.isDark ? 0.35 : 0.18),
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _glowAnim,
                builder: (_, __) => Positioned(
                  bottom: 100,
                  right: -80,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.orangeEnd.withOpacity(
                            _glowAnim.value * (c.isDark ? 0.25 : 0.12),
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),

                    // Brand row with theme toggle
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: AppColors.orangeGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.local_shipping,
                              color: Color(0xFFFFFFFF),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'FleetOS',
                            style: TextStyle(
                              color: c.text,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),
                          const ThemeToggle(width: 64, height: 32),
                        ],
                      ),
                    ),

                    const Spacer(),

                    Center(
                      child: AnimatedBuilder(
                        animation: _truckAnim,
                        builder: (_, __) => _TruckIllustration(
                          progress: _truckAnim.value,
                          isDark: c.isDark,
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    AnimatedBuilder(
                      animation: _fadeAnim,
                      builder: (_, child) => Opacity(
                        opacity: _fadeAnim.value,
                        child: Transform.translate(
                          offset: Offset(0, _slideAnim.value),
                          child: child,
                        ),
                      ),
                      child: Text(
                        'Smart Fleet\nManagement',
                        style: TextStyle(
                          color: c.text,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    AnimatedBuilder(
                      animation: _fadeAnim,
                      builder: (_, child) => Opacity(
                        opacity: _fadeAnim.value,
                        child: Transform.translate(
                          offset: Offset(0, _slideAnim.value * 1.2),
                          child: child,
                        ),
                      ),
                      child: Text(
                        'Track trucks, drivers, and performance\nin real-time with IoT precision.',
                        style: TextStyle(
                          color: c.textSub,
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    AnimatedBuilder(
                      animation: _fadeAnim,
                      builder: (_, child) =>
                          Opacity(opacity: _fadeAnim.value, child: child),
                      child: CustomButton(
                        label: 'Get Started',
                        onPressed: () => Navigator.push(
                          context,
                          AppMotionRoute.fadeSlideScale(const LoginScreen()),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Truck illustration ──────────────────────────────────────────────────────
class _TruckIllustration extends StatelessWidget {
  final double progress;
  final bool isDark;
  const _TruckIllustration({required this.progress, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 160,
      child: CustomPaint(
        painter: _TruckPainter(progress: progress, isDark: isDark),
      ),
    );
  }
}

class _TruckPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  _TruckPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final bodyColor = isDark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFE8ECF4);
    final cabColor = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFCDD3E8);
    final strokeClr = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.06);

    final orangePaint = Paint()
      ..color = AppColors.orangeStart
      ..style = PaintingStyle.fill;
    final darkPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;
    final greyPaint = Paint()
      ..color = cabColor
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = AppColors.orangeStart.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final glowPaint = Paint()
      ..color = AppColors.orangeStart.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final cx = size.width / 2;
    final cy = size.height / 2;

    for (int i = 0; i < 5; i++) {
      final lp = (progress + i * 0.2) % 1.0;
      final x = cx - 80 - lp * 60;
      final y = cy + 20 + i * 8.0;
      canvas.drawLine(
        Offset(x, y),
        Offset(x + 20.0 + i * 8, y),
        linePaint
          ..color = AppColors.orangeStart.withOpacity(0.15 + (1 - lp) * 0.2),
      );
    }

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 10, cy + 42), width: 160, height: 18),
      glowPaint,
    );

    final trailerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - 100, cy - 28, 130, 60),
      const Radius.circular(6),
    );
    canvas.drawRRect(trailerRect, darkPaint);
    canvas.drawRRect(
      trailerRect,
      Paint()
        ..color = strokeClr
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawRect(
      Rect.fromLTWH(cx - 100, cy + 18, 130, 4),
      orangePaint..color = AppColors.orangeStart.withOpacity(0.6),
    );

    final cabRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx + 30, cy - 20, 70, 52),
      const Radius.circular(8),
    );
    canvas.drawRRect(cabRect, greyPaint);

    final cabTopPath = Path()
      ..moveTo(cx + 38, cy - 20)
      ..lineTo(cx + 95, cy - 20)
      ..lineTo(cx + 100, cy - 5)
      ..lineTo(cx + 30, cy - 5)
      ..close();
    canvas.drawPath(cabTopPath, darkPaint);

    final windshieldPath = Path()
      ..moveTo(cx + 42, cy - 18)
      ..lineTo(cx + 90, cy - 18)
      ..lineTo(cx + 94, cy - 7)
      ..lineTo(cx + 34, cy - 7)
      ..close();
    canvas.drawPath(
      windshieldPath,
      Paint()
        ..color = AppColors.orangeStart.withOpacity(0.15)
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      Offset(cx + 97, cy + 10),
      8,
      Paint()
        ..color = AppColors.orangeStart.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(
      Offset(cx + 97, cy + 10),
      4,
      orangePaint..color = AppColors.orangeStart.withOpacity(0.8),
    );

    for (final wx in [cx - 60, cx - 20, cx + 50, cx + 80]) {
      canvas.drawCircle(
        Offset(wx, cy + 38),
        14,
        Paint()
          ..color = Colors.black.withOpacity(0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(Offset(wx, cy + 36), 13, darkPaint);
      canvas.drawCircle(
        Offset(wx, cy + 36),
        13,
        Paint()
          ..color = strokeClr
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      canvas.drawCircle(Offset(wx, cy + 36), 5, greyPaint);
      canvas.drawCircle(
        Offset(wx, cy + 36),
        5,
        Paint()
          ..color = AppColors.orangeStart.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      for (int s = 0; s < 4; s++) {
        final angle = (progress * 2 * math.pi) + (s * math.pi / 2);
        canvas.drawLine(
          Offset(wx + math.cos(angle) * 2, cy + 36 + math.sin(angle) * 2),
          Offset(wx + math.cos(angle) * 9, cy + 36 + math.sin(angle) * 9),
          Paint()
            ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.25)
            ..strokeWidth = 1.2,
        );
      }
    }

    for (int d = 0; d < 3; d++) {
      final dp = (progress + d * 0.33) % 1.0;
      final op = math.sin(dp * math.pi).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(cx + 60 + d * 10.0, cy - 38),
        3,
        Paint()..color = AppColors.orangeStart.withOpacity(op * 0.8),
      );
    }
    final sp = Paint()
      ..color = AppColors.orangeStart.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx + 65, cy - 30), width: 20, height: 20),
      -math.pi * 0.8,
      -math.pi * 0.4,
      false,
      sp,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx + 65, cy - 30), width: 32, height: 32),
      -math.pi * 0.8,
      -math.pi * 0.4,
      false,
      sp..color = AppColors.orangeStart.withOpacity(0.15),
    );
  }

  @override
  bool shouldRepaint(_TruckPainter old) =>
      old.progress != progress || old.isDark != isDark;
}
