import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'auth/presentation/bloc/auth_bloc.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          if (state.user.role == 'client') {
            context.go('/client');
          } else if (state.user.role == 'employee') {
            context.go('/employee');
          } else if (state.user.role == 'admin') {
            context.go('/admin');
          } else {
            context.go('/login');
          }
        } else if (state is AuthUnauthenticated) {
          context.go('/login');
        }
      },
      child: const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
