class Match {
  final String matchId;
  final String gameMode;
  final int gameDuration;
  final DateTime gameCreation;
  final List<Participant> participants;

  Match({
    required this.matchId,
    required this.gameMode,
    required this.gameDuration,
    required this.gameCreation,
    required this.participants,
  });

  Participant? participantByPuuid(String puuid) {
    try {
      return participants.firstWhere((p) => p.puuid == puuid);
    } catch (_) {
      return null;
    }
  }

  String get durationFormatted {
    final minutes = gameDuration ~/ 60;
    final seconds = gameDuration % 60;
    return '${minutes}m ${seconds}s';
  }

  String get timeAgo {
    final diff = DateTime.now().difference(gameCreation);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

class Participant {
  final String puuid;
  final String summonerName;
  final String championName;
  final int championId;
  final String role;
  final String lane;
  final int kills;
  final int deaths;
  final int assists;
  final int totalMinionsKilled;
  final int neutralMinionsKilled;
  final int goldEarned;
  final int totalDamageDealtToChampions;
  final int visionScore;
  final bool win;
  final List<int> items;

  Participant({
    required this.puuid,
    required this.summonerName,
    required this.championName,
    required this.championId,
    required this.role,
    required this.lane,
    required this.kills,
    required this.deaths,
    required this.assists,
    required this.totalMinionsKilled,
    required this.neutralMinionsKilled,
    required this.goldEarned,
    required this.totalDamageDealtToChampions,
    required this.visionScore,
    required this.win,
    required this.items,
  });

  double get kda {
    if (deaths == 0) return (kills + assists).toDouble();
    return (kills + assists) / deaths;
  }

  int get cs => totalMinionsKilled + neutralMinionsKilled;

  double csPerMinute(int gameDurationSeconds) {
    final minutes = gameDurationSeconds / 60;
    if (minutes == 0) return 0;
    return cs / minutes;
  }

  String get displayRole {
    if (lane == 'TOP') return 'TOP';
    if (lane == 'JUNGLE') return 'JUNGLE';
    if (lane == 'MIDDLE') return 'MID';
    if (lane == 'BOTTOM') {
      return role == 'SUPPORT' || role == 'UTILITY' ? 'SUPPORT' : 'ADC';
    }
    return role;
  }

  String get championIconUrl =>
      'https://ddragon.leagueoflegends.com/cdn/14.1.1/img/champion/$championName.png';

  String get championSplashUrl =>
      'https://ddragon.leagueoflegends.com/cdn/img/champion/splash/${championName}_0.jpg';

  String itemIconUrl(int itemId) =>
      'https://ddragon.leagueoflegends.com/cdn/14.1.1/img/item/$itemId.png';
}
