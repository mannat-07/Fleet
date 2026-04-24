import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/status_badge.dart';
import '../widgets/back_button_widget.dart';

class InsuranceScreen extends StatefulWidget {
  const InsuranceScreen({super.key});

  @override
  State<InsuranceScreen> createState() => _InsuranceScreenState();
}

class _InsuranceScreenState extends State<InsuranceScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _loadInsurance();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadInsurance() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Insurance data is derived from truck records
      final trucks = await ApiService.getTrucks();
      if (!mounted) return;
      // Map trucks that have insurance fields
      AppStore.insurance = trucks
          .where(
            (t) => t['insuranceStatus'] != null || t['insuranceExpiry'] != null,
          )
          .map(InsuranceModel.fromJson)
          .toList();
      // Also update trucks store
      AppStore.trucks = trucks.map(TruckModel.fromJson).toList();
      setState(() => _loading = false);
      _controller.reset();
      _controller.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = FleetTheme.of(context).colors;
    final valid = AppStore.insurance.where((i) => i.status == 'Valid').length;
    final expiring = AppStore.insurance
        .where((i) => i.status == 'Expiring')
        .length;
    final expired = AppStore.insurance
        .where((i) => i.status == 'Expired')
        .length;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: c.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(title: 'Insurance', subtitle: 'Document status'),
              if (!_loading && _error == null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(
                    children: [
                      _Chip(
                        label: 'Valid',
                        count: valid,
                        color: AppColors.green,
                        c: c,
                      ),
                      const SizedBox(width: 10),
                      _Chip(
                        label: 'Expiring',
                        count: expiring,
                        color: AppColors.amber,
                        c: c,
                      ),
                      const SizedBox(width: 10),
                      _Chip(
                        label: 'Expired',
                        count: expired,
                        color: AppColors.red,
                        c: c,
                      ),
                    ],
                  ),
                ),
              Expanded(child: _buildBody(c)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(FleetColors c) {
    if (_loading)
      return const Center(
        child: CircularProgressIndicator(color: AppColors.orangeStart),
      );
    if (_error != null)
      return _ErrorState(error: _error!, onRetry: _loadInsurance, c: c);
    if (AppStore.insurance.isEmpty)
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_outlined, color: c.textSub, size: 56),
            const SizedBox(height: 16),
            Text(
              'No insurance records found',
              style: TextStyle(color: c.textSub, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              'Add insurance fields to your trucks',
              style: TextStyle(color: c.textSub, fontSize: 13),
            ),
          ],
        ),
      );

    return RefreshIndicator(
      color: AppColors.orangeStart,
      backgroundColor: c.surface,
      onRefresh: _loadInsurance,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        itemCount: AppStore.insurance.length,
        itemBuilder: (_, i) {
          final delay = i * 0.12;
          final anim = CurvedAnimation(
            parent: _controller,
            curve: Interval(delay, delay + 0.5, curve: Curves.easeOutCubic),
          );
          return AnimatedBuilder(
            animation: anim,
            builder: (_, child) => Opacity(
              opacity: anim.value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - anim.value)),
                child: child,
              ),
            ),
            child: _InsuranceCard(doc: AppStore.insurance[i], c: c),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final FleetColors c;
  const _Chip({
    required this.label,
    required this.count,
    required this.color,
    required this.c,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(c.isDark ? 0.1 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: color.withOpacity(0.8), fontSize: 11),
          ),
        ],
      ),
    ),
  );
}

class _InsuranceCard extends StatelessWidget {
  final InsuranceModel doc;
  final FleetColors c;
  const _InsuranceCard({required this.doc, required this.c});

  Color get _statusColor {
    switch (doc.status) {
      case 'Valid':
        return AppColors.green;
      case 'Expiring':
        return AppColors.amber;
      case 'Expired':
        return AppColors.red;
      default:
        return AppColors.green;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: c.isDark ? Colors.white.withOpacity(0.05) : c.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _statusColor.withOpacity(0.2)),
    ),
    child: Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: _statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.shield_outlined, color: _statusColor, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doc.truckPlate,
                style: TextStyle(
                  color: c.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              if (doc.provider.isNotEmpty)
                Text(
                  doc.provider,
                  style: TextStyle(color: c.textSub, fontSize: 13),
                ),
              if (doc.expiryDate.isNotEmpty) ...[
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: c.textSub,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Expires: ${doc.expiryDate}',
                      style: TextStyle(color: c.textSub, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        StatusBadge(status: doc.status),
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final FleetColors c;
  const _ErrorState({
    required this.error,
    required this.onRetry,
    required this.c,
  });
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_outlined, color: c.textSub, size: 48),
          const SizedBox(height: 16),
          Text(
            'Could not load insurance',
            style: TextStyle(
              color: c.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: c.textSub, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppColors.orangeGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
