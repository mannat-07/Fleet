import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/firebase_config.dart';
import 'utils/theme.dart';
import 'screens/home_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/driver_dashboard_screen.dart';
import 'screens/org_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Firebase with the web config
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor:                   Colors.transparent,
      statusBarIconBrightness:          _isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor:         colors.background,
      systemNavigationBarIconBrightness: _isDark ? Brightness.light : Brightness.dark,
    ));

    return FleetTheme(
      colors: colors,
      toggle: _toggle,
      child: MaterialApp(
        title: 'FleetOS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(colors),
        home: const HomeScreen(),
        routes: {
          '/home':             (_) => const HomeScreen(),
          '/dashboard':        (_) => const DashboardScreen(),
          '/driver-dashboard': (_) => const DriverDashboardScreen(),
          '/org-dashboard':    (_) => const OrgDashboardScreen(),
        },
      ),
    );
  }
}
