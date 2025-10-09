// lib/models/referee.dart
class Referee {
  final String id;
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
    required this.id,
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
      id:
          json['id']?.toString() ??
          json['_id']?.toString() ??
          '', // Support both
      confed: json['confed'] ?? '',
      country: json['country'] ?? '',
      details: json['details'] != null
          ? Details.fromJson(json['details'])
          : null,
      gender: json['gender'] ?? '',
      lastEnriched: (json['last_enriched'] ?? 0).toInt(),
      name: json['name'] ?? '',
      roles: json['roles'] != null ? List<String>.from(json['roles']) : [],
      since: (json['since'] ?? 0).toInt(),
      year: json['year'],
    );
  }

  // Added for caching (serialize back to JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'confed': confed,
      'country': country,
      'details': details?.toJson(),
      'gender': gender,
      'last_enriched': lastEnriched,
      'name': name,
      'roles': roles,
      'since': since,
      'year': year,
    };
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

  Map<String, dynamic> toJson() {
    return {'worldfootball': worldfootball?.toJson()};
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
      // Removed print to stop console spam; fallback silently
      return WorldFootball(
        competitions: [],
        overallTotals: OverallTotals(
          matches: 0,
          red: 0,
          secondYellow: 0,
          yellow: 0,
          yellowPerGame: 0.0,
        ),
        profile: Profile(
          completeName: 'Not Found',
          name: 'N/A',
          nationality: '',
          born: null,
          placeOfBirth: null,
        ),
        scrapedAt: 0,
        source: Source(site: '', url: ''),
      );
    }
    final List<dynamic> compsJson = json['competitions'] ?? [];
    return WorldFootball(
      competitions: compsJson.map((c) => Competition.fromJson(c)).toList(),
      overallTotals: OverallTotals.fromJson(json['overall_totals']),
      profile: Profile.fromJson(json['profile']),
      scrapedAt: (json['scraped_at'] ?? 0).toInt(),
      source: Source.fromJson(json['source']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'competitions': competitions.map((c) => c.toJson()).toList(),
      'overall_totals': overallTotals.toJson(),
      'profile': profile.toJson(),
      'scraped_at': scrapedAt,
      'source': source.toJson(),
    };
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

  Map<String, dynamic> toJson() {
    return {'competition': name, 'totals': totals.toJson()};
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
      matches: (json['matches'] ?? 0).toInt(),
      red: (json['red'] ?? 0).toInt(),
      secondYellow: (json['second_yellow'] ?? 0).toInt(),
      yellow: (json['yellow'] ?? 0).toInt(),
      yellowPerGame: (json['yellow_per_game'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matches': matches,
      'red': red,
      'second_yellow': secondYellow,
      'yellow': yellow,
      'yellow_per_game': yellowPerGame,
    };
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
      matches: (json['matches'] ?? 0).toInt(),
      red: (json['red'] ?? 0).toInt(),
      secondYellow: (json['second_yellow'] ?? 0).toInt(),
      yellow: (json['yellow'] ?? 0).toInt(),
      yellowPerGame: (json['yellow_per_game'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matches': matches,
      'red': red,
      'second_yellow': secondYellow,
      'yellow': yellow,
      'yellow_per_game': yellowPerGame,
    };
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

  Map<String, dynamic> toJson() {
    return {
      'born': born,
      'complete_name': completeName,
      'name': name,
      'nationality': nationality,
      'place_of_birth': placeOfBirth,
    };
  }
}

class Source {
  final String site;
  final String url;

  Source({required this.site, required this.url});

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(site: json['site'] ?? '', url: json['url'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'site': site, 'url': url};
  }
}
//