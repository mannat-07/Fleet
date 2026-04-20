import 'package:flutter/material.dart';
import '../utils/theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'active':
      case 'valid':
      case 'available':
        return AppColors.green;
      case 'on trip':
        return AppColors.orangeStart;
      case 'expiring':
        return AppColors.amber;
      case 'idle':
        return const Color(0xFF9E9E9E);
      case 'expired':
        return AppColors.red;
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              color: _color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
