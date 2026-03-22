import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/movie.dart';
import '../../../data/models/genre.dart';
import '../../../data/services/api_client.dart';

part 'onboarding_event.dart';
part 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final ApiClient apiClient;

  OnboardingBloc({required this.apiClient}) : super(OnboardingInitial()) {
    on<LoadOnboarding>(_onLoadOnboarding);
    on<SelectGenres>(_onSelectGenres);
    on<SkipGenres>(_onSkipGenres);
    on<SelectMoviesWithRatings>(_onSelectMoviesWithRatings);
    on<SkipMovies>(_onSkipMovies);
    on<CompleteOnboarding>(_onCompleteOnboarding);
  }

  Future<void> _onLoadOnboarding(
    LoadOnboarding event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(OnboardingLoading());
    try {
      final genres = await apiClient.getGenres();
      emit(GenresLoaded(genres: genres, selectedGenreIds: []));
    } catch (e) {
      emit(OnboardingError(e.toString()));
    }
  }

  Future<void> _onSelectGenres(
    SelectGenres event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(OnboardingLoading());
    try {
      final movies = await apiClient.getMoviesByGenres(event.genreIds);
      emit(MoviesForSelectionLoaded(
        movies: movies,
        selectedRatings: {},
      ));
    } catch (e) {
      emit(OnboardingError(e.toString()));
    }
  }

  Future<void> _onSkipGenres(
    SkipGenres event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(OnboardingLoading());
    try {
      final movies = await apiClient.getPopularMovies();
      emit(MoviesForSelectionLoaded(
        movies: movies,
        selectedRatings: {},
      ));
    } catch (e) {
      emit(OnboardingError(e.toString()));
    }
  }

  Future<void> _onSelectMoviesWithRatings(
    SelectMoviesWithRatings event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(OnboardingLoading());
    try {
      // Получаем выбранные жанры из текущего состояния (если они были)
      List<int> selectedGenreIds = [];
      if (state is GenresLoaded) {
        selectedGenreIds = (state as GenresLoaded).selectedGenreIds;
      }
      
      final recommendations = await apiClient.getRecommendations(
        selectedGenreIds,
        event.ratings,
      );
      emit(RecommendationsLoaded(recommendations));
    } catch (e) {
      emit(OnboardingError(e.toString()));
    }
  }

  Future<void> _onSkipMovies(
    SkipMovies event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(OnboardingLoading());
    try {
      final recommendations = await apiClient.getPopularMovies();
      emit(RecommendationsLoaded(recommendations));
    } catch (e) {
      emit(OnboardingError(e.toString()));
    }
  }

  Future<void> _onCompleteOnboarding(
    CompleteOnboarding event,
    Emitter<OnboardingState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    emit(OnboardingCompleted());
  }
}