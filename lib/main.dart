import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mi_gym_flutter/providers/user_session.dart';
import 'package:mi_gym_flutter/screens/auth/login_page.dart';
import 'package:mi_gym_flutter/config/app_config.dart';
import 'package:mi_gym_flutter/theme/app_theme.dart';
import 'package:mi_gym_flutter/services/supabase_service.dart';

import 'package:mi_gym_flutter/data/repositories/auth_repository_impl.dart';
import 'package:mi_gym_flutter/data/repositories/class_repository_impl.dart';
import 'package:mi_gym_flutter/data/repositories/booking_repository_impl.dart';
import 'package:mi_gym_flutter/domain/repositories/auth_repository.dart';
import 'package:mi_gym_flutter/domain/repositories/class_repository.dart';
import 'package:mi_gym_flutter/domain/repositories/booking_repository.dart';
import 'package:mi_gym_flutter/domain/usecases/login_usecase.dart';
import 'package:mi_gym_flutter/domain/usecases/get_schedules_usecase.dart';
import 'package:mi_gym_flutter/domain/usecases/get_categories_usecase.dart';
import 'package:mi_gym_flutter/domain/usecases/get_home_data_usecase.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseService.initialize();
  await AppConfig.initialize();

  // Auth
  final authRepository = AuthRepositoryImpl();
  final loginUseCase = LoginUseCaseImpl(authRepository);

  // Classes & Bookings
  final supabaseClient = SupabaseService.client;
  final classRepository = ClassRepositoryImpl(supabaseClient);
  final bookingRepository = BookingRepositoryImpl(supabaseClient);
  final getSchedulesUseCase = GetSchedulesUseCase(classRepository);
  final getCategoriesUseCase = GetCategoriesUseCase(classRepository);
  final getHomeDataUseCase = GetHomeDataUseCase(authRepository, classRepository, bookingRepository);

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: authRepository),
        Provider<LoginUseCase>.value(value: loginUseCase),
        Provider<ClassRepository>.value(value: classRepository),
        Provider<BookingRepository>.value(value: bookingRepository),
        Provider<GetSchedulesUseCase>.value(value: getSchedulesUseCase),
        Provider<GetCategoriesUseCase>.value(value: getCategoriesUseCase),
        Provider<GetHomeDataUseCase>.value(value: getHomeDataUseCase),
        ChangeNotifierProvider(create: (_) => UserSession()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      locale: AppConfig.defaultLocale,
      supportedLocales: AppConfig.supportedLocales,
      localizationsDelegates: AppConfig.localizationsDelegates,
      theme: AppTheme.darkTheme,
      home: const LoginPage(),
    );
  }
}
