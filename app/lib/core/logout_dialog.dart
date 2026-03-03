import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import 'constants.dart';

/// Styled logout confirmation dialog.
/// Call [showLogoutDialog] from any screen.
Future<void> showLogoutDialog(BuildContext context) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogCtx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      actionsPadding: const EdgeInsets.all(16),
      title: Row(
        children: const [
          Icon(Icons.logout, color: AppColors.danger, size: 22),
          SizedBox(width: 10),
          Text(
            'Logout',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: const Text(
        'Are you sure you want to log out of your account?',
        style: TextStyle(fontSize: 14, color: Colors.black87),
      ),
      actions: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(90, 42),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () => Navigator.pop(dialogCtx),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            minimumSize: const Size(90, 42),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () {
            Navigator.pop(dialogCtx);
            context.read<AuthBloc>().add(AuthLogoutRequested());
          },
          child: const Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}
