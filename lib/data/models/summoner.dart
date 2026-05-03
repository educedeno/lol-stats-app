class Summoner {
  final String puuid;
  final String name;
  final String tagLine;
  final int profileIconId;
  final int summonerLevel;
  final String region;

  Summoner({
    required this.puuid,
    required this.name,
    required this.tagLine,
    required this.profileIconId,
    required this.summonerLevel,
    required this.region,
  });

  String get fullName => '$name#$tagLine';

  String get profileIconUrl =>
      'https://ddragon.leagueoflegends.com/cdn/14.1.1/img/profileicon/$profileIconId.png';

  factory Summoner.fromJson(Map<String, dynamic> json) {
    return Summoner(
      puuid: json['puuid'] ?? '',
      name: json['name'] ?? json['gameName'] ?? '',
      tagLine: json['tagLine'] ?? '',
      profileIconId: json['profileIconId'] ?? 1,
      summonerLevel: json['summonerLevel'] ?? 0,
      region: json['region'] ?? 'LA1',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'puuid': puuid,
      'name': name,
      'tag_line': tagLine,
      'profile_icon_id': profileIconId,
      'summoner_level': summonerLevel,
      'region': region,
    };
  }

  factory Summoner.fromMap(Map<String, dynamic> map) {
    return Summoner(
      puuid: map['puuid'],
      name: map['name'],
      tagLine: map['tag_line'] ?? '',
      profileIconId: map['profile_icon_id'] ?? 1,
      summonerLevel: map['summoner_level'] ?? 0,
      region: map['region'] ?? 'LA1',
    );
  }
}

class RankedInfo {
  final String queueType;
  final String tier;
  final String rank;
  final int leaguePoints;
  final int wins;
  final int losses;

  RankedInfo({
    required this.queueType,
    required this.tier,
    required this.rank,
    required this.leaguePoints,
    required this.wins,
    required this.losses,
  });

  double get winRate {
    final total = wins + losses;
    if (total == 0) return 0;
    return (wins / total) * 100;
  }

  String get fullRank => '$tier $rank';

  factory RankedInfo.fromJson(Map<String, dynamic> json) {
    return RankedInfo(
      queueType: json['queueType'] ?? '',
      tier: json['tier'] ?? 'UNRANKED',
      rank: json['rank'] ?? '',
      leaguePoints: json['leaguePoints'] ?? 0,
      wins: json['wins'] ?? 0,
      losses: json['losses'] ?? 0,
    );
  }
}
