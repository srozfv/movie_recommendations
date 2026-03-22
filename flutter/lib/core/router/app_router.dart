import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../presentation/home/home_screen.dart';
import '../../presentation/movie_detail/movie_detail_screen.dart';
import '../../presentation/search/search_screen.dart';
import '../../presentation/onboarding/onboarding_screen.dart';
import '../../presentation/auth/login_screen.dart';
import '../../presentation/auth/register_screen.dart';
import '../../presentation/profile/profile_screen.dart';  // добавьте импорт
import '../../core/services/token_service.dart';

final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final tokenService = TokenService();
    final isAuthenticated = await tokenService.hasToken();

    if (!isAuthenticated && state.matchedLocation != '/login' && state.matchedLocation != '/register') {
      return '/login';
    }

// В redirect
    if (isAuthenticated) {
      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
      print('🔍 Онбординг пройден: $onboardingCompleted'); // добавим отладку
      if (!onboardingCompleted && state.matchedLocation != '/onboarding') {
        return '/onboarding';
      }
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/movie/:id',
      name: 'movieDetail',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return MovieDetailScreen(movieId: id);
      },
    ),
    GoRoute(
      path: '/search',
      name: 'search',
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    // Добавьте маршрут для профиля
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Страница не найдена: ${state.uri}'),
    ),
  ),
);