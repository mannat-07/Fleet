import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/theme.dart';
import '../models/models.dart';
import '../widgets/back_button_widget.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _chartController;
  late Animation<double> _fadeAnim;
  late Animation<double> _chartAnim;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _fadeController  = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    _chartController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();
    _fadeAnim  = CurvedAnimation(parent: _fadeController,  curve: Curves.easeOut);
    _chartAnim = CurvedAnimation(parent: _chartController, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() { _fadeController.dispose(); _chartController.dispose(); super.dispose(); }

  void _switchTab(int t) {
    setState(() => _tab = t);
    _chartController.reset();
    _chartController.forward();
  }

  List<double> get _data   => _tab == 0 ? SampleData.weeklyEarnings  : SampleData.monthlyEarnings;
  List<String> get _labels => _tab == 0 ? SampleData.weekDays        : SampleData.months;
  double get _total => _data.fold(0, (a, b) => a + b);

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
                SliverToBoxAdapter(child: _buildChart(c)),
                SliverToBoxAdapter(child: _buildBreakdown(c)),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalCard(FleetColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: c.isDark
              ? const LinearGradient(colors: [Color(0xFF1E1E1E), Color(0xFF2A1A0E)], begin: Alignment.topLeft, end: Alignment.bottomRight)
              : LinearGradient(colors: [c.surface, const Color(0xFFFFF3EE)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.orangeStart.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(color: AppColors.orangeStart.withOpacity(c.isDark ? 0.1 : 0.08), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Earnings', style: TextStyle(color: c.textSub, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text('₹${(_total / 100000).toStringAsFixed(2)}L', style: TextStyle(color: c.text, fontSize: 36, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                        child: const Row(
                          children: [
                            Icon(Icons.trending_up, color: AppColors.green, size: 13),
                            SizedBox(width: 3),
                            Text('+12.4%', style: TextStyle(color: AppColors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('vs last period', style: TextStyle(color: c.textSub, fontSize: 12)),
                    ],
                  ),
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
  }

  Widget _buildTabBar(FleetColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: c.isDark ? Colors.white.withOpacity(0.05) : c.surfaceHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.cardBorder),
        ),
        child: Row(
          children: [
            _TabBtn(label: 'Weekly',  selected: _tab == 0, onTap: () => _switchTab(0)),
            _TabBtn(label: 'Monthly', selected: _tab == 1, onTap: () => _switchTab(1)),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(FleetColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Container(
        height: 220,
        padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
        decoration: BoxDecoration(
          color: c.isDark ? Colors.white.withOpacity(0.04) : c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.cardBorder),
          boxShadow: c.isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: AnimatedBuilder(
          animation: _chartAnim,
          builder: (_, __) => BarChart(BarChartData(
            maxY: _data.reduce((a, b) => a > b ? a : b) * 1.2,
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
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= _labels.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(_labels[idx], style: TextStyle(color: c.textSub, fontSize: 11)),
                    );
                  },
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(color: c.chartGrid, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            barGroups: _data.asMap().entries.map((e) {
              return BarChartGroupData(x: e.key, barRods: [
                BarChartRodData(
                  toY: e.value * _chartAnim.value,
                  gradient: LinearGradient(
                    colors: [AppColors.orangeStart, AppColors.orangeEnd.withOpacity(0.6)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  ),
                  width: _tab == 0 ? 22 : 28,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ]);
            }).toList(),
          )),
        ),
      ),
    );
  }

  Widget _buildBreakdown(FleetColors c) {
    final items = [
      _BItem('Freight Revenue',    '₹2,80,000', 0.68, AppColors.orangeStart),
      _BItem('Fuel Surcharge',     '₹72,000',   0.18, AppColors.blue),
      _BItem('Detention Charges',  '₹48,000',   0.12, AppColors.green),
      _BItem('Other Income',       '₹8,000',    0.02, AppColors.amber),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Revenue Breakdown', style: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          ...items.map((item) => _BRow(item: item, c: c)),
        ],
      ),
    );
  }
}

class _BItem {
  final String label, amount;
  final double fraction;
  final Color color;
  const _BItem(this.label, this.amount, this.fraction, this.color);
}

class _BRow extends StatelessWidget {
  final _BItem item;
  final FleetColors c;
  const _BRow({required this.item, required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: item.color, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(child: Text(item.label, style: TextStyle(color: c.textSub, fontSize: 13))),
              Text(item.amount, style: TextStyle(color: c.text, fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.fraction,
              backgroundColor: c.isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.07),
              valueColor: AlwaysStoppedAnimation(item.color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : FleetTheme.of(context).colors.textSub,
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
