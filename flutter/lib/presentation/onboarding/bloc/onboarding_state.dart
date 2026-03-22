part of 'onboarding_bloc.dart';

abstract class OnboardingState {}

class OnboardingInitial extends OnboardingState {}

class OnboardingLoading extends OnboardingState {}

class GenresLoaded extends OnboardingState {
  final List<Genre> genres;
  final List<int> selectedGenreIds;
  GenresLoaded({required this.genres, required this.selectedGenreIds});
}

class MoviesForSelectionLoaded extends OnboardingState {
  final List<Movie> movies;
  final Map<int, int> selectedRatings; // movieId -> rating
  MoviesForSelectionLoaded({required this.movies, required this.selectedRatings});
}

class RecommendationsLoaded extends OnboardingState {
  final List<Movie> recommendations;
  RecommendationsLoaded(this.recommendations);
}

class OnboardingCompleted extends OnboardingState {}

class OnboardingError extends OnboardingState {
  final String message;
  OnboardingError(this.message);
}