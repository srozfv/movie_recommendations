import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/movie.dart';
import '../../../data/services/api_client.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final ApiClient apiClient;

  SearchBloc({required this.apiClient}) : super(SearchInitial()) {
    on<SearchMovies>(_onSearchMovies);
  }

  Future<void> _onSearchMovies(
    SearchMovies event,
    Emitter<SearchState> emit,
  ) async {
    if (event.query.isEmpty) {
      emit(SearchInitial());
      return;
    }
    emit(SearchLoading());
    try {
      final movies = await apiClient.searchMovies(event.query);
      emit(SearchLoaded(movies));
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }
}