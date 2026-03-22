import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/genre.dart';
import '../bloc/onboarding_bloc.dart';

class GenreSelectionWidget extends StatelessWidget {
  final List<Genre> genres;
  final List<int> selectedIds;

  const GenreSelectionWidget({
    super.key,
    required this.genres,
    required this.selectedIds,
  });

  void _showSkipDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Пропустить выбор жанров?'),
        content: const Text(
          'Если вы пропустите этот шаг, рекомендации будут основаны только на популярных фильмах. Это может ухудшить качество подборки. Продолжить?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<OnboardingBloc>().add(SkipGenres());
            },
            child: const Text('Пропустить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: genres.map((genre) {
                final isSelected = selectedIds.contains(genre.id);
                return FilterChip(
                  label: Text(genre.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    final newIds = List<int>.from(selectedIds);
                    if (selected) {
                      newIds.add(genre.id);
                    } else {
                      newIds.remove(genre.id);
                    }
                    // Обновляем состояние через BLoC
                    context.read<OnboardingBloc>().add(SelectGenres(newIds));
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: Colors.blue[100],
                  checkmarkColor: Colors.blue,
                );
              }).toList(),
            ),
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
                onPressed: selectedIds.isEmpty
                    ? null
                    : () {
                        context.read<OnboardingBloc>().add(SelectGenres(selectedIds));
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