import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/theme.dart';
import 'motion.dart';

class GlassCard extends StatefulWidget {
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
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  @override
  Widget build(BuildContext context) {
    final c = FleetTheme.of(context).colors;
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.gradient == null ? c.cardBg : null,
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(color: c.cardBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: c.isDark
                    ? Colors.black.withOpacity(0.28)
                    : Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppColors.orangeStart.withOpacity(
                  c.isDark ? 0.08 : 0.05,
                ),
                blurRadius: 28,
                spreadRadius: 0.6,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: widget.padding ?? const EdgeInsets.all(20),
          child: widget.child,
        ),
      ),
    );

    return FloatMotion(
      child: PressScale(onTap: widget.onTap, child: content),
    );
  }
}
