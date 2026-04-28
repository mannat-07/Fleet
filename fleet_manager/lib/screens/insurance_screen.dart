import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/status_badge.dart';
import '../widgets/back_button_widget.dart';
import '../widgets/glass_input.dart';
import '../widgets/custom_button.dart';

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
  List<InsuranceModel> _allInsurance = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiService.getInsuranceRecords(),
        ApiService.getTrucks(),
      ]);
      
      if (!mounted) return;

      final insuranceList = results[0];
      final trucksList = results[1];

      // Build insurance records from API
      final insurance = insuranceList.map((j) => InsuranceModel.fromJson(j)).toList();

      // Build set of insured truck IDs
      final insuredTruckIds = insurance.map((i) => i.truckId).toSet();

      // Find trucks with no insurance (pending)
      final pendingInsurance = trucksList
          .where((t) => !insuredTruckIds.contains(t['truckId'] as String? ?? ''))
          .map((t) => InsuranceModel.pending(
                truckId: t['truckId'] as String? ?? '',
                truckPlate: t['plate'] as String? ?? '',
              ))
          .toList();

      _allInsurance = [...insurance, ...pendingInsurance];

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

  void _openAddSheet(InsuranceModel pending) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InsuranceFormSheet(
        truckId: pending.truckId,
        truckPlate: pending.truckPlate,
        onSaved: () => _loadData(),
      ),
    );
  }

  void _openEditSheet(InsuranceModel insurance) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InsuranceFormSheet(
        existing: insurance,
        truckId: insurance.truckId,
        truckPlate: insurance.truckPlate,
        onSaved: () => _loadData(),
      ),
    );
  }

  void _confirmDelete(InsuranceModel insurance) {
    final c = FleetTheme.of(context).colors;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.sheetBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Insurance Record',
          style: TextStyle(color: c.text, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Remove insurance record for ${insurance.truckPlate}?',
          style: TextStyle(color: c.textSub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: c.textSub)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ApiService.deleteInsuranceRecord(insurance.insuranceId);
                _loadData();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Delete failed: $e')),
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = FleetTheme.of(context).colors;
    final valid = _allInsurance.where((i) => i.status == 'Valid').length;
    final expiring = _allInsurance.where((i) => i.status == 'Expiring Soon').length;
    final expired = _allInsurance.where((i) => i.status == 'Expired').length;
    final pending = _allInsurance.where((i) => i.status == 'Pending').length;

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
                      _Chip(label: 'Valid', count: valid, color: AppColors.green, c: c),
                      const SizedBox(width: 10),
                      _Chip(label: 'Expiring', count: expiring, color: AppColors.amber, c: c),
                      const SizedBox(width: 10),
                      _Chip(label: 'Expired', count: expired, color: AppColors.red, c: c),
                      const SizedBox(width: 10),
                      _Chip(label: 'Pending', count: pending, color: AppColors.blue, c: c),
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
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.orangeStart),
      );
    }
    if (_error != null) {
      return _ErrorState(error: _error!, onRetry: _loadData, c: c);
    }
    if (_allInsurance.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_outlined, color: c.textSub, size: 56),
            const SizedBox(height: 16),
            Text(
              'No trucks found',
              style: TextStyle(color: c.textSub, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              'Add trucks to manage their insurance',
              style: TextStyle(color: c.textSub, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.orangeStart,
      backgroundColor: c.surface,
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        itemCount: _allInsurance.length,
        itemBuilder: (_, i) {
          final delay = i * 0.12;
          final anim = CurvedAnimation(
            parent: _controller,
            curve: Interval(delay, delay + 0.5, curve: Curves.easeOutCubic),
          );
          final item = _allInsurance[i];
          return AnimatedBuilder(
            animation: anim,
            builder: (_, child) => Opacity(
              opacity: anim.value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - anim.value)),
                child: child,
              ),
            ),
            child: _InsuranceCard(
              insurance: item,
              c: c,
              onAdd: item.status == 'Pending' ? () => _openAddSheet(item) : null,
              onEdit: item.status != 'Pending' ? () => _openEditSheet(item) : null,
              onDelete: item.status != 'Pending' ? () => _confirmDelete(item) : null,
            ),
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
  final InsuranceModel insurance;
  final FleetColors c;
  final VoidCallback? onAdd;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const _InsuranceCard({
    required this.insurance,
    required this.c,
    this.onAdd,
    this.onEdit,
    this.onDelete,
  });

  Color get _statusColor {
    switch (insurance.status) {
      case 'Valid':
        return AppColors.green;
      case 'Expiring Soon':
        return AppColors.amber;
      case 'Expired':
        return AppColors.red;
      case 'Pending':
        return AppColors.blue;
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
                    insurance.truckPlate,
                    style: TextStyle(
                      color: c.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (insurance.provider.isNotEmpty)
                    Text(
                      insurance.provider,
                      style: TextStyle(color: c.textSub, fontSize: 13),
                    ),
                  if (insurance.status == 'Pending')
                    Text(
                      'Insurance pending',
                      style: TextStyle(color: c.textSub, fontSize: 12),
                    ),
                  if (insurance.expiryDate.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, color: c.textSub, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'Expires: ${insurance.expiryDate}',
                          style: TextStyle(color: c.textSub, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                  if (insurance.status != 'Pending' && insurance.daysUntilExpiry != 0) ...[
                    const SizedBox(height: 3),
                    Text(
                      insurance.daysUntilExpiry > 0
                          ? '${insurance.daysUntilExpiry} days remaining'
                          : '${insurance.daysUntilExpiry.abs()} days overdue',
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge(status: insurance.status),
                const SizedBox(height: 10),
                if (onAdd != null)
                  GestureDetector(
                    onTap: onAdd,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: AppColors.orangeGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Add',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                if (onEdit != null || onDelete != null)
                  Row(
                    children: [
                      if (onEdit != null)
                        GestureDetector(
                          onTap: onEdit,
                          child: Icon(
                            Icons.edit_outlined,
                            color: AppColors.blue.withOpacity(0.8),
                            size: 18,
                          ),
                        ),
                      if (onEdit != null && onDelete != null) const SizedBox(width: 10),
                      if (onDelete != null)
                        GestureDetector(
                          onTap: onDelete,
                          child: Icon(
                            Icons.delete_outline,
                            color: AppColors.red.withOpacity(0.7),
                            size: 18,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      );
}

class _InsuranceFormSheet extends StatefulWidget {
  final InsuranceModel? existing;
  final String truckId;
  final String truckPlate;
  final VoidCallback onSaved;
  const _InsuranceFormSheet({
    this.existing,
    required this.truckId,
    required this.truckPlate,
    required this.onSaved,
  });

  @override
  State<_InsuranceFormSheet> createState() => _InsuranceFormSheetState();
}

class _InsuranceFormSheetState extends State<_InsuranceFormSheet> {
  late final TextEditingController _policyCtrl, _providerCtrl;
  DateTime? _startDate, _expiryDate;
  bool _loading = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _policyCtrl = TextEditingController(text: e?.policyNumber ?? '');
    _providerCtrl = TextEditingController(text: e?.provider ?? '');
    if (e != null && e.startDate.isNotEmpty) {
      _startDate = DateTime.tryParse(e.startDate);
    }
    if (e != null && e.expiryDate.isNotEmpty) {
      _expiryDate = DateTime.tryParse(e.expiryDate);
    }
  }

  @override
  void dispose() {
    _policyCtrl.dispose();
    _providerCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _expiryDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _expiryDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    final policy = _policyCtrl.text.trim();
    final provider = _providerCtrl.text.trim();

    if (policy.isEmpty || provider.isEmpty || _startDate == null || _expiryDate == null) {
      setState(() => _error = 'All fields are required');
      return;
    }

    if (_startDate!.isAfter(_expiryDate!) || _startDate!.isAtSameMomentAs(_expiryDate!)) {
      setState(() => _error = 'Start date must be before expiry date');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final body = {
        'truckId': widget.truckId,
        'policyNumber': policy,
        'provider': provider,
        'startDate': DateFormat('yyyy-MM-dd').format(_startDate!),
        'expiryDate': DateFormat('yyyy-MM-dd').format(_expiryDate!),
      };

      if (_isEdit) {
        await ApiService.updateInsuranceRecord(widget.existing!.insuranceId, body);
      } else {
        await ApiService.addInsuranceRecord(body);
      }

      if (!mounted) return;
      widget.onSaved();
      Navigator.pop(context);
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
    return Container(
      decoration: BoxDecoration(
        color: c.sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: c.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              _isEdit ? 'Edit Insurance' : 'Add Insurance',
              style: TextStyle(
                color: c.text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Truck ${widget.truckPlate}',
              style: TextStyle(color: c.textSub, fontSize: 13),
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              _ErrorBanner(_error!),
              const SizedBox(height: 16),
            ],
            GlassInput(
              hint: 'Policy Number',
              icon: Icons.badge_outlined,
              controller: _policyCtrl,
            ),
            const SizedBox(height: 12),
            GlassInput(
              hint: 'Insurance Provider',
              icon: Icons.shield_outlined,
              controller: _providerCtrl,
            ),
            const SizedBox(height: 12),
            _DateField(
              label: 'Start Date',
              date: _startDate,
              onTap: () => _pickDate(true),
              c: c,
            ),
            const SizedBox(height: 12),
            _DateField(
              label: 'Expiry Date',
              date: _expiryDate,
              onTap: () => _pickDate(false),
              c: c,
            ),
            const SizedBox(height: 18),
            CustomButton(
              label: _isEdit ? 'Update Insurance' : 'Save Insurance',
              onPressed: _submit,
              isLoading: _loading,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final FleetColors c;
  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
    required this.c,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: c.inputBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.inputBorder, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today_outlined, color: c.textSub, size: 18),
              const SizedBox(width: 12),
              Text(
                date != null ? DateFormat('dd MMM yyyy').format(date!) : label,
                style: TextStyle(
                  color: date != null ? c.text : c.textSub,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.red.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.red, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.red, fontSize: 13),
              ),
            ),
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
