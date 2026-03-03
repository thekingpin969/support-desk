import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/reset_password_screen.dart';
import '../features/dashboard/presentation/client_dashboard.dart';
import '../features/dashboard/presentation/employee_dashboard.dart';
import '../features/dashboard/presentation/admin_dashboard.dart';
import '../features/dashboard/presentation/employee_management_screen.dart';
import '../features/dashboard/presentation/sla_config_screen.dart';
import '../features/dashboard/presentation/category_management_screen.dart';
import '../features/dashboard/presentation/analytics_screen.dart';
import '../features/dashboard/presentation/admin_tickets_screen.dart';
import '../features/dashboard/presentation/employee_detail_screen.dart';
import '../features/tickets/presentation/create_ticket_screen.dart';
import '../features/splash_screen.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/dashboard/presentation/bloc/notification_bloc.dart';
import 'di.dart';

import '../features/dashboard/presentation/notification_screen.dart';
import '../features/tickets/presentation/my_tickets_screen.dart';
import '../features/tickets/presentation/ticket_detail_screen.dart';
import '../features/tickets/domain/ticket_model.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final role = state.uri.queryParameters['role'] ?? 'client';
          return LoginScreen(role: role);
        },
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) {
          final role = state.uri.queryParameters['role'] ?? 'client';
          return RegisterScreen(role: role);
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/client',
        builder: (context, state) => const ClientDashboard(),
      ),
      GoRoute(
        path: '/employee',
        builder: (context, state) => const EmployeeDashboard(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/tickets/create',
        builder: (context, state) => const CreateTicketScreen(),
      ),
      GoRoute(
        path: '/admin/employees',
        builder: (context, state) => const EmployeeManagementScreen(),
      ),
      GoRoute(
        path: '/admin/sla',
        builder: (context, state) => const SlaConfigScreen(),
      ),
      GoRoute(
        path: '/admin/categories',
        builder: (context, state) => const CategoryManagementScreen(),
      ),
      GoRoute(
        path: '/admin/analytics',
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: '/admin/tickets',
        builder: (context, state) {
          final filter = state.uri.queryParameters['filter'];
          return AdminTicketsScreen(initialFilter: filter);
        },
      ),
      GoRoute(
        path: '/admin/employee-detail',
        builder: (context, state) {
          final employee = state.extra as Map<String, dynamic>;
          return EmployeeDetailScreen(employee: employee);
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => BlocProvider(
          create: (_) => sl<NotificationBloc>(),
          child: const NotificationScreen(),
        ),
      ),
      GoRoute(
        path: '/my-tickets',
        builder: (context, state) => const MyTicketsScreen(),
      ),
      GoRoute(
        path: '/ticket-detail',
        builder: (context, state) {
          final ticket = state.extra as TicketModel;
          return TicketDetailScreen(ticket: ticket);
        },
      ),
    ],
  );
}
