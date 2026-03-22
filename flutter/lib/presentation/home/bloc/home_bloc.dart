import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/movie.dart';
import '../../../data/services/api_client.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ApiClient apiClient;
  int _currentPage = 1;
  bool _hasMore = true;
  final List<Movie> _movies = [];

  HomeBloc({required this.apiClient}) : super(HomeInitial()) {
    on<FetchPopularMovies>(_onFetchPopularMovies);
    on<LoadMoreMovies>(_onLoadMoreMovies);
    on<RefreshMovies>(_onRefreshMovies);
  }

  Future<void> _onFetchPopularMovies(
    FetchPopularMovies event,
    Emitter<HomeState> emit,
  ) async {
    _currentPage = 1;
    _hasMore = true;
    _movies.clear();
    emit(HomeLoading());
    
    try {
      final movies = await apiClient.getPopularMovies(page: _currentPage);
      _movies.addAll(movies);
      _hasMore = movies.length == 20; // если получили меньше 20, значит больше нет
      emit(HomeLoaded(List.from(_movies), hasMore: _hasMore));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _onLoadMoreMovies(
    LoadMoreMovies event,
    Emitter<HomeState> emit,
  ) async {
    if (!_hasMore) return;
    
    _currentPage++;
    emit(HomeLoadingMore());
    
    try {
      final movies = await apiClient.getPopularMovies(page: _currentPage);
      _movies.addAll(movies);
      _hasMore = movies.length == 20;
      emit(HomeLoaded(List.from(_movies), hasMore: _hasMore));
    } catch (e) {
      _currentPage--;
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _onRefreshMovies(
    RefreshMovies event,
    Emitter<HomeState> emit,
  ) async {
    _currentPage = 1;
    _hasMore = true;
    _movies.clear();
    
    try {
      final movies = await apiClient.getPopularMovies(page: _currentPage);
      _movies.addAll(movies);
      _hasMore = movies.length == 20;
      emit(HomeLoaded(List.from(_movies), hasMore: _hasMore));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }
}