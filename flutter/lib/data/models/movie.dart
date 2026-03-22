class Movie {
  final int id;
  final int? tmdbId;
  final String title;
  final String? originalTitle;
  final String? description;
  final int? releaseYear;
  final DateTime? releaseDate;
  final String? posterUrl;          // поле для постера
  final String? backdropPath;       // поле для фонового изображения
  final double? voteAverage;
  final int? voteCount;
  final double? popularity;
  final int? runtime;
  final int? budget;
  final int? revenue;
  final String? imdbId;
  final String? status;
  final String? tagline;
  final String? tsv;
  final DateTime? createdAt;

  Movie({
    required this.id,
    this.tmdbId,
    required this.title,
    this.originalTitle,
    this.description,
    this.releaseYear,
    this.releaseDate,
    this.posterUrl,
    this.backdropPath,
    this.voteAverage,
    this.voteCount,
    this.popularity,
    this.runtime,
    this.budget,
    this.revenue,
    this.imdbId,
    this.status,
    this.tagline,
    this.tsv,
    this.createdAt,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],
      tmdbId: json['tmdb_id'],
      title: json['title'],
      originalTitle: json['original_title'],
      description: json['description'],
      releaseYear: json['release_year'],
      releaseDate: json['release_date'] != null ? DateTime.parse(json['release_date']) : null,
      posterUrl: json['poster_url'],
      backdropPath: json['backdrop_path'],
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      voteCount: json['vote_count'],
      popularity: (json['popularity'] as num?)?.toDouble(),
      runtime: json['runtime'],
      budget: json['budget'],
      revenue: json['revenue'],
      imdbId: json['imdb_id'],
      status: json['status'],
      tagline: json['tagline'],
      tsv: json['tsv'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }
}