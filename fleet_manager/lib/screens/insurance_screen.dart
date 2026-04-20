import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../models/models.dart';
import '../widgets/status_badge.dart';
import '../widgets/back_button_widget.dart';

class InsuranceScreen extends StatefulWidget {
  const InsuranceScreen({super.key});

  @override
  State<InsuranceScreen> createState() => _InsuranceScreenState();
}

class _InsuranceScreenState extends State<InsuranceScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = FleetTheme.of(context).colors;
    final valid    = SampleData.insurance.where((i) => i.status == 'Valid').length;
    final expiring = SampleData.insurance.where((i) => i.status == 'Expiring').length;
    final expired  = SampleData.insurance.where((i) => i.status == 'Expired').length;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: c.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(title: 'Insurance', subtitle: 'Document status'),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  children: [
                    _Chip(label: 'Valid',    count: valid,    color: AppColors.green, c: c),
                    const SizedBox(width: 10),
                    _Chip(label: 'Expiring', count: expiring, color: AppColors.amber, c: c),
                    const SizedBox(width: 10),
                    _Chip(label: 'Expired',  count: expired,  color: AppColors.red,   c: c),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  itemCount: SampleData.insurance.length,
                  itemBuilder: (_, i) {
                    final delay = i * 0.12;
                    final anim = CurvedAnimation(parent: _controller, curve: Interval(delay, delay + 0.5, curve: Curves.easeOutCubic));
                    return AnimatedBuilder(
                      animation: anim,
                      builder: (_, child) => Opacity(opacity: anim.value, child: Transform.translate(offset: Offset(0, 20 * (1 - anim.value)), child: child)),
                      child: _InsuranceCard(doc: SampleData.insurance[i], c: c),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final FleetColors c;
  const _Chip({required this.label, required this.count, required this.color, required this.c});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(c.isDark ? 0.1 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text('$count', style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
            Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _InsuranceCard extends StatelessWidget {
  final InsuranceModel doc;
  final FleetColors c;
  const _InsuranceCard({required this.doc, required this.c});

  Color get _statusColor {
    switch (doc.status) {
      case 'Valid':    return AppColors.green;
      case 'Expiring': return AppColors.amber;
      case 'Expired':  return AppColors.red;
      default:         return AppColors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.isDark ? Colors.white.withOpacity(0.05) : c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _statusColor.withOpacity(0.2)),
        boxShadow: c.isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: _statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.shield_outlined, color: _statusColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.truckPlate, style: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                const SizedBox(height: 3),
                Text(doc.provider, style: TextStyle(color: c.textSub, fontSize: 13)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, color: c.textSub, size: 12),
                    const SizedBox(width: 4),
                    Text('Expires: ${doc.expiryDate}', style: TextStyle(color: c.textSub, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          StatusBadge(status: doc.status),
        ],
      ),
    );
  }
}
