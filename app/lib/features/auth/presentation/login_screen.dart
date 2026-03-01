import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'bloc/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  final String role;
  const LoginScreen({super.key, this.role = 'client'});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final displayRole = widget.role.isNotEmpty
        ? '${widget.role[0].toUpperCase()}${widget.role.substring(1)}'
        : 'Client';

    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is AuthAuthenticated) {
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
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  const Text(
                    'Welcome back',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to your account as $displayRole',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 48),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (state is AuthLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton(
                      onPressed: () {
                        context.read<AuthBloc>().add(
                          AuthLoginRequested(
                            widget.role,
                            _emailController.text,
                            _passwordController.text,
                          ),
                        );
                      },
                      child: const Text('Login'),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () =>
                            context.push('/register?role=${widget.role}'),
                        child: const Text('Register'),
                      ),
                    ],
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
                      onPressed: () => context.go('/login?role=client'),
                      child: const Text('Login as Client'),
                    ),
                  if (widget.role != 'client') const SizedBox(height: 8),
                  if (widget.role != 'employee')
                    OutlinedButton(
                      onPressed: () => context.go('/login?role=employee'),
                      child: const Text('Login as Employee'),
                    ),
                  if (widget.role != 'employee') const SizedBox(height: 8),
                  if (widget.role != 'admin')
                    OutlinedButton(
                      onPressed: () => context.go('/login?role=admin'),
                      child: const Text('Login as Admin'),
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
