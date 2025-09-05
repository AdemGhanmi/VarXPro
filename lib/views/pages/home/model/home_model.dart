class Referee {
  final String id;
  final String confed;
  final String country;
  final String gender;
  final String name;
  final List<String> roles;
  final int since;
  final dynamic year;

  Referee({
    required this.id,
    required this.confed,
    required this.country,
    required this.gender,
    required this.name,
    required this.roles,
    required this.since,
    required this.year,
  });

  factory Referee.fromJson(Map<String, dynamic> json) {
    return Referee(
      id: json['_id'],
      confed: json['confed'],
      country: json['country'],
      gender: json['gender'],
      name: json['name'],
      roles: List<String>.from(json['roles']),
      since: json['since'],
      year: json['year'],
    );
  }
}