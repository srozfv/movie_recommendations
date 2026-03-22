part of 'movie_detail_bloc.dart';

abstract class MovieDetailState {}

class MovieDetailInitial extends MovieDetailState {}

class MovieDetailLoading extends MovieDetailState {}

class MovieDetailLoaded extends MovieDetailState {
  final Movie movie;
  final List<ActorWithRole> cast;
  MovieDetailLoaded(this.movie, this.cast);
}

class MovieDetailError extends MovieDetailState {
  final String message;
  MovieDetailError(this.message);
}