import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/dashboard/presentation/client_dashboard.dart';
import '../features/dashboard/presentation/employee_dashboard.dart';
import '../features/dashboard/presentation/admin_dashboard.dart';
import '../features/tickets/presentation/create_ticket_screen.dart';
import '../features/splash_screen.dart';

import '../features/dashboard/presentation/notification_screen.dart';
import '../features/tickets/presentation/ticket_detail_screen.dart';
import '../features/tickets/domain/ticket_model.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
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
        path: '/create-ticket',
        builder: (context, state) => const CreateTicketScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationScreen(),
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
