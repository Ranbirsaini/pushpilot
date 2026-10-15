import 'package:flutter/material.dart';
import '../utils/constants.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? backgroundColor;
  final IconData? icon;
  final bool isPill;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.backgroundColor,
    this.icon,
    this.isPill = true,
  });

  factory StatusBadge.success({required String label, IconData? icon}) {
    return StatusBadge(
      label: label,
      color: AppConstants.success,
      backgroundColor: AppConstants.successBg,
      icon: icon ?? Icons.check_circle_rounded,
    );
  }

  factory StatusBadge.error({required String label, IconData? icon}) {
    return StatusBadge(
      label: label,
      color: AppConstants.error,
      backgroundColor: AppConstants.errorBg,
      icon: icon ?? Icons.cancel_rounded,
    );
  }

  factory StatusBadge.warning({required String label, IconData? icon}) {
    return StatusBadge(
      label: label,
      color: AppConstants.warning,
      backgroundColor: AppConstants.warningBg,
      icon: icon ?? Icons.warning_rounded,
    );
  }

  factory StatusBadge.info({required String label, IconData? icon}) {
    return StatusBadge(
      label: label,
      color: AppConstants.info,
      backgroundColor: AppConstants.infoBg,
      icon: icon ?? Icons.info_outline_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? color.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(isPill ? 20 : 6),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
