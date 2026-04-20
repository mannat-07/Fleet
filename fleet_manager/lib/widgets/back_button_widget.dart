import 'package:flutter/material.dart';
import '../utils/theme.dart';
import 'theme_toggle.dart';

class FleetBackButton extends StatelessWidget {
  const FleetBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = FleetTheme.of(context).colors;
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: c.backBtnBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.backBtnBorder),
          boxShadow: c.isDark
              ? []
              : [BoxShadow(color: const Color(0x0F000000), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Icon(Icons.arrow_back_ios_new, color: c.text, size: 16),
      ),
    );
  }
}

/// Standard screen header with back button, title/subtitle, optional actions,
/// and always-present theme toggle on the far right.
class ScreenHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> actions;
  final bool showToggle;

  const ScreenHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions = const [],
    this.showToggle = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = FleetTheme.of(context).colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          const FleetBackButton(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,    style: TextStyle(color: c.text,    fontSize: 22, fontWeight: FontWeight.w800)),
                Text(subtitle, style: TextStyle(color: c.textSub, fontSize: 13)),
              ],
            ),
          ),
          ...actions,
          if (showToggle) ...[
            const SizedBox(width: 10),
            const ThemeToggle(),
          ],
        ],
      ),
    );
  }
}

/// Icon button used in headers (e.g. add button)
class HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const HeaderIconBtn({super.key, required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          gradient: AppColors.orangeGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: AppColors.orangeStart.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Icon(icon, color: const Color(0xFFFFFFFF), size: 20),
      ),
    );
  }
}
