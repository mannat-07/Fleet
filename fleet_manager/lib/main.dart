import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/firebase_config.dart';
import 'utils/theme.dart';
import 'screens/home_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/driver_dashboard_screen.dart';
import 'screens/org_dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'widgets/motion.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Firebase with the web config
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const FleetManagerApp());
}

class FleetManagerApp extends StatefulWidget {
  const FleetManagerApp({super.key});

  @override
  State<FleetManagerApp> createState() => _FleetManagerAppState();
}

class _FleetManagerAppState extends State<FleetManagerApp> {
  bool _isDark = true;

  void _toggle() => setState(() => _isDark = !_isDark);

  @override
  Widget build(BuildContext context) {
    final colors = _isDark ? FleetColors.dark : FleetColors.light;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: colors.background,
        systemNavigationBarIconBrightness: _isDark
            ? Brightness.light
            : Brightness.dark,
      ),
    );

    return FleetTheme(
      colors: colors,
      toggle: _toggle,
      child: MaterialApp(
        title: 'FleetOS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(colors),
        home: const HomeScreen(),
        onGenerateRoute: (settings) {
          Widget? page;
          switch (settings.name) {
            case '/home':
              page = const HomeScreen();
              break;
            case '/dashboard':
              page = const DashboardScreen();
              break;
            case '/driver-dashboard':
              page = const DriverDashboardScreen();
              break;
            case '/org-dashboard':
              page = const OrgDashboardScreen();
              break;
            case '/login':
              page = const LoginScreen();
              break;
            case '/signup':
              page = const SignupScreen();
              break;
          }
          if (page == null) return null;
          return AppMotionRoute.fadeSlideScale(page);
        },
        routes: {
          '/home': (_) => const HomeScreen(),
          '/dashboard': (_) => const DashboardScreen(),
          '/driver-dashboard': (_) => const DriverDashboardScreen(),
          '/org-dashboard': (_) => const OrgDashboardScreen(),
        },
      ),
    );
  }
}
