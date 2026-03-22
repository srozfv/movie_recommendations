part of 'home_bloc.dart';

abstract class HomeEvent {}

class FetchPopularMovies extends HomeEvent {}

class LoadMoreMovies extends HomeEvent {}

class RefreshMovies extends HomeEvent {}