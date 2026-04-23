import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/back_button_widget.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _chartController;
  late Animation<double> _fadeAnim;
  late Animation<double> _chartAnim;
  int _tab = 0; // 0 = weekly, 1 = monthly

  Map<String, dynamic>? _earningsData;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fadeController  = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    _chartController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();
    _fadeAnim  = CurvedAnimation(parent: _fadeController,  curve: Curves.easeOut);
    _chartAnim = CurvedAnimation(parent: _chartController, curve: Curves.easeOutCubic);
    _loadEarnings();
  }

  @override
  void dispose() { _fadeController.dispose(); _chartController.dispose(); super.dispose(); }

  Future<void> _loadEarnings() async {
    setState(() { _loading = true; _error = null; });
    try {
      final period = _tab == 0 ? 'weekly' : 'monthly';
      final data = await ApiService.getEarnings(period: period);
      if (!mounted) return;
      setState(() { _earningsData = data; _loading = false; });
      _chartController.reset();
      _chartController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  void _switchTab(int t) {
    setState(() => _tab = t);
    _loadEarnings();
  }

  List<double> get _chartValues {
    final chartData = _earningsData?['chartData'] as List? ?? [];
    return chartData.map((e) => ((e as Map)['amount'] as num?)?.toDouble() ?? 0.0).toList();
  }

  List<String> get _chartLabels {
    final chartData = _earningsData?['chartData'] as List? ?? [];
    return chartData.map((e) {
      final date = (e as Map)['date'] as String? ?? '';
      if (date.length >= 10) return date.substring(5, 10); // MM-DD
      return date;
    }).toList();
  }

  double get _total => (_earningsData?['total'] as num?)?.toDouble() ?? 0.0;
  int get _recordCount => (_earningsData?['records'] as int?) ?? 0;

  @override
  Widget build(BuildContext context) {
    final c = FleetTheme.of(context).colors;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: c.backgroundGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: ScreenHeader(title: 'Earnings', subtitle: 'Revenue analytics')),
                SliverToBoxAdapter(child: _buildTotalCard(c)),
                SliverToBoxAdapter(child: _buildTabBar(c)),
                if (_loading)
                  const SliverToBoxAdapter(child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator(color: AppColors.orangeStart)),
                  ))
                else if (_error != null)
                  SliverToBoxAdapter(child: _buildError(c))
                else ...[
                  SliverToBoxAdapter(child: _buildChart(c)),
                  SliverToBoxAdapter(child: _buildStats(c)),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalCard(FleetColors c) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: c.isDark
                ? const LinearGradient(colors: [Color(0xFF1E1E1E), Color(0xFF2A1A0E)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight)
                : LinearGradient(colors: [c.surface, const Color(0xFFFFF3EE)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.orangeStart.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Earnings', style: TextStyle(color: c.textSub, fontSize: 13)),
                    const SizedBox(height: 6),
                    _loading
                        ? Container(width: 100, height: 36,
                            decoration: BoxDecoration(color: c.surfaceHigh, borderRadius: BorderRadius.circular(8)))
                        : Text(
                            _total > 0 ? '₹${(_total / 100000).toStringAsFixed(2)}L' : '₹0',
                            style: TextStyle(color: c.text, fontSize: 36, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text('${_tab == 0 ? 'Weekly' : 'Monthly'} • $_recordCount transactions',
                        style: TextStyle(color: c.textSub, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(gradient: AppColors.orangeGradient, borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.payments, color: Colors.white, size: 28),
              ),
            ],
          ),
        ),
      );

  Widget _buildTabBar(FleetColors c) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: c.isDark ? Colors.white.withOpacity(0.05) : c.surfaceHigh,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.cardBorder),
          ),
          child: Row(children: [
            _TabBtn(label: 'Weekly',  selected: _tab == 0, onTap: () => _switchTab(0)),
            _TabBtn(label: 'Monthly', selected: _tab == 1, onTap: () => _switchTab(1)),
          ]),
        ),
      );

  Widget _buildChart(FleetColors c) {
    final values = _chartValues;
    final labels = _chartLabels;
    if (values.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            color: c.isDark ? Colors.white.withOpacity(0.04) : c.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.cardBorder),
          ),
          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.bar_chart, color: c.textSub, size: 40),
            const SizedBox(height: 8),
            Text('No earnings data for this period', style: TextStyle(color: c.textSub, fontSize: 13)),
          ])),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Container(
        height: 220,
        padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
        decoration: BoxDecoration(
          color: c.isDark ? Colors.white.withOpacity(0.04) : c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.cardBorder),
        ),
        child: AnimatedBuilder(
          animation: _chartAnim,
          builder: (_, __) => BarChart(BarChartData(
            maxY: values.reduce((a, b) => a > b ? a : b) * 1.2,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => c.tooltipBg,
                getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                  '₹${(rod.toY / 1000).toStringAsFixed(0)}K',
                  TextStyle(color: c.text, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                  return Padding(padding: const EdgeInsets.only(top: 6),
                      child: Text(labels[idx], style: TextStyle(color: c.textSub, fontSize: 10)));
                },
              )),
            ),
            gridData: FlGridData(show: true, drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(color: c.chartGrid, strokeWidth: 1)),
            borderData: FlBorderData(show: false),
            barGroups: values.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [
              BarChartRodData(
                toY: e.value * _chartAnim.value,
                gradient: LinearGradient(
                  colors: [AppColors.orangeStart, AppColors.orangeEnd.withOpacity(0.6)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
                width: 22, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ])).toList(),
          )),
        ),
      ),
    );
  }

  Widget _buildStats(FleetColors c) {
    final values = _chartValues;
    if (values.isEmpty) return const SizedBox.shrink();
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.fold(0.0, (a, b) => a + b) / values.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Summary', style: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _StatCard(label: 'Peak Day', value: '₹${(max / 1000).toStringAsFixed(0)}K', color: AppColors.green, c: c)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: 'Daily Avg', value: '₹${(avg / 1000).toStringAsFixed(0)}K', color: AppColors.blue, c: c)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: 'Trips', value: '$_recordCount', color: AppColors.purple, c: c)),
          ]),
        ],
      ),
    );
  }

  Widget _buildError(FleetColors c) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.cloud_off_outlined, color: c.textSub, size: 48),
          const SizedBox(height: 16),
          Text('Could not load earnings', style: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: c.textSub, fontSize: 13), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          GestureDetector(onTap: _loadEarnings, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            decoration: BoxDecoration(gradient: AppColors.orangeGradient, borderRadius: BorderRadius.circular(14)),
            child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          )),
        ]),
      );
}

class _StatCard extends StatelessWidget {
  final String label, value; final Color color; final FleetColors c;
  const _StatCard({required this.label, required this.value, required this.color, required this.c});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.cardBg, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.cardBorder),
        ),
        child: Column(children: [
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: c.textSub, fontSize: 11)),
        ]),
      );
}

class _TabBtn extends StatelessWidget {
  final String label; final bool selected; final VoidCallback onTap;
  const _TabBtn({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: selected ? AppColors.orangeGradient : null,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(label, style: TextStyle(
              color: selected ? Colors.white : FleetTheme.of(context).colors.textSub,
              fontSize: 14, fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            )),
          ),
        ),
      );
}
