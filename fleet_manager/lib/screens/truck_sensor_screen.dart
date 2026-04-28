import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/back_button_widget.dart';

// ─── ESP32 data model ─────────────────────────────────────────────────────────
class Esp32Data {
  final double weight;
  final double temperature;
  final double humidity;
  final int gas;
  final int alcohol;
  final bool beef;
  final bool alcoholDetected;
  final bool rain;
  final bool buzzer;
  final double distance;
  final double lat;
  final double lng;
  final String status;

  const Esp32Data({
    required this.weight,
    required this.temperature,
    required this.humidity,
    required this.gas,
    required this.alcohol,
    required this.beef,
    required this.alcoholDetected,
    required this.rain,
    required this.buzzer,
    required this.distance,
    required this.lat,
    required this.lng,
    required this.status,
  });

  factory Esp32Data.fromJson(Map<String, dynamic> j) => Esp32Data(
        weight: (j['weight'] as num?)?.toDouble() ?? 0,
        temperature: (j['temperature'] as num?)?.toDouble() ?? 0,
        humidity: (j['humidity'] as num?)?.toDouble() ?? 0,
        gas: (j['gas'] as num?)?.toInt() ?? 0,
        alcohol: (j['alcohol'] as num?)?.toInt() ?? 0,
        beef: j['beef'] == true,
        alcoholDetected: j['alcohol_detected'] == true,
        rain: j['rain'] == true,
        buzzer: j['buzzer'] == true,
        distance: (j['distance'] as num?)?.toDouble() ?? -1,
        lat: (j['lat'] as num?)?.toDouble() ?? 0,
        lng: (j['lng'] as num?)?.toDouble() ?? 0,
        status: j['status'] as String? ?? 'NORMAL',
      );
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class TruckSensorScreen extends StatefulWidget {
  final TruckModel truck;
  const TruckSensorScreen({super.key, required this.truck});

  @override
  State<TruckSensorScreen> createState() => _TruckSensorScreenState();
}

class _TruckSensorScreenState extends State<TruckSensorScreen>
    with SingleTickerProviderStateMixin {
  // Backend proxy endpoint — backend fetches from ESP32 on your behalf
  // since your PC is connected to the ESP32 WiFi, not the phone.
  static const String _sensorUrl = '/esp32/data';
  static const Duration _pollInterval = Duration(seconds: 2);

  Timer? _timer;
  Esp32Data? _data;
  bool _connecting = true;
  bool _connected = false;
  String? _error;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _startPolling() {
    _fetchData();
    _timer = Timer.periodic(_pollInterval, (_) => _fetchData());
  }

  Future<void> _fetchData() async {
    try {
      // Call backend proxy — backend fetches from ESP32 (PC is on ESP32 WiFi)
      final data = await ApiService.getEsp32Data();
      if (!mounted) return;
      setState(() {
        _data = Esp32Data.fromJson(data);
        _connecting = false;
        _connected = true;
        _error = null;
      });
    } on TimeoutException {
      if (!mounted) return;
      _setError(
        'Connection timed out.\n\nMake sure:\n'
        '• Your PC running the backend is\n'
        '  connected to "TruckSystem" WiFi\n'
        '• Backend server is running (npm start)',
      );
    } catch (e) {
      if (!mounted) return;
      _setError(
        'Cannot reach ESP32 sensor data.\n\n'
        'Make sure:\n'
        '• Backend server is running on your PC\n'
        '• Your PC WiFi is connected to "TruckSystem"\n'
        '• Password: 12345678',
      );
    }
  }

  void _setError(String msg) {
    setState(() {
      _connecting = false;
      _connected = false;
      _error = msg;
    });
  }

  // ─── Status helpers ──────────────────────────────────────────────────────────
  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case 'OVERLOAD':
        return AppColors.red;
      case 'TOO CLOSE':
        return AppColors.amber;
      default:
        return AppColors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = FleetTheme.of(context).colors;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: c.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(c),
              Expanded(child: _buildBody(c)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(FleetColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.backBtnBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.backBtnBorder),
              ),
              child: Icon(Icons.arrow_back_ios_new, color: c.text, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.truck.plate,
                  style: TextStyle(
                    color: c.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${widget.truck.model}  •  Live Sensors',
                  style: TextStyle(color: c.textSub, fontSize: 12),
                ),
              ],
            ),
          ),
          // Connection indicator
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (_connected ? AppColors.green : AppColors.red)
                    .withOpacity(0.1 + _pulseCtrl.value * 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (_connected ? AppColors.green : AppColors.red)
                      .withOpacity(0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _connected ? AppColors.green : AppColors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _connecting
                        ? 'Connecting…'
                        : _connected
                            ? 'Live'
                            : 'Offline',
                    style: TextStyle(
                      color: _connected ? AppColors.green : AppColors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(FleetColors c) {
    if (_connecting) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.orangeStart),
            const SizedBox(height: 20),
            Text(
              'Connecting to ESP32…',
              style: TextStyle(color: c.textSub, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Make sure you\'re connected to\n"TruckSystem" WiFi',
              style: TextStyle(color: c.textSub, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_error != null && _data == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: AppColors.red,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'ESP32 Not Reachable',
                style: TextStyle(
                  color: c.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              // WiFi instructions box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.wifi, color: AppColors.blue, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'How to connect:',
                          style: TextStyle(
                            color: c.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _Step(n: '1', text: 'Connect your PC WiFi to "TruckSystem"', c: c),
                    _Step(n: '2', text: 'Password: 12345678', c: c),
                    _Step(n: '3', text: 'Start backend: npm start', c: c),
                    _Step(n: '4', text: 'Tap Retry below', c: c),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _connecting = true;
                    _error = null;
                  });
                  _fetchData();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 36, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppColors.orangeGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Retry Connection',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final d = _data!;
    final statusColor = _statusColor(d.status);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status banner ──────────────────────────────────────────────────
          _StatusBanner(status: d.status, color: statusColor, c: c),
          const SizedBox(height: 20),

          // ── Weight ─────────────────────────────────────────────────────────
          _WeightCard(weight: d.weight, buzzer: d.buzzer, c: c),
          const SizedBox(height: 14),

          // ── 2-column grid ──────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _SensorTile(
                  icon: Icons.thermostat_outlined,
                  label: 'Temperature',
                  value: '${d.temperature.toStringAsFixed(1)}°C',
                  color: d.temperature > 40 ? AppColors.red : _orange,
                  c: c,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SensorTile(
                  icon: Icons.water_drop_outlined,
                  label: 'Humidity',
                  value: '${d.humidity.toStringAsFixed(1)}%',
                  color: AppColors.blue,
                  c: c,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SensorTile(
                  icon: Icons.air_outlined,
                  label: 'Air Quality',
                  value: '${d.gas}',
                  sublabel: d.gas > 2000 ? 'Poor' : 'Good',
                  color: d.gas > 2000 ? AppColors.red : AppColors.green,
                  c: c,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SensorTile(
                  icon: Icons.local_bar_outlined,
                  label: 'Alcohol',
                  value: '${d.alcohol}',
                  sublabel: d.alcoholDetected ? 'Detected!' : 'Clear',
                  color: d.alcoholDetected ? AppColors.red : AppColors.green,
                  c: c,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SensorTile(
                  icon: Icons.social_distance_outlined,
                  label: 'Distance',
                  value: d.distance < 0
                      ? 'N/A'
                      : '${d.distance.toStringAsFixed(1)} cm',
                  sublabel: d.distance > 0 && d.distance < 10
                      ? 'Too Close!'
                      : 'Safe',
                  color: d.distance > 0 && d.distance < 10
                      ? AppColors.amber
                      : AppColors.green,
                  c: c,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SensorTile(
                  icon: Icons.grain_outlined,
                  label: 'Rain',
                  value: d.rain ? 'Raining' : 'Dry',
                  color: d.rain ? AppColors.blue : AppColors.green,
                  c: c,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Alert flags ────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _FlagTile(
                  icon: Icons.warning_amber_rounded,
                  label: 'Beef Detected',
                  active: d.beef,
                  activeColor: AppColors.amber,
                  c: c,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FlagTile(
                  icon: Icons.notifications_active_outlined,
                  label: 'Buzzer',
                  active: d.buzzer,
                  activeColor: AppColors.red,
                  c: c,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── GPS ────────────────────────────────────────────────────────────
          _GpsCard(lat: d.lat, lng: d.lng, c: c),
        ],
      ),
    );
  }
}

// ─── Status Banner ────────────────────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  final String status;
  final Color color;
  final FleetColors c;
  const _StatusBanner({
    required this.status,
    required this.color,
    required this.c,
  });

  IconData get _icon {
    switch (status.toUpperCase()) {
      case 'OVERLOAD':
        return Icons.warning_rounded;
      case 'TOO CLOSE':
        return Icons.social_distance_outlined;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withOpacity(c.isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Status',
                  style: TextStyle(color: c.textSub, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

// ─── Weight Card ──────────────────────────────────────────────────────────────
class _WeightCard extends StatelessWidget {
  final double weight;
  final bool buzzer;
  final FleetColors c;
  const _WeightCard({
    required this.weight,
    required this.buzzer,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final isOverload = buzzer;
    final color = isOverload ? AppColors.red : AppColors.green;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.isDark ? Colors.white.withOpacity(0.05) : c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.scale_outlined, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Load Weight',
                  style: TextStyle(color: c.textSub, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '${weight.toStringAsFixed(2)} kg',
                  style: TextStyle(
                    color: c.text,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          if (isOverload)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.red.withOpacity(0.4)),
              ),
              child: const Text(
                'OVERLOAD',
                style: TextStyle(
                  color: AppColors.red,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Sensor Tile ──────────────────────────────────────────────────────────────
class _SensorTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? sublabel;
  final Color color;
  final FleetColors c;
  const _SensorTile({
    required this.icon,
    required this.label,
    required this.value,
    this.sublabel,
    required this.color,
    required this.c,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.isDark ? Colors.white.withOpacity(0.04) : c.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const Spacer(),
                if (sublabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      sublabel!,
                      style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                color: c.text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: c.textSub, fontSize: 11),
            ),
          ],
        ),
      );
}

// ─── Flag Tile ────────────────────────────────────────────────────────────────
class _FlagTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;
  final FleetColors c;
  const _FlagTile({
    required this.icon,
    required this.label,
    required this.active,
    required this.activeColor,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : c.textSub;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.isDark ? Colors.white.withOpacity(0.04) : c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active ? activeColor.withOpacity(0.35) : c.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: c.textSub,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  active ? 'YES' : 'NO',
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── GPS Card ─────────────────────────────────────────────────────────────────
class _GpsCard extends StatelessWidget {
  final double lat;
  final double lng;
  final FleetColors c;
  const _GpsCard({required this.lat, required this.lng, required this.c});

  bool get _hasLocation => lat != 0 || lng != 0;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: c.isDark ? Colors.white.withOpacity(0.04) : c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (_hasLocation ? AppColors.green : c.cardBorder)
                .withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (_hasLocation ? AppColors.green : c.textSub)
                    .withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.location_on_outlined,
                color: _hasLocation ? AppColors.green : c.textSub,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GPS Location',
                    style: TextStyle(color: c.textSub, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  _hasLocation
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lat: ${lat.toStringAsFixed(6)}',
                              style: TextStyle(
                                color: c.text,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Lng: ${lng.toStringAsFixed(6)}',
                              style: TextStyle(
                                color: c.text,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'No GPS fix yet',
                          style: TextStyle(color: c.textSub, fontSize: 13),
                        ),
                ],
              ),
            ),
            if (_hasLocation)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.green.withOpacity(0.3)),
                ),
                child: const Text(
                  'Fixed',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      );
}

// ─── Orange color helper ──────────────────────────────────────────────────────
const Color _orange = Color(0xFFFF9800);

// ─── Step widget for WiFi instructions ───────────────────────────────────────
class _Step extends StatelessWidget {
  final String n, text;
  final FleetColors c;
  const _Step({required this.n, required this.text, required this.c});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                n,
                style: const TextStyle(
                  color: AppColors.blue,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(color: c.text, fontSize: 13),
            ),
          ],
        ),
      );
}
