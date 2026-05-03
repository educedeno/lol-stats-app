import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/api/riot_api_service.dart';
import '../../data/db/database_helper.dart';
import '../../data/ml/win_predictor_service.dart';
import '../../data/models/summoner.dart';
import '../../data/models/match.dart';
import '../../data/models/champion.dart';

// ============= SERVICES =============

final riotApiProvider = Provider<RiotApiService>((ref) {
  return RiotApiService();
});

final dbProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

final winPredictorProvider = Provider<WinPredictorService>((ref) {
  return WinPredictorService();
});

/// Resultado del análisis Win Predictor para una partida.
class MatchAnalysis {
  final Match match;
  final Participant player;
  final WinPrediction prediction;
  final bool playerWonReal;
  MatchAnalysis({
    required this.match,
    required this.player,
    required this.prediction,
    required this.playerWonReal,
  });

  bool get predictionWasCorrect =>
      prediction.valid &&
      prediction.predictedPlayerWins == playerWonReal;
}

/// Analiza las últimas N partidas del invocador con el Win Predictor.
final winPredictorAnalysisProvider =
    FutureProvider.family<List<MatchAnalysis>, String>((ref, puuid) async {
  final api = ref.read(riotApiProvider);
  final predictor = ref.read(winPredictorProvider);

  final ids = await api.getRecentMatchIds(puuid, count: 5);
  final results = <MatchAnalysis>[];
  for (final id in ids) {
    try {
      final mt = await api.getMatchWithTimeline(id);
      final pred =
          predictor.predictFromTimeline(mt.timeline, puuid: puuid);
      final me = mt.match.participantByPuuid(puuid);
      if (me == null) continue;
      results.add(MatchAnalysis(
        match: mt.match,
        player: me,
        prediction: pred,
        playerWonReal: me.win,
      ));
    } catch (_) {
      // Si una partida falla (rate limit, modo no soportado), seguimos.
      continue;
    }
  }
  return results;
});

// ============= CURRENT SUMMONER =============

final currentSummonerProvider = StateProvider<Summoner?>((ref) => null);

final summonerSearchProvider =
    FutureProvider.family<Summoner, ({String name, String tag})>((
  ref,
  query,
) async {
  final api = ref.read(riotApiProvider);
  final summoner = await api.getSummonerByName(query.name, query.tag);
  // Save to recent searches
  await ref.read(dbProvider).addRecentSearch(query.name, query.tag);
  return summoner;
});

// ============= RANKED INFO =============

final rankedInfoProvider = FutureProvider.family<List<RankedInfo>, String>((
  ref,
  summonerId,
) async {
  return ref.read(riotApiProvider).getRankedInfo(summonerId);
});

// ============= MATCH HISTORY =============

final matchHistoryProvider = FutureProvider.family<List<Match>, String>((
  ref,
  puuid,
) async {
  return ref.read(riotApiProvider).getMatchHistory(puuid);
});

// ============= CHAMPION MASTERY =============

final masteryProvider = FutureProvider.family<List<ChampionMastery>, String>((
  ref,
  puuid,
) async {
  return ref.read(riotApiProvider).getChampionMastery(puuid);
});

// ============= FAVORITES =============

class FavoritesNotifier extends StateNotifier<List<Summoner>> {
  final DatabaseHelper _db;

  FavoritesNotifier(this._db) : super([]) {
    _load();
  }

  Future<void> _load() async {
    state = await _db.getFavoriteSummoners();
  }

  Future<void> add(Summoner summoner) async {
    await _db.addFavoriteSummoner(summoner);
    await _load();
  }

  Future<void> remove(String puuid) async {
    await _db.removeFavoriteSummoner(puuid);
    await _load();
  }

  Future<bool> isFavorite(String puuid) async {
    return await _db.isFavoriteSummoner(puuid);
  }

  Future<void> toggle(Summoner summoner) async {
    final isFav = await isFavorite(summoner.puuid);
    if (isFav) {
      await remove(summoner.puuid);
    } else {
      await add(summoner);
    }
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, List<Summoner>>((ref) {
  return FavoritesNotifier(ref.read(dbProvider));
});

// ============= RECENT SEARCHES =============

final recentSearchesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(dbProvider).getRecentSearches();
});
