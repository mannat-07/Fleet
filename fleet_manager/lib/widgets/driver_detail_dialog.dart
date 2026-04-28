import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../services/api_service.dart';

class DriverDetailDialog extends StatefulWidget {
  final Map<String, dynamic> driver;
  final Map<String, dynamic>? prediction;

  const DriverDetailDialog({
    super.key,
    required this.driver,
    this.prediction,
  });

  @override
  State<DriverDetailDialog> createState() => _DriverDetailDialogState();
}

class _DriverDetailDialogState extends State<DriverDetailDialog> {
  Map<String, dynamic>? _truck;
  Map<String, dynamic>? _sensor;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTruckDetails();
  }

  Future<void> _loadTruckDetails() async {
    final assignedTruckId = widget.driver['assignedTruckId'] as String?;
    if (assignedTruckId == null || assignedTruckId.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    try {
      final trucks = await ApiService.getTrucks();
      _truck = trucks.firstWhere(
        (t) => t['truckId'] == assignedTruckId,
        orElse: () => {},
      );

      if (_truck != null && _truck!.isNotEmpty) {
        try {
          _sensor = await ApiService.getLatestSensorData(assignedTruckId);
        } catch (_) {}
      }
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _showAssignTruckDialog(FleetColors c) async {
    try {
      // Fetch idle trucks
      final idleTrucks = await ApiService.getIdleTrucks();
      
      if (!mounted) return;
      
      if (idleTrucks.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No idle trucks available')),
        );
        return;
      }

      // Show truck selection dialog
      final selectedTruck = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: c.sheetBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Select Truck',
            style: TextStyle(color: c.text, fontWeight: FontWeight.w800),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: idleTrucks.length,
              itemBuilder: (context, index) {
                final truck = idleTrucks[index];
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.orangeStart.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_shipping,
                      color: AppColors.orangeStart,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    truck['plate'] ?? 'Unknown',
                    style: TextStyle(
                      color: c.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    truck['model'] ?? '',
                    style: TextStyle(color: c.textSub, fontSize: 12),
                  ),
                  onTap: () => Navigator.pop(context, truck),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: c.textSub)),
            ),
          ],
        ),
      );

      if (selectedTruck == null || !mounted) return;

      // Assign the truck
      setState(() => _loading = true);
      
      try {
        await ApiService.assignDriver(
          widget.driver['driverId'],
          selectedTruck['truckId'],
        );
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Assigned ${selectedTruck['plate']} to ${widget.driver['name']}',
            ),
          ),
        );
        
        // Reload truck details
        await _loadTruckDetails();
        
        // Close the dialog to refresh the parent screen
        if (mounted) Navigator.pop(context, true);
        
      } catch (e) {
        if (!mounted) return;
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to assign truck: $e')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load trucks: $e')),
      );
    }
  }

  double _calculateStarRating(double score) {
    // Convert 0-100 score to 0-5 stars
    return (score / 100) * 5;
  }

  @override
  Widget build(BuildContext context) {
    final c = FleetTheme.of(context).colors;
    final score = widget.prediction?['predictedScore'] ?? 
                  widget.driver['predicted_score'] ?? 
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
                ),
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
                    child: Text(
                      _getInitials(widget.driver['name'] ?? ''),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.driver['name'] ?? 'Unknown',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.driver['email'] ?? '',
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
                            'Safety Score',
                            widget.driver['safety_score'] ?? 85.0,
                            Icons.shield,
                          ),
                          _buildMetricRow(
                            c,
                            'On-Time Delivery',
                            widget.driver['on_time_delivery_rate'] ?? 80.0,
                            Icons.schedule,
                          ),
                          _buildMetricRow(
                            c,
                            'Fuel Efficiency',
                            widget.driver['fuel_efficiency'] ?? 5.5,
                            Icons.local_gas_station,
                            suffix: ' km/l',
                            maxValue: 20,
                          ),
                          _buildMetricRow(
                            c,
                            'Experience',
                            (widget.driver['experience_years'] ?? 0).toDouble(),
                            Icons.work,
                            suffix: ' years',
                            maxValue: 30,
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
                              'Trips',
                              '${widget.driver['trips_completed'] ?? 0}',
                              Icons.local_shipping,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              c,
                              'Alerts',
                              '${widget.driver['alert_count'] ?? 0}',
                              Icons.warning_amber,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Contact Info
                    _buildSection(
                      c,
                      'Contact Information',
                      Icons.contact_phone,
                      Column(
                        children: [
                          if (widget.driver['phone'] != null &&
                              (widget.driver['phone'] as String).isNotEmpty)
                            _buildInfoRow(
                              c,
                              Icons.phone,
                              'Phone',
                              widget.driver['phone'],
                            ),
                          if (widget.driver['licenseNumber'] != null &&
                              (widget.driver['licenseNumber'] as String)
                                  .isNotEmpty)
                            _buildInfoRow(
                              c,
                              Icons.badge,
                              'License',
                              widget.driver['licenseNumber'],
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Assigned Truck
                    _buildSection(
                      c,
                      'Assigned Truck',
                      Icons.local_shipping,
                      _loading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : _truck == null || _truck!.isEmpty
                              ? Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Center(
                                        child: Text(
                                          'No truck assigned',
                                          style: TextStyle(
                                            color: c.textSub,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _showAssignTruckDialog(c),
                                        icon: const Icon(Icons.add_circle_outline, size: 18),
                                        label: const Text('Assign Truck'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.blue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : _buildTruckCard(c),
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
              Icon(icon, color: AppColors.blue, size: 20),
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
          Icon(icon, color: AppColors.blue, size: 24),
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

  Widget _buildTruckCard(FleetColors c) {
    final status = _truck!['status'] ?? 'unknown';
    final statusColor = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.orangeStart.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_shipping,
                  color: AppColors.orangeStart,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _truck!['plate'] ?? 'Unknown',
                      style: TextStyle(
                        color: c.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_truck!['model'] != null)
                      Text(
                        _truck!['model'],
                        style: TextStyle(
                          color: c.textSub,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (_sensor != null) ...[
            const SizedBox(height: 12),
            Divider(color: c.divider, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                if (_sensor!['fuelLevel'] != null)
                  Expanded(
                    child: _buildSensorItem(
                      c,
                      Icons.local_gas_station,
                      'Fuel',
                      '${_sensor!['fuelLevel']}%',
                    ),
                  ),
                if (_sensor!['temperature'] != null)
                  Expanded(
                    child: _buildSensorItem(
                      c,
                      Icons.thermostat,
                      'Temp',
                      '${_sensor!['temperature']}°C',
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSensorItem(
    FleetColors c,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: c.textSub, size: 14),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(color: c.textSub, fontSize: 11),
        ),
        Text(
          value,
          style: TextStyle(
            color: c.text,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'on_trip':
        return AppColors.green;
      case 'idle':
        return AppColors.amber;
      case 'maintenance':
        return AppColors.red;
      default:
        return Colors.grey;
    }
  }

  String _getPerformanceLabel(double score) {
    if (score >= 90) return 'Excellent Performance';
    if (score >= 80) return 'Very Good Performance';
    if (score >= 70) return 'Good Performance';
    if (score >= 60) return 'Average Performance';
    return 'Needs Improvement';
  }
}
