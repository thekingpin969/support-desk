import 'package:flutter/material.dart';

enum SnackBarType { success, error, warning, info }

class AppSnackBar {
  static void show(
    BuildContext context,
    String message, {
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    final config = _config(type);

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(config.icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: config.color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: duration,
          elevation: 4,
        ),
      );
  }

  static void success(BuildContext context, String message) =>
      show(context, message, type: SnackBarType.success);

  static void error(BuildContext context, String message) =>
      show(context, message, type: SnackBarType.error);

  static void warning(BuildContext context, String message) =>
      show(context, message, type: SnackBarType.warning);

  static void info(BuildContext context, String message) =>
      show(context, message, type: SnackBarType.info);
}

class _SnackConfig {
  final Color color;
  final IconData icon;
  const _SnackConfig({required this.color, required this.icon});
}

_SnackConfig _config(SnackBarType type) {
  switch (type) {
    case SnackBarType.success:
      return const _SnackConfig(
        color: Color(0xFF22C55E),
        icon: Icons.check_circle_outline,
      );
    case SnackBarType.error:
      return const _SnackConfig(
        color: Color(0xFFEF4444),
        icon: Icons.error_outline,
      );
    case SnackBarType.warning:
      return const _SnackConfig(
        color: Color(0xFFF59E0B),
        icon: Icons.warning_amber_rounded,
      );
    case SnackBarType.info:
      return const _SnackConfig(
        color: Color(0xFF3B82F6),
        icon: Icons.info_outline,
      );
  }
}
