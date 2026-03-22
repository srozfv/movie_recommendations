part of 'search_bloc.dart';

abstract class SearchEvent {}

class SearchMovies extends SearchEvent {
  final String query;
  SearchMovies(this.query);
}