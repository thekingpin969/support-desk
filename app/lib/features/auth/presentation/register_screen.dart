import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'bloc/auth_bloc.dart';
import '../../../core/app_snackbar.dart';
import '../../../core/loading_button.dart';

class RegisterScreen extends StatefulWidget {
  final String role;
  const RegisterScreen({super.key, this.role = 'client'});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      AppSnackBar.warning(context, 'Please fill in all fields.');
      return;
    }
    if (password.length < 6) {
      AppSnackBar.warning(context, 'Password must be at least 6 characters.');
      return;
    }

    context.read<AuthBloc>().add(
      AuthRegisterRequested(widget.role, email, password, name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayRole = widget.role.isNotEmpty
        ? '${widget.role[0].toUpperCase()}${widget.role.substring(1)}'
        : 'Client';

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            AppSnackBar.error(context, state.message);
          } else if (state is AuthAuthenticated) {
            AppSnackBar.success(context, 'Account created successfully!');
            if (state.user.role == 'client') {
              context.go('/client');
            } else if (state.user.role == 'employee') {
              context.go('/employee');
            } else if (state.user.role == 'admin') {
              context.go('/admin');
            }
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Create an account',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign up as $displayRole',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 48),
                  TextField(
                    controller: _nameController,
                    enabled: !isLoading,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    enabled: !isLoading,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    enabled: !isLoading,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(context),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  LoadingButton(
                    isLoading: isLoading,
                    label: 'Create Account',
                    icon: Icons.person_add_outlined,
                    onPressed: () => _submit(context),
                  ),
                  const Divider(height: 48),
                  const Text(
                    'Switch Role',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (widget.role != 'client')
                    OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : () => context.go('/register?role=client'),
                      child: const Text('Register as Client'),
                    ),
                  if (widget.role != 'client') const SizedBox(height: 8),
                  if (widget.role != 'employee')
                    OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : () => context.go('/register?role=employee'),
                      child: const Text('Register as Employee'),
                    ),
                  if (widget.role != 'employee') const SizedBox(height: 8),
                  if (widget.role != 'admin')
                    OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : () => context.go('/register?role=admin'),
                      child: const Text('Register as Admin'),
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
