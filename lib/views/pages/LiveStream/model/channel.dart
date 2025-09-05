class Channel {
  final String id;
  final String name;
  final String categoryId;
  final String streamIcon;

  Channel({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.streamIcon,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['stream_id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown Channel',
      categoryId: json['category_id']?.toString() ?? '',
      streamIcon: json['stream_icon'] ?? '',
    );
  }
}
