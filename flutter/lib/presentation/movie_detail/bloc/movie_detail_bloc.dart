import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/movie.dart';
import '../../../data/models/actor.dart';
import '../../../data/services/api_client.dart';

part 'movie_detail_event.dart';
part 'movie_detail_state.dart';

class MovieDetailBloc extends Bloc<MovieDetailEvent, MovieDetailState> {
  final ApiClient apiClient;

  MovieDetailBloc({required this.apiClient}) : super(MovieDetailInitial()) {
    on<FetchMovieDetail>(_onFetchMovieDetail);
  }

  Future<void> _onFetchMovieDetail(
    FetchMovieDetail event,
    Emitter<MovieDetailState> emit,
  ) async {
    emit(MovieDetailLoading());
    try {
      final movie = await apiClient.getMovieDetail(event.movieId);
      // Пока список актёров пуст, позже добавим
      emit(MovieDetailLoaded(movie, []));
    } catch (e) {
      emit(MovieDetailError(e.toString()));
    }
  }
}