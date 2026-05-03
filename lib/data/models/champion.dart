class Champion {
  final int id;
  final String name;
  final String title;
  final List<String> tags;
  final String? blurb;

  Champion({
    required this.id,
    required this.name,
    required this.title,
    required this.tags,
    this.blurb,
  });

  String get iconUrl =>
      'https://ddragon.leagueoflegends.com/cdn/14.1.1/img/champion/$name.png';

  String get splashUrl =>
      'https://ddragon.leagueoflegends.com/cdn/img/champion/splash/${name}_0.jpg';

  String get loadingUrl =>
      'https://ddragon.leagueoflegends.com/cdn/img/champion/loading/${name}_0.jpg';

  factory Champion.fromJson(Map<String, dynamic> json) {
    return Champion(
      id: int.tryParse(json['key'] ?? '0') ?? 0,
      name: json['id'] ?? '',
      title: json['title'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      blurb: json['blurb'],
    );
  }
}

class ChampionMastery {
  final int championId;
  final String championName;
  final int championLevel;
  final int championPoints;
  final DateTime lastPlayTime;

  ChampionMastery({
    required this.championId,
    required this.championName,
    required this.championLevel,
    required this.championPoints,
    required this.lastPlayTime,
  });

  String get iconUrl =>
      'https://ddragon.leagueoflegends.com/cdn/14.1.1/img/champion/$championName.png';
}
