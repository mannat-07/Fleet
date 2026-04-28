import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/back_button_widget.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _loading = true;
  String? _error;
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadNotifications();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getNotifications();
      if (!mounted) return;
      final list = (data['notifications'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(NotificationModel.fromJson)
          .toList();
      _notifications = list;
      AppStore.notifications = list;
      AppStore.notificationCount = data['count'] as int? ?? list.length;
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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: c.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(
                title: 'Notifications',
                subtitle: _loading
                    ? 'Loading…'
                    : '${_notifications.length} active alert${_notifications.length == 1 ? '' : 's'}',
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
      return _ErrorState(error: _error!, onRetry: _loadNotifications, c: c);
    }
    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none_outlined, color: c.textSub, size: 56),
            const SizedBox(height: 16),
            Text(
              'No active alerts',
              style: TextStyle(
                color: c.text,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All your truck insurance is up to date',
              style: TextStyle(color: c.textSub, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.orangeStart,
      backgroundColor: c.surface,
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        itemCount: _notifications.length,
        itemBuilder: (_, i) {
          final delay = i * 0.1;
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
            child: _NotificationCard(notification: _notifications[i], c: c),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final FleetColors c;
  const _NotificationCard({required this.notification, required this.c});

  Color get _color {
    switch (notification.type) {
      case 'expiring_soon':
        return AppColors.amber;
      case 'expired':
        return AppColors.red;
      case 'pending_insurance':
        return AppColors.blue;
      default:
        return AppColors.blue;
    }
  }

  IconData get _icon {
    switch (notification.type) {
      case 'expiring_soon':
        return Icons.warning_amber_rounded;
      case 'expired':
        return Icons.cancel_outlined;
      case 'pending_insurance':
        return Icons.shield_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String get _typeLabel {
    switch (notification.type) {
      case 'expiring_soon':
        return 'Expiring Soon';
      case 'expired':
        return 'Expired';
      case 'pending_insurance':
        return 'No Insurance';
      default:
        return 'Alert';
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.isDark ? Colors.white.withOpacity(0.05) : c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_icon, color: _color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        notification.truckPlate,
                        style: TextStyle(
                          color: c.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _typeLabel,
                          style: TextStyle(
                            color: _color,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(color: c.textSub, fontSize: 13),
                  ),
                  if (notification.daysUntilExpiry != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      notification.daysUntilExpiry! > 0
                          ? '${notification.daysUntilExpiry} day${notification.daysUntilExpiry == 1 ? '' : 's'} remaining'
                          : '${notification.daysUntilExpiry!.abs()} day${notification.daysUntilExpiry!.abs() == 1 ? '' : 's'} overdue',
                      style: TextStyle(
                        color: _color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
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
                'Could not load notifications',
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
