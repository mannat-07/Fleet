import 'package:flutter/material.dart';
import '../utils/theme.dart';

class GlassInput extends StatefulWidget {
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextEditingController? controller;
  final TextInputType keyboardType;

  const GlassInput({
    super.key,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.controller,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<GlassInput> createState() => _GlassInputState();
}

class _GlassInputState extends State<GlassInput> {
  bool _focused = false;
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    final c = FleetTheme.of(context).colors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _focused
              ? AppColors.orangeStart.withOpacity(0.7)
              : c.inputBorder,
          width: 1.5,
        ),
        color: c.inputBg,
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: AppColors.orangeStart.withOpacity(0.15),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: Focus(
        onFocusChange: (v) => setState(() => _focused = v),
        child: TextField(
          controller: widget.controller,
          obscureText: widget.obscure && !_showPassword,
          keyboardType: widget.keyboardType,
          style: TextStyle(color: c.text, fontSize: 15),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(color: c.textSub.withOpacity(0.7)),
            prefixIcon: Icon(widget.icon, color: c.textSub, size: 20),
            suffixIcon: widget.obscure
                ? IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                      color: c.textSub,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          ),
        ),
      ),
    );
  }
}
