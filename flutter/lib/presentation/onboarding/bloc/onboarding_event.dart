part of 'onboarding_bloc.dart';

abstract class OnboardingEvent {}

class LoadOnboarding extends OnboardingEvent {}

class SelectGenres extends OnboardingEvent {
  final List<int> genreIds;
  SelectGenres(this.genreIds);
}

class SkipGenres extends OnboardingEvent {}

class SelectMoviesWithRatings extends OnboardingEvent {
  final Map<int, int> ratings; // movieId -> rating
  SelectMoviesWithRatings(this.ratings);
}

class SkipMovies extends OnboardingEvent {}

class CompleteOnboarding extends OnboardingEvent {}