import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
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
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _loadDrivers();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadDrivers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ApiService.getDrivers();
      if (!mounted) return;
      AppStore.drivers = list.map(DriverModel.fromJson).toList();
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

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DriverFormSheet(
        onSaved: (_) => _loadDrivers(),
        onCredentials: (email, password) =>
            _showCredentialsDialog(email, password),
      ),
    );
  }

  void _showCredentialsDialog(String email, String password) {
    final c = FleetTheme.of(context).colors;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: c.sheetBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.green,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Driver Account Created',
              style: TextStyle(
                color: c.text,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share these login credentials with the driver:',
              style: TextStyle(color: c.textSub, fontSize: 13),
            ),
            const SizedBox(height: 16),
            _CredentialRow(label: 'Email', value: email, c: c),
            const SizedBox(height: 10),
            _CredentialRow(label: 'Password', value: password, c: c),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.amber,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Save this password — it won\'t be shown again.',
                      style: TextStyle(color: c.text, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: AppColors.orangeGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Got it',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openEditSheet(DriverModel driver) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _DriverFormSheet(existing: driver, onSaved: (_) => _loadDrivers()),
    );
  }

  void _confirmDelete(DriverModel driver) {
    final c = FleetTheme.of(context).colors;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.sheetBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Remove Driver',
          style: TextStyle(color: c.text, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Remove ${driver.name} from your team?',
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
                await ApiService.deleteDriver(driver.id);
                _loadDrivers();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
              }
            },
            child: const Text(
              'Remove',
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
                title: 'Drivers',
                subtitle: _loading
                    ? 'Loading…'
                    : '${AppStore.drivers.length} registered',
                actions: [
                  HeaderIconBtn(
                    icon: Icons.person_add_alt_1,
                    onTap: _openAddSheet,
                  ),
                ],
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
      return _ErrorState(error: _error!, onRetry: _loadDrivers, c: c);
    if (AppStore.drivers.isEmpty)
      return _EmptyState(
        icon: Icons.people_outline,
        message: 'No drivers yet.\nTap + to add your first driver.',
        c: c,
      );

    return RefreshIndicator(
      color: AppColors.orangeStart,
      backgroundColor: c.surface,
      onRefresh: _loadDrivers,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        itemCount: AppStore.drivers.length,
        itemBuilder: (_, i) {
          final delay = (i * 0.12).clamp(0.0, 0.8);
          final anim = CurvedAnimation(
            parent: _controller,
            curve: Interval(
              delay,
              (delay + 0.5).clamp(0.0, 1.0),
              curve: Curves.easeOutCubic,
            ),
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
            child: _DriverCard(
              driver: AppStore.drivers[i],
              c: c,
              onEdit: () => _openEditSheet(AppStore.drivers[i]),
              onDelete: () => _confirmDelete(AppStore.drivers[i]),
            ),
          );
        },
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  final DriverModel driver;
  final FleetColors c;
  final VoidCallback onEdit, onDelete;
  const _DriverCard({
    required this.driver,
    required this.c,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: c.isDark ? const Color(0x0DFFFFFF) : c.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: c.cardBorder),
    ),
    child: Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            driver.avatarInitials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                driver.name,
                style: TextStyle(
                  color: c.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              if (driver.phone.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.phone_outlined, color: c.textSub, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      driver.phone,
                      style: TextStyle(color: c.textSub, fontSize: 12),
                    ),
                  ],
                ),
              const SizedBox(height: 3),
              if (driver.assignedTruck.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      Icons.local_shipping_outlined,
                      color: c.textSub,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        driver.assignedTruck,
                        style: TextStyle(color: c.textSub, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
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
                  child: Icon(
                    Icons.edit_outlined,
                    color: AppColors.blue.withOpacity(0.8),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
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

class _DriverFormSheet extends StatefulWidget {
  final DriverModel? existing;
  final void Function(DriverModel) onSaved;
  final void Function(String email, String password)? onCredentials;
  const _DriverFormSheet({
    this.existing,
    required this.onSaved,
    this.onCredentials,
  });

  @override
  State<_DriverFormSheet> createState() => _DriverFormSheetState();
}

class _DriverFormSheetState extends State<_DriverFormSheet> {
  late final TextEditingController _nameCtrl,
      _phoneCtrl,
      _licCtrl,
      _emailCtrl,
      _passCtrl;
  bool _loading = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _phoneCtrl = TextEditingController(text: e?.phone ?? '');
    _licCtrl = TextEditingController(text: e?.licenseNumber ?? '');
    _emailCtrl = TextEditingController();
    _passCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _licCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty || email.isEmpty) {
      setState(() => _error = 'Name and email are required.');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final body = {
        'name': name,
        'email': email,
        'phone': phone,
        if (_licCtrl.text.trim().isNotEmpty)
          'licenseNumber': _licCtrl.text.trim(),
        if (_passCtrl.text.trim().isNotEmpty) 'password': _passCtrl.text.trim(),
      };
      final result = await ApiService.addDriver(body);
      if (!mounted) return;

      final tempPassword = result['tempPassword'] as String? ?? '';
      widget.onSaved(DriverModel.fromJson(result));
      Navigator.pop(context);

      // Show credentials dialog so owner can share with driver
      if (tempPassword.isNotEmpty) {
        widget.onCredentials?.call(email, tempPassword);
      }
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
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _isEdit ? 'Edit Driver' : 'Add New Driver',
                  style: TextStyle(
                    color: c.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!_isEdit)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.blue,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'A login account will be created for the driver. Share the credentials with them.',
                          style: TextStyle(color: c.text, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              _ErrorBanner(_error!),
              const SizedBox(height: 16),
            ],
            _Label('Full Name *', c),
            GlassInput(
              hint: 'Full name',
              icon: Icons.person_outline,
              controller: _nameCtrl,
            ),
            const SizedBox(height: 14),
            _Label('Email (login) *', c),
            GlassInput(
              hint: 'driver@example.com',
              icon: Icons.email_outlined,
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            _Label('Password (optional — auto-generated if blank)', c),
            GlassInput(
              hint: 'Leave blank to auto-generate',
              icon: Icons.lock_outline,
              controller: _passCtrl,
              obscure: true,
            ),
            const SizedBox(height: 14),
            _Label('Phone Number', c),
            GlassInput(
              hint: '+91 XXXXX XXXXX',
              icon: Icons.phone_outlined,
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            _Label('License Number', c),
            GlassInput(
              hint: 'License number',
              icon: Icons.badge_outlined,
              controller: _licCtrl,
            ),
            const SizedBox(height: 28),
            CustomButton(
              label: _isEdit ? 'Save Changes' : 'Add Driver & Create Account',
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
            'Could not load drivers',
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

class _CredentialRow extends StatefulWidget {
  final String label, value;
  final FleetColors c;
  const _CredentialRow({
    required this.label,
    required this.value,
    required this.c,
  });

  @override
  State<_CredentialRow> createState() => _CredentialRowState();
}

class _CredentialRowState extends State<_CredentialRow> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: widget.c.surfaceHigh,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: widget.c.cardBorder),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label,
                style: TextStyle(color: widget.c.textSub, fontSize: 11),
              ),
              const SizedBox(height: 2),
              SelectableText(
                widget.value,
                style: TextStyle(
                  color: widget.c.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: widget.value));
            if (!mounted) return;
            setState(() => _copied = true);
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) setState(() => _copied = false);
            });
          },
          child: Icon(
            _copied ? Icons.check_circle : Icons.copy,
            color: _copied ? AppColors.green : widget.c.textSub,
            size: 18,
          ),
        ),
      ],
    ),
  );
}
