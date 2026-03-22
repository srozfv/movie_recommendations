import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'bloc/movie_detail_bloc.dart';
import '../../data/models/movie.dart';
import '../../data/models/actor.dart';
import '../../data/services/api_client.dart';

class MovieDetailScreen extends StatefulWidget {
  final int movieId;

  const MovieDetailScreen({super.key, required this.movieId});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool _isDescriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MovieDetailBloc(
        apiClient: context.read<ApiClient>(),
      )..add(FetchMovieDetail(widget.movieId)),
      child: Scaffold(
        body: BlocBuilder<MovieDetailBloc, MovieDetailState>(
          builder: (context, state) {
            if (state is MovieDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is MovieDetailLoaded) {
              final movie = state.movie;
              final cast = state.cast;
              return CustomScrollView(
                slivers: [
                  _buildAppBar(movie),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildTitleSection(movie),
                        const SizedBox(height: 16),
                        _buildActionButtons(),
                        const SizedBox(height: 24),
                        _buildDescriptionSection(movie),
                        const SizedBox(height: 24),
                        _buildCastSection(cast),
                        const SizedBox(height: 24),
                      ]),
                    ),
                  ),
                ],
              );
            } else if (state is MovieDetailError) {
              return Center(child: Text('Ошибка: ${state.message}'));
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(Movie movie) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(movie.title),
        background: movie.backdropPath != null
            ? CachedNetworkImage(
                imageUrl: 'https://image.tmdb.org/t/p/w500${movie.backdropPath}',
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey),
                errorWidget: (context, url, error) => Container(color: Colors.grey),
              )
            : Container(color: Colors.grey),
      ),
    );
  }

  Widget _buildTitleSection(Movie movie) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          movie.title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (movie.releaseYear != null)
              Chip(label: Text('${movie.releaseYear}'), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
            if (movie.runtime != null)
              Chip(label: Text('${movie.runtime} мин'), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
            if (movie.voteAverage != null)
              Chip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text('${movie.voteAverage}/10'),
                  ],
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (movie.tagline != null && movie.tagline!.isNotEmpty)
          Text(
            movie.tagline!,
            style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey[600]),
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _ActionButton(
          icon: Icons.share,
          label: 'Поделиться',
          onTap: () {
            // TODO: реализовать шаринг
          },
        ),
        _ActionButton(
          icon: Icons.bookmark_border,
          label: 'Буду смотреть',
          onTap: () {
            // TODO: добавить в закладки
          },
        ),
        _ActionButton(
          icon: Icons.star_border,
          label: 'Оценить',
          onTap: () {
            // TODO: открыть диалог оценки
          },
        ),
        _ActionButton(
          icon: Icons.thumb_down_alt_outlined,
          label: 'Неинтересно',
          onTap: () {
            // TODO: отметить как неинтересно
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(Movie movie) {
    if (movie.description == null || movie.description!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Описание',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        AnimatedCrossFade(
          firstChild: Text(
            movie.description!,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          secondChild: Text(movie.description!),
          crossFadeState: _isDescriptionExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _isDescriptionExpanded = !_isDescriptionExpanded;
            });
          },
          child: Text(_isDescriptionExpanded ? 'Скрыть' : 'Показать полностью'),
        ),
      ],
    );
  }

  Widget _buildCastSection(List<ActorWithRole> cast) {
    if (cast.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Актёры',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cast.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final actor = cast[index];
              return Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: actor.profilePath != null
                        ? NetworkImage('https://image.tmdb.org/t/p/w185${actor.profilePath}')
                        : null,
                    child: actor.profilePath == null ? const Icon(Icons.person, size: 40) : null,
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 80,
                    child: Text(
                      actor.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (actor.character != null && actor.character!.isNotEmpty)
                    SizedBox(
                      width: 80,
                      child: Text(
                        actor.character!,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}