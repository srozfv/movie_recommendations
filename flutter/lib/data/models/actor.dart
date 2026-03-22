class Actor {
  final int id;
  final int? tmdbId;
  final String name;
  final String? profilePath;
  final String? biography;
  final DateTime? birthday;
  final DateTime? deathday;
  final String? placeOfBirth;
  final int? gender; // 0-unknown, 1-female, 2-male

  Actor({
    required this.id,
    this.tmdbId,
    required this.name,
    this.profilePath,
    this.biography,
    this.birthday,
    this.deathday,
    this.placeOfBirth,
    this.gender,
  });

  factory Actor.fromJson(Map<String, dynamic> json) {
    return Actor(
      id: json['id'],
      tmdbId: json['tmdb_id'],
      name: json['name'],
      profilePath: json['profile_path'],
      biography: json['biography'],
      birthday: json['birthday'] != null ? DateTime.parse(json['birthday']) : null,
      deathday: json['deathday'] != null ? DateTime.parse(json['deathday']) : null,
      placeOfBirth: json['place_of_birth'],
      gender: json['gender'],
    );
  }
}

class ActorWithRole extends Actor {
  final String? character;
  final int? castOrder;
  final bool? isLead;

  ActorWithRole({
    required super.id,
    super.tmdbId,
    required super.name,
    super.profilePath,
    super.biography,
    super.birthday,
    super.deathday,
    super.placeOfBirth,
    super.gender,
    this.character,
    this.castOrder,
    this.isLead,
  });
}