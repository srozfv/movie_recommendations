import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:movie_recommendations/core/router/app_router.dart';
import 'data/services/api_client.dart';
import 'core/services/token_service.dart';
import 'presentation/auth/bloc/auth_bloc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Для эмулятора Android используйте 10.0.2.2
    final apiClient = ApiClient(baseUrl: 'http://10.0.2.2:8000/api/v1');
    final tokenService = TokenService();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: apiClient),
        RepositoryProvider.value(value: tokenService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(
              apiClient: context.read<ApiClient>(),
              tokenService: context.read<TokenService>(),
            )..add(AppStarted()),
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return MaterialApp.router(
              title: 'Кинотеатр',
              theme: ThemeData(
                primarySwatch: Colors.blue,
                useMaterial3: true,
              ),
              routerConfig: router,
            );
          },
        ),
      ),
    );
  }
}