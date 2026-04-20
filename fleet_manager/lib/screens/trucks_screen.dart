import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../models/models.dart';
import '../widgets/status_badge.dart';
import '../widgets/back_button_widget.dart';
import '../widgets/glass_input.dart';
import '../widgets/custom_button.dart';

class TrucksScreen extends StatefulWidget {
  const TrucksScreen({super.key});

  @override
  State<TrucksScreen> createState() => _TrucksScreenState();
}

class _TrucksScreenState extends State<TrucksScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TruckFormSheet(
        onSaved: (truck) => setState(() {
          AppStore.trucks.add(truck);
          _controller.reset();
          _controller.forward();
        }),
      ),
    );
  }

  void _openEditSheet(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TruckFormSheet(
        existing: AppStore.trucks[index],
        onSaved: (updated) => setState(() {
          AppStore.trucks[index] = updated;
        }),
      ),
    );
  }

  void _confirmDelete(int index) {
    final c = FleetTheme.of(context).colors;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.sheetBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Truck',
            style: TextStyle(color: c.text, fontWeight: FontWeight.w800)),
        content: Text(
            'Remove ${AppStore.trucks[index].plate} from your fleet?',
            style: TextStyle(color: c.textSub)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: c.textSub)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => AppStore.trucks.removeAt(index));
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: AppColors.red, fontWeight: FontWeight.w700)),
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
                subtitle: '${AppStore.trucks.length} registered',
                actions: [
                  HeaderIconBtn(icon: Icons.add, onTap: _openAddSheet),
                ],
              ),
              Expanded(
                child: AppStore.trucks.isEmpty
                    ? _EmptyState(
                        icon: Icons.local_shipping_outlined,
                        message:
                            'No trucks yet.\nTap + to add your first truck.',
                        c: c,
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(20, 4, 20, 100),
                        itemCount: AppStore.trucks.length,
                        itemBuilder: (_, i) {
                          final delay = (i * 0.12).clamp(0.0, 0.8);
                          final anim = CurvedAnimation(
                            parent: _controller,
                            curve: Interval(
                                delay,
                                (delay + 0.5).clamp(0.0, 1.0),
                                curve: Curves.easeOutCubic),
                          );
                          return AnimatedBuilder(
                            animation: anim,
                            builder: (_, child) => Opacity(
                              opacity: anim.value,
                              child: Transform.translate(
                                  offset:
                                      Offset(0, 20 * (1 - anim.value)),
                                  child: child),
                            ),
                            child: _TruckCard(
                              truck: AppStore.trucks[i],
                              c: c,
                              onEdit: () => _openEditSheet(i),
                              onDelete: () => _confirmDelete(i),
                            ),
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

// ─── Truck Card ───────────────────────────────────────────────────────────────
class _TruckCard extends StatelessWidget {
  final TruckModel truck;
  final FleetColors c;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TruckCard({
    required this.truck,
    required this.c,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.isDark ? const Color(0x0DFFFFFF) : c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.cardBorder),
        boxShadow: c.isDark
            ? []
            : [
                BoxShadow(
                    color: const Color(0x0D000000),
                    blurRadius: 10,
                    offset: const Offset(0, 3))
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
                gradient: AppColors.orangeGradient,
                borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.local_shipping,
                color: Color(0xFFFFFFFF), size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(truck.plate,
                    style: TextStyle(
                        color: c.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4)),
                const SizedBox(height: 2),
                Text('${truck.model}  •  ${truck.type}',
                    style: TextStyle(color: c.textSub, fontSize: 12)),
                const SizedBox(height: 5),
                Row(children: [
                  Icon(Icons.location_on_outlined,
                      color: c.textSub, size: 12),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(truck.location,
                        style:
                            TextStyle(color: c.textSub, fontSize: 11),
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
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
                  GestureDetector(
                    onTap: onEdit,
                    child: Icon(Icons.edit_outlined,
                        color: AppColors.blue.withOpacity(0.8), size: 18),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: onDelete,
                    child: Icon(Icons.delete_outline,
                        color: AppColors.red.withOpacity(0.7), size: 18),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Add / Edit Truck Sheet ───────────────────────────────────────────────────
class _TruckFormSheet extends StatefulWidget {
  final TruckModel? existing; // null = add mode
  final void Function(TruckModel) onSaved;

  const _TruckFormSheet({this.existing, required this.onSaved});

  @override
  State<_TruckFormSheet> createState() => _TruckFormSheetState();
}

class _TruckFormSheetState extends State<_TruckFormSheet> {
  late final TextEditingController _plateCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _locCtrl;
  late String _type;
  late String _status;
  bool    _loading = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  static const _types    = ['heavy', 'medium', 'light', 'tanker', 'flatbed'];
  static const _statuses = ['Active', 'On Trip', 'Idle', 'Maintenance'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _plateCtrl = TextEditingController(text: e?.plate ?? '');
    _modelCtrl = TextEditingController(text: e?.model ?? '');
    _yearCtrl  = TextEditingController(text: e?.year?.toString() ?? '');
    _locCtrl   = TextEditingController(text: e?.location ?? '');
    _type      = e?.type   ?? 'heavy';
    _status    = e?.status ?? 'Idle';
  }

  @override
  void dispose() {
    _plateCtrl.dispose(); _modelCtrl.dispose();
    _yearCtrl.dispose();  _locCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final plate = _plateCtrl.text.trim();
    final model = _modelCtrl.text.trim();
    if (plate.isEmpty || model.isEmpty) {
      setState(() => _error = 'Plate and model are required.');
      return;
    }
    setState(() { _loading = true; _error = null; });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final truck = TruckModel(
        id:       widget.existing?.id ?? AppStore.nextId(AppStore.trucks),
        plate:    plate.toUpperCase(),
        model:    model,
        type:     _type,
        status:   _status,
        location: _locCtrl.text.trim().isEmpty
            ? 'Depot'
            : _locCtrl.text.trim(),
        year:     int.tryParse(_yearCtrl.text.trim()),
        assignedDriverId: widget.existing?.assignedDriverId,
      );
      widget.onSaved(truck);
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = FleetTheme.of(context).colors;
    return Container(
      decoration: BoxDecoration(
        color: c.sheetBg,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: c.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),

            // Header
            Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    gradient: AppColors.orangeGradient,
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.local_shipping,
                    color: Color(0xFFFFFFFF), size: 20),
              ),
              const SizedBox(width: 12),
              Text(_isEdit ? 'Edit Truck' : 'Add New Truck',
                  style: TextStyle(
                      color: c.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              if (_isEdit) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.blue.withOpacity(0.3)),
                  ),
                  child: const Text('Editing',
                      style: TextStyle(
                          color: AppColors.blue,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ]),
            const SizedBox(height: 24),

            // Error
            if (_error != null) ...[
              _ErrorBanner(_error!),
              const SizedBox(height: 16),
            ],

            _Label('Number Plate *', c),
            GlassInput(
                hint: 'e.g. MH12 AB 1234',
                icon: Icons.pin,
                controller: _plateCtrl),
            const SizedBox(height: 14),

            _Label('Truck Model *', c),
            GlassInput(
                hint: 'e.g. Tata Prima 4928.S',
                icon: Icons.directions_car,
                controller: _modelCtrl),
            const SizedBox(height: 14),

            Row(children: [
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
                    ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('Year', c),
                      GlassInput(
                          hint: '2022',
                          icon: Icons.calendar_today_outlined,
                          controller: _yearCtrl,
                          keyboardType: TextInputType.number),
                    ]),
              ),
            ]),
            const SizedBox(height: 14),

            _Label('Status', c),
            _DropdownField(
              value: _status,
              items: _statuses,
              c: c,
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 14),

            _Label('Current Location', c),
            GlassInput(
                hint: 'e.g. Mumbai Depot',
                icon: Icons.location_on_outlined,
                controller: _locCtrl),
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
        child: Text(text,
            style: TextStyle(
                color: c.textSub,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
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
            border: Border.all(color: AppColors.red.withOpacity(0.3))),
        child: Row(children: [
          const Icon(Icons.error_outline, color: AppColors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: AppColors.red, fontSize: 13))),
        ]),
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
  Widget build(BuildContext context) {
    return Container(
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
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e, style: TextStyle(color: c.text)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final FleetColors c;
  const _EmptyState(
      {required this.icon, required this.message, required this.c});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: c.textSub, size: 56),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: c.textSub, fontSize: 15, height: 1.6)),
          ],
        ),
      );
}
