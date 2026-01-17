import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database_helper.dart';
import '../data/repositories/account_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../services/session_service.dart';
import '../../features/accounts/bloc/account_bloc.dart';
import '../../features/transactions/bloc/transaction_bloc.dart';
import '../../features/auth/bloc/auth_bloc.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  // Database Helper
  getIt.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper.instance);

  // Services
  getIt.registerLazySingleton<SessionService>(() => SessionService(getIt<SharedPreferences>()));

  // Repositories (singleton porque usan la misma instancia de DatabaseHelper)
  getIt.registerLazySingleton<AccountRepository>(() => AccountRepository());
  getIt.registerLazySingleton<CategoryRepository>(() => CategoryRepository());
  getIt.registerLazySingleton<TransactionRepository>(() => TransactionRepository());
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepository());

  // BLoCs (factory para crear nuevas instancias)
  getIt.registerFactory<AccountBloc>(() => AccountBloc(getIt<AccountRepository>()));
  getIt.registerFactory<TransactionBloc>(() => TransactionBloc(getIt<TransactionRepository>()));
  getIt.registerLazySingleton<AuthBloc>(() => AuthBloc(
        authRepository: getIt<AuthRepository>(),
        sessionService: getIt<SessionService>(),
      ));
}
