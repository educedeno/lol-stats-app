import 'package:dio/dio.dart';
import '../models/summoner.dart';
import '../models/match.dart';
import '../models/champion.dart';

/// Riot Games API Service
///
/// Para usar:
/// 1. Saca tu key en https://developer.riotgames.com (caduca cada 24h)
/// 2. Corre la app con:
///    flutter run -d windows --dart-define=RIOT_API_KEY=RGAPI-tu-key-aqui
class RiotApiService {
  // ============= CONFIG =============

  static const String _envKey = String.fromEnvironment('RIOT_API_KEY');
  String get _apiKey => _envKey;

  // Regional routing (cuentas, partidas)
  static const String _regionalUrl = 'https://americas.api.riotgames.com';
  // Platform routing (summoner, ranked, mastery) — LA1 = LAN
  static const String _platformUrl = 'https://la1.api.riotgames.com';

  static const String _ddragonVersion = '14.1.1';

  final Dio _dio;
  Map<int, String>? _championIdToName;

  RiotApiService() : _dio = Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
  }

  Map<String, String> get _headers => {'X-Riot-Token': _apiKey};

  void _assertKey() {
    if (_apiKey.isEmpty) {
      throw Exception(
        'Falta API key. Corre con --dart-define=RIOT_API_KEY=RGAPI-...',
      );
    }
  }

  Never _handleError(DioException e, String context) {
    final status = e.response?.statusCode;
    if (status == 401 || status == 403) {
      throw Exception(
          'API key inválida o expirada. Genera una nueva en developer.riotgames.com');
    }
    if (status == 404) {
      throw Exception('No encontrado: $context');
    }
    if (status == 429) {
      throw Exception('Rate limit excedido. Espera un momento.');
    }
    throw Exception('Error de API ($status): ${e.message}');
  }

  // ============= SUMMONER =============

  Future<Summoner> getSummonerByName(String gameName, String tagLine) async {
    _assertKey();
    try {
      final accountResp = await _dio.get(
        '$_regionalUrl/riot/account/v1/accounts/by-riot-id/$gameName/$tagLine',
        options: Options(headers: _headers),
      );
      final puuid = accountResp.data['puuid'] as String;
      final realGameName = accountResp.data['gameName'] as String? ?? gameName;
      final realTagLine = accountResp.data['tagLine'] as String? ?? tagLine;

      final sumResp = await _dio.get(
        '$_platformUrl/lol/summoner/v4/summoners/by-puuid/$puuid',
        options: Options(headers: _headers),
      );

      return Summoner(
        puuid: puuid,
        name: realGameName,
        tagLine: realTagLine,
        profileIconId: sumResp.data['profileIconId'] as int? ?? 1,
        summonerLevel: (sumResp.data['summonerLevel'] as num?)?.toInt() ?? 0,
        region: 'LA1',
      );
    } on DioException catch (e) {
      _handleError(e, '$gameName#$tagLine');
    }
  }

  // ============= RANKED INFO =============

  Future<List<RankedInfo>> getRankedInfo(String puuid) async {
    _assertKey();
    try {
      final resp = await _dio.get(
        '$_platformUrl/lol/league/v4/entries/by-puuid/$puuid',
        options: Options(headers: _headers),
      );
      final list = resp.data as List;
      return list
          .map((e) => RankedInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleError(e, 'ranked $puuid');
    }
  }

  // ============= MATCH HISTORY =============

  Future<List<Match>> getMatchHistory(String puuid, {int count = 20}) async {
    _assertKey();
    try {
      final idsResp = await _dio.get(
        '$_regionalUrl/lol/match/v5/matches/by-puuid/$puuid/ids',
        queryParameters: {'count': count},
        options: Options(headers: _headers),
      );
      final ids = (idsResp.data as List).cast<String>();

      // Procesamos en lotes pequeños para no exceder el rate limit de Riot
      // (dev key: 20 req/seg, 100 req/2min).
      return _runBatched<String, Match>(
        ids,
        batchSize: 5,
        delayBetweenBatches: const Duration(milliseconds: 1200),
        task: (id) async {
          final resp = await _dio.get(
            '$_regionalUrl/lol/match/v5/matches/$id',
            options: Options(headers: _headers),
          );
          return _parseMatch(resp.data as Map<String, dynamic>);
        },
      );
    } on DioException catch (e) {
      _handleError(e, 'matches $puuid');
    }
  }

  /// Ejecuta [task] sobre [items] en lotes paralelos, esperando entre lotes
  /// para no saturar el rate limit.
  Future<List<R>> _runBatched<T, R>(
    List<T> items, {
    required int batchSize,
    required Duration delayBetweenBatches,
    required Future<R> Function(T) task,
  }) async {
    final results = <R>[];
    for (var i = 0; i < items.length; i += batchSize) {
      final batch = items.skip(i).take(batchSize);
      final batchResults = await Future.wait(batch.map(task));
      results.addAll(batchResults);
      if (i + batchSize < items.length) {
        await Future.delayed(delayBetweenBatches);
      }
    }
    return results;
  }

  Match _parseMatch(Map<String, dynamic> json) {
    final info = json['info'] as Map<String, dynamic>;
    final metadata = json['metadata'] as Map<String, dynamic>;
    final participants = (info['participants'] as List)
        .map((p) => _parseParticipant(p as Map<String, dynamic>))
        .toList();

    return Match(
      matchId: metadata['matchId'] as String,
      gameMode: info['gameMode'] as String? ?? 'CLASSIC',
      gameDuration: (info['gameDuration'] as num?)?.toInt() ?? 0,
      gameCreation: DateTime.fromMillisecondsSinceEpoch(
        (info['gameCreation'] as num?)?.toInt() ?? 0,
      ),
      participants: participants,
    );
  }

  Participant _parseParticipant(Map<String, dynamic> p) {
    return Participant(
      puuid: p['puuid'] as String? ?? '',
      summonerName: p['riotIdGameName'] as String? ??
          p['summonerName'] as String? ??
          '',
      championName: p['championName'] as String? ?? '',
      championId: (p['championId'] as num?)?.toInt() ?? 0,
      role: p['role'] as String? ?? '',
      lane: p['lane'] as String? ?? '',
      kills: (p['kills'] as num?)?.toInt() ?? 0,
      deaths: (p['deaths'] as num?)?.toInt() ?? 0,
      assists: (p['assists'] as num?)?.toInt() ?? 0,
      totalMinionsKilled: (p['totalMinionsKilled'] as num?)?.toInt() ?? 0,
      neutralMinionsKilled: (p['neutralMinionsKilled'] as num?)?.toInt() ?? 0,
      goldEarned: (p['goldEarned'] as num?)?.toInt() ?? 0,
      totalDamageDealtToChampions:
          (p['totalDamageDealtToChampions'] as num?)?.toInt() ?? 0,
      visionScore: (p['visionScore'] as num?)?.toInt() ?? 0,
      win: p['win'] as bool? ?? false,
      items: [
        (p['item0'] as num?)?.toInt() ?? 0,
        (p['item1'] as num?)?.toInt() ?? 0,
        (p['item2'] as num?)?.toInt() ?? 0,
        (p['item3'] as num?)?.toInt() ?? 0,
        (p['item4'] as num?)?.toInt() ?? 0,
        (p['item5'] as num?)?.toInt() ?? 0,
      ],
    );
  }

  // ============= MATCH TIMELINE =============

  /// Devuelve la timeline cruda (estructura de Riot) para una partida.
  /// Necesario para extraer stats al minuto 10.
  Future<Map<String, dynamic>> getMatchTimeline(String matchId) async {
    _assertKey();
    try {
      final resp = await _dio.get(
        '$_regionalUrl/lol/match/v5/matches/$matchId/timeline',
        options: Options(headers: _headers),
      );
      return Map<String, dynamic>.from(resp.data as Map);
    } on DioException catch (e) {
      _handleError(e, 'timeline $matchId');
    }
  }

  /// Trae match + timeline en paralelo.
  Future<({Match match, Map<String, dynamic> timeline})> getMatchWithTimeline(
    String matchId,
  ) async {
    _assertKey();
    try {
      final results = await Future.wait([
        _dio.get(
          '$_regionalUrl/lol/match/v5/matches/$matchId',
          options: Options(headers: _headers),
        ),
        _dio.get(
          '$_regionalUrl/lol/match/v5/matches/$matchId/timeline',
          options: Options(headers: _headers),
        ),
      ]);
      final match = _parseMatch(results[0].data as Map<String, dynamic>);
      final timeline = Map<String, dynamic>.from(results[1].data as Map);
      return (match: match, timeline: timeline);
    } on DioException catch (e) {
      _handleError(e, 'match+timeline $matchId');
    }
  }

  /// Devuelve los IDs de las últimas N partidas (sin descargar el detalle).
  Future<List<String>> getRecentMatchIds(String puuid, {int count = 5}) async {
    _assertKey();
    try {
      final resp = await _dio.get(
        '$_regionalUrl/lol/match/v5/matches/by-puuid/$puuid/ids',
        queryParameters: {'count': count},
        options: Options(headers: _headers),
      );
      return (resp.data as List).cast<String>();
    } on DioException catch (e) {
      _handleError(e, 'match ids $puuid');
    }
  }

  // ============= CHAMPION MASTERY =============

  Future<List<ChampionMastery>> getChampionMastery(String puuid) async {
    _assertKey();
    try {
      final resp = await _dio.get(
        '$_platformUrl/lol/champion-mastery/v4/champion-masteries/by-puuid/$puuid/top',
        queryParameters: {'count': 5},
        options: Options(headers: _headers),
      );
      final list = resp.data as List;

      await _ensureChampionMap();

      return list.map((e) {
        final m = e as Map<String, dynamic>;
        final id = (m['championId'] as num).toInt();
        return ChampionMastery(
          championId: id,
          championName: _championIdToName?[id] ?? 'Champion$id',
          championLevel: (m['championLevel'] as num?)?.toInt() ?? 0,
          championPoints: (m['championPoints'] as num?)?.toInt() ?? 0,
          lastPlayTime: DateTime.fromMillisecondsSinceEpoch(
            (m['lastPlayTime'] as num?)?.toInt() ?? 0,
          ),
        );
      }).toList();
    } on DioException catch (e) {
      _handleError(e, 'mastery $puuid');
    }
  }

  // ============= DATA DRAGON (champion id → name) =============

  Future<void> _ensureChampionMap() async {
    if (_championIdToName != null) return;
    final resp = await _dio.get(
      'https://ddragon.leagueoflegends.com/cdn/$_ddragonVersion/data/en_US/champion.json',
    );
    final data = resp.data['data'] as Map<String, dynamic>;
    _championIdToName = {
      for (final entry in data.entries)
        int.parse(entry.value['key'] as String): entry.value['id'] as String,
    };
  }
}
