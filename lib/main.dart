import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/di/service_locator.dart';
import 'core/services/supabase_service.dart';
import 'core/config/supabase_config.dart';
import 'features/accounts/bloc/account_bloc.dart';
import 'features/accounts/bloc/account_event.dart';
import 'features/transactions/bloc/transaction_bloc.dart';
import 'features/transactions/bloc/transaction_event.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Supabase (backend en la nube)
  if (SupabaseConfig.isConfigured) {
    try {
      await SupabaseService.initialize(
        supabaseUrl: SupabaseConfig.supabaseUrl,
        supabaseAnonKey: SupabaseConfig.supabaseAnonKey,
      );
      print('✅ Supabase inicializado correctamente');
    } catch (e) {
      print('❌ Error al inicializar Supabase: $e');
    }
  } else {
    print('⚠️ Supabase NO configurado. Agrega tus credenciales en supabase_config.dart');
  }
  
  // Configurar service locator (repositories)
  await setupServiceLocator();
  
  // Inicializar formateo de fechas en español
  await initializeDateFormatting('es');
  
  // Configurar orientación (solo portrait)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Configurar estilo de la barra de estado
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<AuthBloc>()
            ..add(const AuthCheckRequested()),
        ),
        BlocProvider(
          create: (context) => getIt<AccountBloc>()
            ..add(const LoadAccounts()),
        ),
        BlocProvider(
          create: (context) => getIt<TransactionBloc>()
            ..add(const LoadRecentTransactions(limit: 20)),
        ),
      ],
      child: MaterialApp.router(
        title: 'MiChaucherita',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
