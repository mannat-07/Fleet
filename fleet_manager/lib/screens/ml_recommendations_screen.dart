import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/motion.dart';
import '../utils/theme.dart';

class MLRecommendationsScreen extends StatefulWidget {
  const MLRecommendationsScreen({super.key});

  @override
  State<MLRecommendationsScreen> createState() => _MLRecommendationsScreenState();
}

class _MLRecommendationsScreenState extends State<MLRecommendationsScreen> {
  bool _isLoadingDrivers = true;
  bool _isLoadingTrucks = true;
  List<Map<String, dynamic>> _driverRecommendations = [];
  List<Map<String, dynamic>> _truckRecommendations = [];
  String? _errorDrivers;
  String? _errorTrucks;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoadingDrivers = true;
      _isLoadingTrucks = true;
      _errorDrivers = null;
      _errorTrucks = null;
    });

    // Load driver recommendations
    try {
      final drivers = await ApiService.getDriverRecommendations();
      if (mounted) {
        setState(() {
          _driverRecommendations = drivers;
          _isLoadingDrivers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorDrivers = e.toString();
          _isLoadingDrivers = false;
        });
      }
    }

    // Load truck recommendations
    try {
      final trucks = await ApiService.getTruckRecommendations();
      if (mounted) {
        setState(() {
          _truckRecommendations = trucks;
          _isLoadingTrucks = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorTrucks = e.toString();
          _isLoadingTrucks = false;
        });
      }
    }
  }

  Future<void> _trainDriverModel() async {
    try {
      await ApiService.trainDriverModel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driver model training initiated')),
        );
        _loadRecommendations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Training failed: $e')),
        );
      }
    }
  }

  Future<void> _trainTruckModel() async {
    try {
      await ApiService.trainTruckModel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Truck model training initiated')),
        );
        _loadRecommendations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Training failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = FleetTheme.of(context).colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ML Recommendations',
          style: TextStyle(color: colors.text, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: colors.text),
            onPressed: _loadRecommendations,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRecommendations,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDriverSection(colors),
              const SizedBox(height: 24),
              _buildTruckSection(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriverSection(FleetColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Top Drivers',
              style: TextStyle(
                color: colors.text,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: _trainDriverModel,
              icon: Icon(Icons.model_training, size: 18, color: AppColors.orangeStart),
              label: Text('Train Model', style: TextStyle(color: AppColors.orangeStart)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingDrivers)
          const Center(child: CircularProgressIndicator())
        else if (_errorDrivers != null)
          _buildErrorCard(colors, _errorDrivers!)
        else if (_driverRecommendations.isEmpty)
          _buildEmptyCard(colors, 'No driver data available')
        else
          ..._driverRecommendations.map((driver) => _buildDriverCard(colors, driver)),
      ],
    );
  }

  Widget _buildTruckSection(FleetColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Top Trucks',
              style: TextStyle(
                color: colors.text,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: _trainTruckModel,
              icon: Icon(Icons.model_training, size: 18, color: AppColors.orangeStart),
              label: Text('Train Model', style: TextStyle(color: AppColors.orangeStart)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingTrucks)
          const Center(child: CircularProgressIndicator())
        else if (_errorTrucks != null)
          _buildErrorCard(colors, _errorTrucks!)
        else if (_truckRecommendations.isEmpty)
          _buildEmptyCard(colors, 'No truck data available')
        else
          ..._truckRecommendations.map((truck) => _buildTruckCard(colors, truck)),
      ],
    );
  }

  Widget _buildDriverCard(FleetColors colors, Map<String, dynamic> driver) {
    final score = driver['predictedScore'] ?? 0.0;
    final name = driver['name'] ?? 'Unknown';
    final email = driver['email'] ?? '';
    final status = driver['status'] ?? 'unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _getScoreColor(score, colors).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                score.toStringAsFixed(0),
                style: TextStyle(
                  color: _getScoreColor(score, colors),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(color: colors.textSub, fontSize: 13),
                ),
                const SizedBox(height: 4),
                _buildStatusBadge(colors, status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTruckCard(FleetColors colors, Map<String, dynamic> truck) {
    final score = truck['predictedScore'] ?? 0.0;
    final plate = truck['plate'] ?? 'Unknown';
    final model = truck['model'] ?? '';
    final status = truck['status'] ?? 'unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _getScoreColor(score, colors).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                score.toStringAsFixed(0),
                style: TextStyle(
                  color: _getScoreColor(score, colors),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plate,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (model.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    model,
                    style: TextStyle(color: colors.textSub, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 4),
                _buildStatusBadge(colors, status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(FleetColors colors, String status) {
    Color badgeColor;
    switch (status.toLowerCase()) {
      case 'available':
        badgeColor = Colors.green;
        break;
      case 'on_trip':
        badgeColor = Colors.blue;
        break;
      case 'idle':
        badgeColor = Colors.orange;
        break;
      case 'maintenance':
        badgeColor = Colors.red;
        break;
      default:
        badgeColor = colors.textSub;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: badgeColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildErrorCard(FleetColors colors, String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(FleetColors colors, String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: colors.textSub, fontSize: 14),
        ),
      ),
    );
  }

  Color _getScoreColor(double score, FleetColors colors) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}
