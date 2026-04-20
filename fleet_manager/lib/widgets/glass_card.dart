import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.onTap,
    this.width,
    this.height,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final c = FleetTheme.of(context).colors;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: gradient == null ? c.cardBg : null,
              gradient: gradient,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: c.cardBorder, width: 1),
              boxShadow: [
                BoxShadow(
                  color: c.isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }
}
