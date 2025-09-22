class Referee {
  final String confed;
  final String country;
  late final Details? details;
  final String gender;
  final int lastEnriched;
  final String name;
  final List<String> roles;
  final int since;
  final dynamic year;

  Referee({
    required this.confed,
    required this.country,
    this.details,
    required this.gender,
    required this.lastEnriched,
    required this.name,
    required this.roles,
    required this.since,
    this.year,
  });

  factory Referee.fromJson(Map<String, dynamic> json) {
    return Referee(
      confed: json['confed'] ?? '',
      country: json['country'] ?? '',
      details: json['details'] != null ? Details.fromJson(json['details']) : null,
      gender: json['gender'] ?? '',
      lastEnriched: json['last_enriched'] ?? 0,
      name: json['name'] ?? '',
      roles: json['roles'] != null ? List<String>.from(json['roles']) : [],
      since: json['since'] ?? 0,
      year: json['year'],
    );
  }
}

class Details {
  final WorldFootball? worldfootball;

  Details({this.worldfootball});

  factory Details.fromJson(Map<String, dynamic> json) {
    return Details(
      worldfootball: json['worldfootball'] != null
          ? WorldFootball.fromJson(json['worldfootball'])
          : null,
    );
  }
}

class WorldFootball {
  final List<Competition> competitions;
  final OverallTotals overallTotals;
  final Profile profile;
  final int scrapedAt;
  final Source source;

  WorldFootball({
    required this.competitions,
    required this.overallTotals,
    required this.profile,
    required this.scrapedAt,
    required this.source,
  });

  factory WorldFootball.fromJson(Map<String, dynamic> json) {
    if (json['error'] != null) {
      // Handle not_found case
      throw Exception('Referee details not found');
    }
    final List<dynamic> compsJson = json['competitions'] ?? [];
    return WorldFootball(
      competitions: compsJson.map((c) => Competition.fromJson(c)).toList(),
      overallTotals: OverallTotals.fromJson(json['overall_totals']),
      profile: Profile.fromJson(json['profile']),
      scrapedAt: json['scraped_at'] ?? 0,
      source: Source.fromJson(json['source']),
    );
  }
}

class Competition {
  final String name;
  final Totals totals;

  Competition({required this.name, required this.totals});

  factory Competition.fromJson(Map<String, dynamic> json) {
    return Competition(
      name: json['competition'] ?? '',
      totals: Totals.fromJson(json['totals']),
    );
  }
}

class Totals {
  final int matches;
  final int red;
  final int secondYellow;
  final int yellow;
  final double yellowPerGame;

  Totals({
    required this.matches,
    required this.red,
    required this.secondYellow,
    required this.yellow,
    required this.yellowPerGame,
  });

  factory Totals.fromJson(Map<String, dynamic> json) {
    return Totals(
      matches: json['matches'] ?? 0,
      red: json['red'] ?? 0,
      secondYellow: json['second_yellow'] ?? 0,
      yellow: json['yellow'] ?? 0,
      yellowPerGame: (json['yellow_per_game'] ?? 0).toDouble(),
    );
  }
}

class OverallTotals {
  final int matches;
  final int red;
  final int secondYellow;
  final int yellow;
  final double yellowPerGame;

  OverallTotals({
    required this.matches,
    required this.red,
    required this.secondYellow,
    required this.yellow,
    required this.yellowPerGame,
  });

  factory OverallTotals.fromJson(Map<String, dynamic> json) {
    return OverallTotals(
      matches: json['matches'] ?? 0,
      red: json['red'] ?? 0,
      secondYellow: json['second_yellow'] ?? 0,
      yellow: json['yellow'] ?? 0,
      yellowPerGame: (json['yellow_per_game'] ?? 0).toDouble(),
    );
  }
}

class Profile {
  final String? born;
  final String completeName;
  final String name;
  final String nationality;
  final String? placeOfBirth;

  Profile({
    this.born,
    required this.completeName,
    required this.name,
    required this.nationality,
    this.placeOfBirth,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      born: json['born'],
      completeName: json['complete_name'] ?? '',
      name: json['name'] ?? '',
      nationality: json['nationality'] ?? '',
      placeOfBirth: json['place_of_birth'],
    );
  }
}

class Source {
  final String site;
  final String url;

  Source({required this.site, required this.url});

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      site: json['site'] ?? '',
      url: json['url'] ?? '',
    );
  }
}