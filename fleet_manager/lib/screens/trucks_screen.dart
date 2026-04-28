import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/status_badge.dart';
import '../widgets/back_button_widget.dart';
import '../widgets/glass_input.dart';
import '../widgets/custom_button.dart';
import '../widgets/motion.dart';
import 'truck_sensor_screen.dart';

class TrucksScreen extends StatefulWidget {
  const TrucksScreen({super.key});

  @override
  State<TrucksScreen> createState() => _TrucksScreenState();
}

class _TrucksScreenState extends State<TrucksScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTrucks();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadTrucks() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ApiService.getTrucks();
      if (!mounted) return;
      AppStore.trucks = list.map(TruckModel.fromJson).toList();
      if (AppStore.trucks.isEmpty) {
        AppStore.trucks = DemoData.trucks();
      }
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      AppStore.trucks = DemoData.trucks();
      setState(() {
        _loading = false;
        _error = null;
      });
    }
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TruckFormSheet(onSaved: (_) => _loadTrucks()),
    );
  }

  void _openEditSheet(TruckModel truck) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _TruckFormSheet(existing: truck, onSaved: (_) => _loadTrucks()),
    );
  }

  void _confirmDelete(TruckModel truck) {
    final c = FleetTheme.of(context).colors;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.sheetBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Truck',
          style: TextStyle(color: c.text, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Remove ${truck.plate} from your fleet?',
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
                await ApiService.deleteTruck(truck.id);
                _loadTrucks();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: AppColors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
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
              ScreenHeader(
                title: 'Your Trucks',
                subtitle: _loading
                    ? 'Loading…'
                    : '${AppStore.trucks.length} registered',
                actions: [HeaderIconBtn(icon: Icons.add, onTap: _openAddSheet)],
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
      return _ErrorState(error: _error!, onRetry: _loadTrucks, c: c);
    if (AppStore.trucks.isEmpty)
      return _EmptyState(
        icon: Icons.local_shipping_outlined,
        message: 'No trucks yet.\nTap + to add your first truck.',
        c: c,
      );

    return RefreshIndicator(
      color: AppColors.orangeStart,
      backgroundColor: c.surface,
      onRefresh: _loadTrucks,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
        itemCount: AppStore.trucks.length,
        itemBuilder: (_, i) {
          return StaggerReveal(
            delay: Duration(milliseconds: i * 80),
            child: _TruckCard(
              truck: AppStore.trucks[i],
              c: c,
              onEdit: () => _openEditSheet(AppStore.trucks[i]),
              onDelete: () => _confirmDelete(AppStore.trucks[i]),
              onSensor: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      TruckSensorScreen(truck: AppStore.trucks[i]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TruckCard extends StatelessWidget {
  final TruckModel truck;
  final FleetColors c;
  final VoidCallback onEdit, onDelete, onSensor;
  const _TruckCard({
    required this.truck,
    required this.c,
    required this.onEdit,
    required this.onDelete,
    required this.onSensor,
  });

  @override
  Widget build(BuildContext context) => FloatMotion(
    child: PressScale(
      onTap: onSensor,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.isDark ? const Color(0x0DFFFFFF) : c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.cardBorder),
          boxShadow: [
            BoxShadow(
              color: AppColors.orangeStart.withOpacity(c.isDark ? 0.1 : 0.08),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Hero(
              tag: 'truck-hero-${truck.id}',
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.orangeGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Breathing(
                  child: Icon(
                    Icons.local_shipping,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    truck.plate,
                    style: TextStyle(
                      color: c.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${truck.model}  •  ${truck.type}',
                    style: TextStyle(color: c.textSub, fontSize: 12),
                  ),
                  if (truck.location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: c.textSub,
                          size: 12,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            truck.location,
                            style: TextStyle(color: c.textSub, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge(status: truck.status),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // IoT sensor button
                    PressScale(
                      onTap: onSensor,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.green.withOpacity(0.3)),
                        ),
                        child: const Icon(
                          Icons.sensors,
                          color: AppColors.green,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PressScale(
                      onTap: onEdit,
                      child: Icon(
                        Icons.edit_outlined,
                        color: AppColors.blue.withOpacity(0.8),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    PressScale(
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
      ),
    ),
  );
}

class _TruckFormSheet extends StatefulWidget {
  final TruckModel? existing;
  final void Function(TruckModel) onSaved;
  const _TruckFormSheet({this.existing, required this.onSaved});

  @override
  State<_TruckFormSheet> createState() => _TruckFormSheetState();
}

class _TruckFormSheetState extends State<_TruckFormSheet> {
  late final TextEditingController _plateCtrl, _modelCtrl, _yearCtrl;
  late String _type, _status;
  bool _loading = false;
  String? _error;

  // Available driver dropdown state
  List<Map<String, dynamic>> _availableDrivers = [];
  bool _driversLoadFailed = false;
  String? _selectedDriverId;

  bool get _isEdit => widget.existing != null;
  static const _types = ['heavy', 'medium', 'light', 'tanker', 'flatbed'];
  static const _statuses = ['idle', 'active', 'on_trip', 'maintenance'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _plateCtrl = TextEditingController(text: e?.plate ?? '');
    _modelCtrl = TextEditingController(text: e?.model ?? '');
    _yearCtrl = TextEditingController(text: e?.year?.toString() ?? '');
    _type = e?.type ?? 'heavy';
    _status = e?.status ?? 'idle';

    // Only fetch available drivers in add mode
    if (!_isEdit) {
      _fetchAvailableDrivers();
    }
  }

  Future<void> _fetchAvailableDrivers() async {
    try {
      final drivers = await ApiService.getAvailableDrivers();
      if (!mounted) return;
      setState(() => _availableDrivers = drivers);
    } catch (_) {
      if (!mounted) return;
      setState(() => _driversLoadFailed = true);
    }
  }

  @override
  void dispose() {
    _plateCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final plate = _plateCtrl.text.trim();
    final model = _modelCtrl.text.trim();
    if (plate.isEmpty || model.isEmpty) {
      setState(() => _error = 'Plate and model are required.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final body = {
        'plate': plate.toUpperCase(),
        'model': model,
        'type': _type,
        'status': _status,
        if (_yearCtrl.text.trim().isNotEmpty)
          'year': int.tryParse(_yearCtrl.text.trim()),
        if (_selectedDriverId != null) 'driverId': _selectedDriverId,
      };
      final result = await ApiService.addTruck(body);
      if (!mounted) return;
      widget.onSaved(TruckModel.fromJson(result));
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
            Row(
              children: [
                if (widget.existing != null)
                  Hero(
                    tag: 'truck-hero-${widget.existing!.id}',
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppColors.orangeGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Breathing(
                        child: Icon(
                          Icons.local_shipping,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.orangeGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Breathing(
                      child: Icon(
                        Icons.local_shipping,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Text(
                  _isEdit ? 'Edit Truck' : 'Add New Truck',
                  style: TextStyle(
                    color: c.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              _ErrorBanner(_error!),
              const SizedBox(height: 16),
            ],
            _Label('Number Plate *', c),
            GlassInput(
              hint: 'e.g. MH12 AB 1234',
              icon: Icons.pin,
              controller: _plateCtrl,
            ),
            const SizedBox(height: 14),
            _Label('Truck Model *', c),
            GlassInput(
              hint: 'e.g. Tata Prima 4928.S',
              icon: Icons.directions_car,
              controller: _modelCtrl,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('Type', c),
                      _DropdownField(
                        value: _type,
                        items: _types,
                        c: c,
                        onChanged: (v) => setState(() => _type = v!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('Year', c),
                      GlassInput(
                        hint: '${DateTime.now().year}',
                        icon: Icons.calendar_today_outlined,
                        controller: _yearCtrl,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Label('Status', c),
            _DropdownField(
              value: _status,
              items: _statuses,
              c: c,
              onChanged: (v) => setState(() => _status = v!),
            ),
            if (!_isEdit) ...[
              const SizedBox(height: 14),
              _Label('Assign Driver (optional)', c),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: c.inputBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.inputBorder, width: 1.5),
                ),
                child: _driversLoadFailed
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: c.textSub, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Could not load drivers',
                              style: TextStyle(color: c.textSub, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _selectedDriverId,
                          isExpanded: true,
                          dropdownColor: c.sheetBg,
                          style: TextStyle(color: c.text, fontSize: 14),
                          icon: Icon(Icons.keyboard_arrow_down, color: c.textSub),
                          hint: Text(
                            _availableDrivers.isEmpty
                                ? 'No available drivers'
                                : 'Select a driver',
                            style: TextStyle(color: c.textSub, fontSize: 14),
                          ),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(
                                'None',
                                style: TextStyle(color: c.textSub),
                              ),
                            ),
                            ..._availableDrivers.map((d) => DropdownMenuItem<String?>(
                                  value: d['driverId'] as String?,
                                  child: Text(
                                    d['name'] as String? ?? '',
                                    style: TextStyle(color: c.text),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )),
                          ],
                          onChanged: _availableDrivers.isEmpty
                              ? null
                              : (v) => setState(() => _selectedDriverId = v),
                        ),
                      ),
              ),
            ],
            const SizedBox(height: 28),
            CustomButton(
              label: _isEdit ? 'Save Changes' : 'Add Truck',
              onPressed: _submit,
              isLoading: _loading,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  final FleetColors c;
  const _Label(this.text, this.c);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: TextStyle(
        color: c.textSub,
        fontSize: 12,
        fontWeight: FontWeight.w600,
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

class _DropdownField extends StatelessWidget {
  final String value;
  final List<String> items;
  final FleetColors c;
  final void Function(String?) onChanged;
  const _DropdownField({
    required this.value,
    required this.items,
    required this.c,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    decoration: BoxDecoration(
      color: c.inputBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: c.inputBorder, width: 1.5),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        dropdownColor: c.sheetBg,
        style: TextStyle(color: c.text, fontSize: 14),
        icon: Icon(Icons.keyboard_arrow_down, color: c.textSub),
        items: items
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: TextStyle(color: c.text)),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final FleetColors c;
  const _EmptyState({
    required this.icon,
    required this.message,
    required this.c,
  });
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: c.textSub, size: 56),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: c.textSub, fontSize: 15, height: 1.6),
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
            'Could not load trucks',
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
