import 'package:flutter/material.dart';
import 'constants.dart';

/// A full-width [ElevatedButton] that shows an inline spinner when [isLoading]
/// is true. The button keeps its size and layout during loading, preventing
/// layout jumps.
class LoadingButton extends StatelessWidget {
  final bool isLoading;
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const LoadingButton({
    super.key,
    required this.isLoading,
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.primary;
    final fg = foregroundColor ?? Colors.white;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        disabledBackgroundColor: bg.withValues(alpha: 0.7),
        disabledForegroundColor: fg.withValues(alpha: 0.8),
      ),
      onPressed: isLoading ? null : onPressed,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: isLoading
            ? Row(
                key: const ValueKey('loading'),
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: fg,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(fontWeight: FontWeight.w600, color: fg),
                  ),
                ],
              )
            : Row(
                key: const ValueKey('idle'),
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: fg),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(fontWeight: FontWeight.w600, color: fg),
                  ),
                ],
              ),
      ),
    );
  }
}
