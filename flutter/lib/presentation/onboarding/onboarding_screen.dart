import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'bloc/onboarding_bloc.dart';
import 'widgets/genre_selection.dart';
import 'widgets/movie_selection.dart';
import 'widgets/recommendation_preview.dart';
import '../../data/services/api_client.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OnboardingBloc(
        apiClient: context.read<ApiClient>(),
      )..add(LoadOnboarding()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Настройка рекомендаций'),
        ),
        body: BlocListener<OnboardingBloc, OnboardingState>(
          listenWhen: (previous, current) => current is OnboardingCompleted,
          listener: (context, state) {
            context.go('/');
          },
          child: BlocBuilder<OnboardingBloc, OnboardingState>(
            builder: (context, state) {
              if (state is OnboardingLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is GenresLoaded) {
                return GenreSelectionWidget(
                  genres: state.genres,
                  selectedIds: state.selectedGenreIds,
                );
              } else if (state is MoviesForSelectionLoaded) {
                return MovieSelectionWidget(
                  movies: state.movies,
                  selectedRatings: state.selectedRatings,
                );
              } else if (state is RecommendationsLoaded) {
                return RecommendationPreviewWidget(
                  recommendations: state.recommendations,
                );
              } else if (state is OnboardingError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Ошибка: ${state.message}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<OnboardingBloc>().add(LoadOnboarding());
                        },
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}