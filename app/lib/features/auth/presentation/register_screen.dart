import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'bloc/auth_bloc.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        backgroundColor: Colors.transparent,
      ),
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
                    'Sign up as a ${widget.role.isNotEmpty ? widget.role[0].toUpperCase() + widget.role.substring(1) : 'Client'}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 48),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 24),
                  if (state is AuthLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton(
                      onPressed: () {
                        context.read<AuthBloc>().add(
                          AuthRegisterRequested(
                            widget.role,
                            _emailController.text,
                            _passwordController.text,
                            _nameController.text,
                          ),
                        );
                      },
                      child: const Text('Register'),
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
                      onPressed: () => context.go('/register?role=client'),
                      child: const Text('Register as Client'),
                    ),
                  if (widget.role != 'client') const SizedBox(height: 8),
                  if (widget.role != 'employee')
                    OutlinedButton(
                      onPressed: () => context.go('/register?role=employee'),
                      child: const Text('Register as Employee'),
                    ),
                  if (widget.role != 'employee') const SizedBox(height: 8),
                  if (widget.role != 'admin')
                    OutlinedButton(
                      onPressed: () => context.go('/register?role=admin'),
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
