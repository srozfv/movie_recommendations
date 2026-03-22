import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/movie.dart';
import '../../home/widgets/movie_card.dart';
import '../bloc/onboarding_bloc.dart';

class RecommendationPreviewWidget extends StatelessWidget {
  final List<Movie> recommendations;

  const RecommendationPreviewWidget({super.key, required this.recommendations});

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Не удалось загрузить рекомендации'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<OnboardingBloc>().add(CompleteOnboarding());
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
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              final movie = recommendations[index];
              return MovieCard(
                movie: movie,
                onTap: () => context.push('/movie/${movie.id}'),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () {
              context.read<OnboardingBloc>().add(CompleteOnboarding());
            },
            child: const Text('Перейти к просмотру'),
          ),
        ),
      ],
    );
  }
}