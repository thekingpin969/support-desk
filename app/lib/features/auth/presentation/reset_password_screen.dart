import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'bloc/auth_bloc.dart';
import '../../../core/app_snackbar.dart';
import '../../../core/loading_button.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();

  void _submit() {
    if (_tokenController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty) {
      context.read<AuthBloc>().add(
        AuthResetPasswordRequested(
          _tokenController.text,
          _passwordController.text,
        ),
      );
    } else {
      AppSnackBar.warning(context, 'Please fill in all fields.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            AppSnackBar.error(context, state.message);
          } else if (state is AuthAuthenticated || state is AuthInitial) {
            // Let's just say reset password succeeded and we go to login
            AppSnackBar.success(
              context,
              'Password reset successful. Please login again.',
            );
            context.go('/login');
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Create new password',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Enter the reset token sent to your email and your new password.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _tokenController,
                    enabled: !isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Reset Token',
                      prefixIcon: Icon(Icons.key),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    enabled: !isLoading,
                    onSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 32),
                  LoadingButton(
                    isLoading: isLoading,
                    label: 'Reset Password',
                    icon: Icons.lock_reset,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
