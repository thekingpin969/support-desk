import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'bloc/auth_bloc.dart';
import '../../../core/app_snackbar.dart';
import '../../../core/loading_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      AppSnackBar.warning(context, 'Please enter your email address.');
      return;
    }
    context.read<AuthBloc>().add(AuthForgotPasswordRequested(email));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            AppSnackBar.error(context, state.message);
          } else if (state is AuthPasswordResetLinkSent) {
            AppSnackBar.success(context, 'Reset link sent! Check your inbox.');
            context.push('/reset-password');
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
                    'Reset your password',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Enter your email address and we will send you a link to reset your password.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _emailController,
                    enabled: !isLoading,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(context),
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 32),
                  LoadingButton(
                    isLoading: isLoading,
                    label: 'Send Reset Link',
                    icon: Icons.send_outlined,
                    onPressed: () => _submit(context),
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
