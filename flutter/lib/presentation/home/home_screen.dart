import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'bloc/home_bloc.dart';
import 'widgets/movie_card.dart';
import '../../data/services/api_client.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc(
        apiClient: context.read<ApiClient>(),
      )..add(FetchPopularMovies()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Популярные фильмы'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => context.push('/profile'),
              tooltip: 'Профиль',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            context.read<HomeBloc>().add(RefreshMovies());
          },
          child: BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              if (state is HomeLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is HomeLoaded) {
                if (state.movies.isEmpty) {
                  return const Center(child: Text('Нет фильмов'));
                }
                
                return NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollEndNotification &&
                        notification.metrics.extentAfter < 200 &&
                        state.hasMore) {
                      context.read<HomeBloc>().add(LoadMoreMovies());
                    }
                    return false;
                  },
                  child: GridView.builder(
                    padding: EdgeInsets.all(16.w),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 16.w,
                      mainAxisSpacing: 16.h,
                    ),
                    itemCount: state.movies.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.movies.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final movie = state.movies[index];
                      return MovieCard(
                        movie: movie,
                        onTap: () => context.push('/movie/${movie.id}'),
                      );
                    },
                  ),
                );
              } else if (state is HomeLoadingMore) {
                // Показываем существующий список и индикатор загрузки внизу
                if (state is HomeLoaded) {
                  // этот кейс обрабатывается выше
                }
                return const Center(child: CircularProgressIndicator());
              } else if (state is HomeError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Ошибка: ${state.message}'),
                      ElevatedButton(
                        onPressed: () {
                          context.read<HomeBloc>().add(FetchPopularMovies());
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