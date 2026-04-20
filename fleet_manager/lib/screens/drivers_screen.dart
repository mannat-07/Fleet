import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../models/models.dart';
import '../widgets/status_badge.dart';
import '../widgets/back_button_widget.dart';
import '../widgets/glass_input.dart';
import '../widgets/custom_button.dart';

class DriversScreen extends StatefulWidget {
  const DriversScreen({super.key});

  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen>
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
      builder: (_) => _DriverFormSheet(
        onSaved: (driver) => setState(() {
          AppStore.drivers.add(driver);
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
      builder: (_) => _DriverFormSheet(
        existing: AppStore.drivers[index],
        onSaved: (updated) => setState(() {
          AppStore.drivers[index] = updated;
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remove Driver',
            style: TextStyle(
                color: c.text, fontWeight: FontWeight.w800)),
        content: Text(
            'Remove ${AppStore.drivers[index].name} from your team?',
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
              setState(() => AppStore.drivers.removeAt(index));
            },
            child: const Text('Remove',
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
                title: 'Drivers',
                subtitle: '${AppStore.drivers.length} registered',
                actions: [
                  HeaderIconBtn(
                      icon: Icons.person_add_alt_1,
                      onTap: _openAddSheet),
                ],
              ),
              Expanded(
                child: AppStore.drivers.isEmpty
                    ? _EmptyState(
                        icon: Icons.people_outline,
                        message:
                            'No drivers yet.\nTap + to add your first driver.',
                        c: c,
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(20, 4, 20, 32),
                        itemCount: AppStore.drivers.length,
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
                            child: _DriverCard(
                              driver: AppStore.drivers[i],
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

// ─── Driver Card ──────────────────────────────────────────────────────────────
class _DriverCard extends StatelessWidget {
  final DriverModel driver;
  final FleetColors c;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DriverCard({
    required this.driver,
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
              gradient: const LinearGradient(
                  colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)]),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(driver.avatarInitials,
                style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(driver.name,
                    style: TextStyle(
                        color: c.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Row(children: [
                  Icon(Icons.phone_outlined, color: c.textSub, size: 12),
                  const SizedBox(width: 4),
                  Text(driver.phone,
                      style: TextStyle(color: c.textSub, fontSize: 12)),
                ]),
                const SizedBox(height: 3),
                Row(children: [
                  Icon(Icons.local_shipping_outlined,
                      color: c.textSub, size: 12),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(driver.assignedTruck,
                        style:
                            TextStyle(color: c.textSub, fontSize: 12),
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
              StatusBadge(status: driver.status),
              const SizedBox(height: 8),
              Row(
                children: [
                  GestureDetector(
                    onTap: onEdit,
                    child: Icon(Icons.edit_outlined,
                        color: AppColors.blue.withOpacity(0.8),
                        size: 18),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: onDelete,
                    child: Icon(Icons.delete_outline,
                        color: AppColors.red.withOpacity(0.7),
                        size: 18),
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

// ─── Add / Edit Driver Sheet ──────────────────────────────────────────────────
class _DriverFormSheet extends StatefulWidget {
  final DriverModel? existing; // null = add mode
  final void Function(DriverModel) onSaved;

  const _DriverFormSheet({this.existing, required this.onSaved});

  @override
  State<_DriverFormSheet> createState() => _DriverFormSheetState();
}

class _DriverFormSheetState extends State<_DriverFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _licCtrl;
  late final TextEditingController _truckCtrl;
  late String _status;
  bool    _loading = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  static const _statuses = ['Available', 'On Trip', 'Off Duty'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl  = TextEditingController(text: e?.name ?? '');
    _phoneCtrl = TextEditingController(text: e?.phone ?? '');
    _licCtrl   = TextEditingController(text: e?.licenseNumber ?? '');
    _truckCtrl = TextEditingController(
        text: e?.assignedTruck == 'Unassigned' ? '' : (e?.assignedTruck ?? ''));
    _status    = e?.status ?? 'Available';
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    _licCtrl.dispose();  _truckCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name  = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      setState(() => _error = 'Name and phone are required.');
      return;
    }
    setState(() { _loading = true; _error = null; });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final driver = DriverModel(
        id:             widget.existing?.id ?? AppStore.nextId(AppStore.drivers),
        name:           name,
        phone:          phone,
        licenseNumber:  _licCtrl.text.trim().isEmpty
            ? 'N/A'
            : _licCtrl.text.trim(),
        assignedTruck:  _truckCtrl.text.trim().isEmpty
            ? 'Unassigned'
            : _truckCtrl.text.trim(),
        status:         _status,
        avatarInitials: AppStore.initials(name),
      );
      widget.onSaved(driver);
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
                  gradient: const LinearGradient(
                      colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person,
                    color: Color(0xFFFFFFFF), size: 20),
              ),
              const SizedBox(width: 12),
              Text(_isEdit ? 'Edit Driver' : 'Add New Driver',
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

            _Label('Full Name *', c),
            GlassInput(
                hint: 'e.g. Rajesh Kumar',
                icon: Icons.person_outline,
                controller: _nameCtrl),
            const SizedBox(height: 14),

            _Label('Phone Number *', c),
            GlassInput(
                hint: '+91 98765 43210',
                icon: Icons.phone_outlined,
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 14),

            _Label('License Number', c),
            GlassInput(
                hint: 'e.g. MH-0120110012345',
                icon: Icons.badge_outlined,
                controller: _licCtrl),
            const SizedBox(height: 14),

            _Label('Assigned Truck (plate)', c),
            GlassInput(
                hint: 'e.g. MH12 AB 1234',
                icon: Icons.local_shipping_outlined,
                controller: _truckCtrl),
            const SizedBox(height: 14),

            _Label('Status', c),
            _DropdownField(
              value: _status,
              items: _statuses,
              c: c,
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 28),

            CustomButton(
              label: _isEdit ? 'Save Changes' : 'Add Driver',
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
