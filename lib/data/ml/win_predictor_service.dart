import 'win_predictor_model.dart' as model;

/// Resultado de aplicar el Win Predictor a una partida.
class WinPrediction {
  /// Probabilidad de que gane el equipo azul (0..1).
  final double blueProbability;

  /// Equipo (100 = azul, 200 = rojo) en el que estaba el invocador consultado.
  final int playerTeamId;

  /// true si la partida llegó al minuto 10 (modelo pudo correr).
  final bool valid;

  /// Razón si valid == false.
  final String? invalidReason;

  /// Features crudas usadas (debug).
  final List<double>? features;

  const WinPrediction({
    required this.blueProbability,
    required this.playerTeamId,
    required this.valid,
    this.invalidReason,
    this.features,
  });

  bool get playerOnBlue => playerTeamId == 100;

  /// Probabilidad de que gane el jugador (no el equipo azul).
  double get playerProbability =>
      playerOnBlue ? blueProbability : (1.0 - blueProbability);

  /// "Predicción" binaria: ¿el modelo dice que el jugador gana?
  bool get predictedPlayerWins => playerProbability >= 0.5;

  factory WinPrediction.invalid(String reason, {int teamId = 100}) =>
      WinPrediction(
        blueProbability: 0.5,
        playerTeamId: teamId,
        valid: false,
        invalidReason: reason,
      );
}

class WinPredictorService {
  static const int _frameMs = 600000; // minuto 10

  /// Construye las 38 features y predice la probabilidad de victoria azul
  /// a partir de la timeline cruda de Riot.
  ///
  /// [puuid] se usa para saber en qué equipo estaba el jugador consultado.
  WinPrediction predictFromTimeline(
    Map<String, dynamic> timeline, {
    required String puuid,
  }) {
    final info = timeline['info'] as Map<String, dynamic>?;
    if (info == null) {
      return WinPrediction.invalid('Timeline mal formada');
    }

    final participantsRaw = info['participants'] as List? ?? const [];
    // participantId → puuid
    final pidToPuuid = <int, String>{};
    for (final p in participantsRaw) {
      final m = p as Map<String, dynamic>;
      pidToPuuid[(m['participantId'] as num).toInt()] = m['puuid'] as String;
    }

    // ¿En qué equipo está nuestro jugador? participantes 1..5 son azul (100),
    // 6..10 son rojo (200). Si por algún motivo no aparece, default azul.
    int playerTeamId = 100;
    for (final entry in pidToPuuid.entries) {
      if (entry.value == puuid) {
        playerTeamId = entry.key <= 5 ? 100 : 200;
        break;
      }
    }

    final frames = info['frames'] as List? ?? const [];
    if (frames.length < 11) {
      return WinPrediction.invalid(
        'Partida muy corta (no llegó al minuto 10)',
        teamId: playerTeamId,
      );
    }

    // Frame del minuto 10
    final frame10 = frames[10] as Map<String, dynamic>;
    final pframes = frame10['participantFrames'] as Map<String, dynamic>;

    double blueGold = 0,
        redGold = 0,
        blueXp = 0,
        redXp = 0,
        blueLevelSum = 0,
        redLevelSum = 0,
        blueCs = 0,
        redCs = 0,
        blueJg = 0,
        redJg = 0;

    pframes.forEach((pidStr, raw) {
      final pid = int.parse(pidStr);
      final f = raw as Map<String, dynamic>;
      final isBlue = pid <= 5;
      final gold = (f['totalGold'] as num?)?.toDouble() ?? 0;
      final xp = (f['xp'] as num?)?.toDouble() ?? 0;
      final lvl = (f['level'] as num?)?.toDouble() ?? 0;
      final cs = (f['minionsKilled'] as num?)?.toDouble() ?? 0;
      final jg = (f['jungleMinionsKilled'] as num?)?.toDouble() ?? 0;

      if (isBlue) {
        blueGold += gold;
        blueXp += xp;
        blueLevelSum += lvl;
        blueCs += cs;
        blueJg += jg;
      } else {
        redGold += gold;
        redXp += xp;
        redLevelSum += lvl;
        redCs += cs;
        redJg += jg;
      }
    });

    final blueAvgLevel = blueLevelSum / 5.0;
    final redAvgLevel = redLevelSum / 5.0;

    // Recorremos eventos de TODOS los frames hasta el minuto 10.
    int blueWardsPlaced = 0,
        redWardsPlaced = 0,
        blueWardsDestroyed = 0,
        redWardsDestroyed = 0,
        blueKills = 0,
        redKills = 0,
        blueAssists = 0,
        redAssists = 0,
        blueDragons = 0,
        redDragons = 0,
        blueHeralds = 0,
        redHeralds = 0,
        blueTowers = 0,
        redTowers = 0;
    int? firstBloodTeam; // 100 / 200

    for (var i = 0; i <= 10 && i < frames.length; i++) {
      final events = (frames[i] as Map<String, dynamic>)['events'] as List? ??
          const [];
      for (final ev in events) {
        final e = ev as Map<String, dynamic>;
        final ts = (e['timestamp'] as num?)?.toInt() ?? 0;
        if (ts > _frameMs) continue;
        final type = e['type'] as String? ?? '';

        switch (type) {
          case 'WARD_PLACED':
            final cid = (e['creatorId'] as num?)?.toInt() ?? 0;
            if (cid >= 1 && cid <= 5) blueWardsPlaced++;
            if (cid >= 6 && cid <= 10) redWardsPlaced++;
            break;
          case 'WARD_KILL':
            final kid = (e['killerId'] as num?)?.toInt() ?? 0;
            if (kid >= 1 && kid <= 5) blueWardsDestroyed++;
            if (kid >= 6 && kid <= 10) redWardsDestroyed++;
            break;
          case 'CHAMPION_KILL':
            final killer = (e['killerId'] as num?)?.toInt() ?? 0;
            final victim = (e['victimId'] as num?)?.toInt() ?? 0;
            final assists = (e['assistingParticipantIds'] as List?) ?? const [];
            int? killerTeam;
            if (killer >= 1 && killer <= 5) {
              blueKills++;
              killerTeam = 100;
            } else if (killer >= 6 && killer <= 10) {
              redKills++;
              killerTeam = 200;
            }
            // (No usamos deaths como feature separada — el modelo ya tiene
            //  redKills == blueDeaths trivialmente, lo replicamos abajo.)
            for (final aid in assists) {
              final a = (aid as num).toInt();
              if (a >= 1 && a <= 5) blueAssists++;
              if (a >= 6 && a <= 10) redAssists++;
            }
            firstBloodTeam ??= killerTeam;
            // Para mantener la cuenta de muertes de la víctima:
            if (victim >= 1 && victim <= 5) {
              // muerte del lado azul (= kill rojo, ya contado arriba si aplica)
            }
            break;
          case 'ELITE_MONSTER_KILL':
            final teamId = (e['killerTeamId'] as num?)?.toInt() ?? 0;
            final monster = e['monsterType'] as String? ?? '';
            if (teamId == 100) {
              if (monster == 'DRAGON') blueDragons++;
              if (monster == 'RIFTHERALD') blueHeralds++;
            } else if (teamId == 200) {
              if (monster == 'DRAGON') redDragons++;
              if (monster == 'RIFTHERALD') redHeralds++;
            }
            break;
          case 'BUILDING_KILL':
            final lostTeam = (e['teamId'] as num?)?.toInt() ?? 0;
            final buildType = e['buildingType'] as String? ?? '';
            if (buildType == 'TOWER_BUILDING') {
              // El que pierde la torre es lostTeam, así que la otra la destruyó.
              if (lostTeam == 200) blueTowers++;
              if (lostTeam == 100) redTowers++;
            }
            break;
        }
      }
    }

    // En el dataset original, deaths = kills del rival
    final blueDeaths = redKills.toDouble();
    final redDeaths = blueKills.toDouble();

    final blueElite = (blueDragons + blueHeralds).toDouble();
    final redElite = (redDragons + redHeralds).toDouble();

    final blueFirstBlood = firstBloodTeam == 100 ? 1.0 : 0.0;
    final redFirstBlood = firstBloodTeam == 200 ? 1.0 : 0.0;

    final blueGoldDiff = blueGold - redGold;
    final redGoldDiff = -blueGoldDiff;
    final blueXpDiff = blueXp - redXp;
    final redXpDiff = -blueXpDiff;

    // Features en el orden de feature_names.txt
    final features = <double>[
      blueWardsPlaced.toDouble(),       // 0
      blueWardsDestroyed.toDouble(),    // 1
      blueFirstBlood,                   // 2
      blueKills.toDouble(),             // 3
      blueDeaths,                       // 4
      blueAssists.toDouble(),           // 5
      blueElite,                        // 6
      blueDragons.toDouble(),           // 7
      blueHeralds.toDouble(),           // 8
      blueTowers.toDouble(),            // 9
      blueGold,                         // 10
      blueAvgLevel,                     // 11
      blueXp,                           // 12
      blueCs,                           // 13
      blueJg,                           // 14
      blueGoldDiff,                     // 15
      blueXpDiff,                       // 16
      blueCs / 10.0,                    // 17 blueCSPerMin
      blueGold / 10.0,                  // 18 blueGoldPerMin
      redWardsPlaced.toDouble(),        // 19
      redWardsDestroyed.toDouble(),     // 20
      redFirstBlood,                    // 21
      redKills.toDouble(),              // 22
      redDeaths,                        // 23
      redAssists.toDouble(),            // 24
      redElite,                         // 25
      redDragons.toDouble(),            // 26
      redHeralds.toDouble(),            // 27
      redTowers.toDouble(),             // 28
      redGold,                          // 29
      redAvgLevel,                      // 30
      redXp,                            // 31
      redCs,                            // 32
      redJg,                            // 33
      redGoldDiff,                      // 34
      redXpDiff,                        // 35
      redCs / 10.0,                     // 36
      redGold / 10.0,                   // 37
    ];

    final scores = model.scoreWinPredictor(features);
    // scores = [probRed, probBlue]
    final probBlue = scores[1].clamp(0.0, 1.0);

    return WinPrediction(
      blueProbability: probBlue,
      playerTeamId: playerTeamId,
      valid: true,
      features: features,
    );
  }
}
