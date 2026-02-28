import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'api_client.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/tickets/data/ticket_repository.dart';
import '../features/tickets/presentation/bloc/tickets_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Storage
  sl.registerLazySingleton(() => const FlutterSecureStorage());

  // Api Client
  sl.registerLazySingleton(() => ApiClient(storage: sl()));

  // Repositories
  sl.registerLazySingleton(
    () => AuthRepository(apiClient: sl(), storage: sl()),
  );
  sl.registerLazySingleton(() => TicketRepository(apiClient: sl()));

  // Blocs
  sl.registerFactory(() => AuthBloc(repository: sl()));
  sl.registerFactory(() => TicketsBloc(repository: sl()));
}
