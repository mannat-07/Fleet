import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../services/api_service.dart';

class TruckDetailDialog extends StatefulWidget {
  final Map<String, dynamic> truck;
  final Map<String, dynamic>? prediction;

  const TruckDetailDialog({
    super.key,
    required this.truck,
    this.prediction,
  });

  @override
  State<TruckDetailDialog> createState() => _TruckDetailDialogState();
}

class _TruckDetailDialogState extends State<TruckDetailDialog> {
  Map<String, dynamic>? _driver;
  Map<String, dynamic>? _sensor;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      // Load assigned driver
      final assignedDriverId = widget.truck['assignedDriverId'] as String?;
      if (assignedDriverId != null && assignedDriverId.isNotEmpty) {
        try {
          final drivers = await ApiService.getDrivers();
          _driver = drivers.firstWhere(
            (d) => d['driverId'] == assignedDriverId || d['uid'] == assignedDriverId,
            orElse: () => {},
          );
        } catch (_) {}
      }

      // Load sensor data
      final truckId = widget.truck['truckId'] as String?;
      if (truckId != null) {
        try {
          _sensor = await ApiService.getLatestSensorData(truckId);
        } catch (_) {}
      }
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  double _calculateStarRating(double score) {
    return (score / 100) * 5;
  }

  @override
  Widget build(BuildContext context) {
    final c = FleetTheme.of(context).colors;
    final score = widget.prediction?['predictedScore'] ?? 
                  widget.truck['predicted_score'] ?? 
                  85.0;
    final starRating = _calculateStarRating(score.toDouble());

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        decoration: BoxDecoration(
          color: c.sheetBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: c.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.orangeGradient,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.local_shipping,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.truck['plate'] ?? 'Unknown',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.truck['model'] ?? 'No model info',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ML Score & Star Rating
                    _buildSection(
                      c,
                      'Performance Rating',
                      Icons.star,
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                score.toStringAsFixed(1),
                                style: TextStyle(
                                  color: _getScoreColor(score.toDouble()),
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                '/100',
                                style: TextStyle(
                                  color: c.textSub,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildStarRating(starRating, c),
                          const SizedBox(height: 8),
                          Text(
                            _getPerformanceLabel(score.toDouble()),
                            style: TextStyle(
                              color: c.textSub,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Metrics
                    _buildSection(
                      c,
                      'Performance Metrics',
                      Icons.analytics,
                      Column(
                        children: [
                          _buildMetricRow(
                            c,
                            'Maintenance Score',
                            widget.truck['maintenance_score'] ?? 90.0,
                            Icons.build,
                          ),
                          _buildMetricRow(
                            c,
                            'Fuel Efficiency',
                            widget.truck['fuel_efficiency'] ?? 5.5,
                            Icons.local_gas_station,
                            suffix: ' km/l',
                            maxValue: 20,
                          ),
                          _buildMetricRow(
                            c,
                            'Capacity Usage',
                            widget.truck['avg_load_capacity_used'] ?? 75.0,
                            Icons.inventory,
                            suffix: '%',
                          ),
                          _buildMetricRow(
                            c,
                            'Age',
                            (widget.truck['age_years'] ?? 0).toDouble(),
                            Icons.calendar_today,
                            suffix: ' years',
                            maxValue: 20,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Stats
                    _buildSection(
                      c,
                      'Statistics',
                      Icons.bar_chart,
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              c,
                              'Total Trips',
                              '${widget.truck['total_trips'] ?? 0}',
                              Icons.route,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              c,
                              'Breakdowns',
                              '${widget.truck['breakdown_count'] ?? 0}',
                              Icons.warning_amber,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Truck Info
                    _buildSection(
                      c,
                      'Vehicle Information',
                      Icons.info,
                      Column(
                        children: [
                          if (widget.truck['type'] != null)
                            _buildInfoRow(
                              c,
                              Icons.category,
                              'Type',
                              widget.truck['type'],
                            ),
                          if (widget.truck['year'] != null)
                            _buildInfoRow(
                              c,
                              Icons.calendar_month,
                              'Year',
                              '${widget.truck['year']}',
                            ),
                          _buildInfoRow(
                            c,
                            Icons.flag,
                            'Status',
                            widget.truck['status'] ?? 'unknown',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Live Sensor Data
                    if (_sensor != null && _sensor!.isNotEmpty)
                      _buildSection(
                        c,
                        'Live Sensor Data',
                        Icons.sensors,
                        _buildSensorData(c),
                      ),

                    const SizedBox(height: 20),

                    // Assigned Driver
                    _buildSection(
                      c,
                      'Assigned Driver',
                      Icons.person,
                      _loading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : _driver == null || _driver!.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Center(
                                    child: Text(
                                      'No driver assigned',
                                      style: TextStyle(
                                        color: c.textSub,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                )
                              : _buildDriverCard(c),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    FleetColors c,
    String title,
    IconData icon,
    Widget child,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.orangeStart, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: c.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating, FleetColors c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: AppColors.amber, size: 28);
        } else if (index < rating) {
          return const Icon(Icons.star_half, color: AppColors.amber, size: 28);
        } else {
          return Icon(Icons.star_border, color: c.textSub, size: 28);
        }
      }),
    );
  }

  Widget _buildMetricRow(
    FleetColors c,
    String label,
    dynamic value,
    IconData icon, {
    String suffix = '',
    double maxValue = 100,
  }) {
    final numValue = (value is int ? value.toDouble() : value as double);
    final percentage = (numValue / maxValue).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: c.textSub, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: c.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${numValue.toStringAsFixed(numValue % 1 == 0 ? 0 : 1)}$suffix',
                style: TextStyle(
                  color: c.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: c.inputBg,
              valueColor: AlwaysStoppedAnimation(
                _getScoreColor(numValue),
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    FleetColors c,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.cardBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.orangeStart, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: c.text,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: c.textSub,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    FleetColors c,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: c.textSub, size: 18),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              color: c.textSub,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: c.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorData(FleetColors c) {
    return Column(
      children: [
        if (_sensor!['fuelLevel'] != null)
          _buildSensorRow(
            c,
            Icons.local_gas_station,
            'Fuel Level',
            '${_sensor!['fuelLevel']}%',
          ),
        if (_sensor!['temperature'] != null)
          _buildSensorRow(
            c,
            Icons.thermostat,
            'Temperature',
            '${_sensor!['temperature']}°C',
          ),
        if (_sensor!['speed'] != null)
          _buildSensorRow(
            c,
            Icons.speed,
            'Speed',
            '${_sensor!['speed']} km/h',
          ),
        if (_sensor!['loadStatus'] != null)
          _buildSensorRow(
            c,
            Icons.inventory_2,
            'Load Status',
            _sensor!['loadStatus'],
          ),
        if (_sensor!['doorStatus'] != null)
          _buildSensorRow(
            c,
            Icons.door_front_door,
            'Door Status',
            _sensor!['doorStatus'],
          ),
      ],
    );
  }

  Widget _buildSensorRow(
    FleetColors c,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: c.textSub, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: c.textSub,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: c.text,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(FleetColors c) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              _getInitials(_driver!['name'] ?? ''),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _driver!['name'] ?? 'Unknown',
                  style: TextStyle(
                    color: c.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_driver!['phone'] != null)
                  Text(
                    _driver!['phone'],
                    style: TextStyle(
                      color: c.textSub,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return AppColors.green;
    if (score >= 60) return AppColors.amber;
    return AppColors.red;
  }

  String _getPerformanceLabel(double score) {
    if (score >= 90) return 'Excellent Condition';
    if (score >= 80) return 'Very Good Condition';
    if (score >= 70) return 'Good Condition';
    if (score >= 60) return 'Fair Condition';
    return 'Needs Maintenance';
  }
}
