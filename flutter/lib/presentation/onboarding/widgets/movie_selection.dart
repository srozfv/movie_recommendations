import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/movie.dart';
import '../bloc/onboarding_bloc.dart';

class MovieSelectionWidget extends StatefulWidget {
  final List<Movie> movies;
  final Map<int, int> selectedRatings;

  const MovieSelectionWidget({
    super.key,
    required this.movies,
    required this.selectedRatings,
  });

  @override
  State<MovieSelectionWidget> createState() => _MovieSelectionWidgetState();
}

class _MovieSelectionWidgetState extends State<MovieSelectionWidget> {
  late Map<int, int> _ratings;

  @override
  void initState() {
    super.initState();
    _ratings = Map.from(widget.selectedRatings);
  }

  void _showSkipDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Пропустить выбор фильмов?'),
        content: const Text(
          'Если вы пропустите этот шаг, рекомендации будут основаны только на выбранных жанрах. Это может ухудшить качество подборки. Продолжить?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<OnboardingBloc>().add(SkipMovies());
            },
            child: const Text('Пропустить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.movies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Нет фильмов для выбора'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<OnboardingBloc>().add(SkipMovies());
              },
              child: const Text('Пропустить'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: widget.movies.length,
            itemBuilder: (context, index) {
              final movie = widget.movies[index];
              final rating = _ratings[movie.id] ?? 0;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Оценка: '),
                          ...List.generate(10, (i) {
                            return IconButton(
                              onPressed: () {
                                setState(() {
                                  if (rating == i + 1) {
                                    _ratings.remove(movie.id);
                                  } else {
                                    _ratings[movie.id] = i + 1;
                                  }
                                });
                              },
                              icon: Icon(
                                i < rating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                              ),
                              iconSize: 24,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton(
                onPressed: () => _showSkipDialog(context),
                child: const Text('Пропустить'),
              ),
              ElevatedButton(
                onPressed: _ratings.isEmpty
                    ? null
                    : () {
                        context
                            .read<OnboardingBloc>()
                            .add(SelectMoviesWithRatings(_ratings));
                      },
                child: const Text('Далее'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}