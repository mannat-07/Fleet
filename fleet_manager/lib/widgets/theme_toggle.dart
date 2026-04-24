import 'package:flutter/material.dart';
import '../utils/theme.dart';

class ThemeToggle extends StatelessWidget {
  final double? width;
  final double? height;

  const ThemeToggle({super.key, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    final ft = FleetTheme.of(context);
    final c = ft.colors;

    return GestureDetector(
      onTap: ft.toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: width ?? 56,
        height: height ?? 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: c.isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8EDFB),
          border: Border.all(
            color: c.isDark ? const Color(0x1FFFFFFF) : const Color(0x14000000),
          ),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: c.isDark
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Container(
                width: (height ?? 28) - 6,
                height: (height ?? 28) - 6,
                decoration: BoxDecoration(
                  gradient: AppColors.orangeGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.orangeStart.withOpacity(0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Icon(
                  c.isDark ? Icons.dark_mode : Icons.light_mode,
                  color: const Color(0xFFFFFFFF),
                  size: (height ?? 28) * 0.42,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
