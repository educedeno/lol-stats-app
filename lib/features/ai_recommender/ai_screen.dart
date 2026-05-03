import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';

/// Win Predictor — Random Forest entrenado en Kaggle (high_diamond_ranked_10min).
/// El usuario aprieta el botón "Analizar" para evitar disparar requests
/// automáticamente cuando se cambia de pestaña.
class AIScreen extends ConsumerStatefulWidget {
  const AIScreen({super.key});

  @override
  ConsumerState<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends ConsumerState<AIScreen> {
  Future<List<MatchAnalysis>>? _future;
  String? _analyzingFor;

  void _runAnalysis(String puuid) {
    setState(() {
      _analyzingFor = puuid;
      _future = ref.read(winPredictorAnalysisProvider(puuid).future);
    });
  }

  @override
  Widget build(BuildContext context) {
    final summoner = ref.watch(currentSummonerProvider);

    // Si cambia el invocador buscado, reseteamos.
    if (summoner != null &&
        _analyzingFor != null &&
        _analyzingFor != summoner.puuid) {
      _future = null;
      _analyzingFor = null;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('WIN PREDICTOR')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Header(),
            const SizedBox(height: AppSizes.paddingL),
            if (summoner == null)
              const _EmptyState()
            else if (_future == null)
              _ReadyToAnalyze(
                summonerName: '${summoner.name}#${summoner.tagLine}',
                onAnalyze: () => _runAnalysis(summoner.puuid),
              )
            else
              _ResultsView(
                future: _future!,
                onRetry: () => _runAnalysis(summoner.puuid),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.25),
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        border: Border.all(color: AppColors.accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology,
                  color: AppColors.accent, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'WIN PREDICTOR',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(color: AppColors.accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Random Forest entrenado con ~10K partidas de Diamond. '
            'Predice el resultado usando el estado del minuto 10.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              _Chip(label: 'Random Forest', icon: Icons.model_training),
              SizedBox(width: 8),
              _Chip(label: '38 features', icon: Icons.tune),
              SizedBox(width: 8),
              _Chip(label: '71% accuracy', icon: Icons.verified),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Chip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.accent),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          children: [
            Icon(Icons.search_off, color: AppColors.textSecondary, size: 48),
            SizedBox(height: 12),
            Text(
              'Busca primero un invocador',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'En la pestaña Search, busca a un jugador y vuelve aquí '
              'para analizar sus últimas partidas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadyToAnalyze extends StatelessWidget {
  final String summonerName;
  final VoidCallback onAnalyze;
  const _ReadyToAnalyze({
    required this.summonerName,
    required this.onAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.analytics, color: AppColors.accent, size: 40),
            const SizedBox(height: 12),
            Text(
              'Analizar a $summonerName',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Descargaremos las últimas 5 partidas con su timeline y '
              'compararemos la predicción del modelo con el resultado real.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAnalyze,
              icon: const Icon(Icons.play_arrow),
              label: const Text('ANALIZAR PARTIDAS'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultsView extends StatelessWidget {
  final Future<List<MatchAnalysis>> future;
  final VoidCallback onRetry;
  const _ResultsView({required this.future, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MatchAnalysis>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(child: _LoadingState()),
          );
        }
        if (snap.hasError) {
          return _ErrorView(error: snap.error.toString(), onRetry: onRetry);
        }
        final analyses = snap.data ?? [];
        if (analyses.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              child: Column(
                children: [
                  const Text(
                    'No se pudieron analizar partidas recientes.',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        final valid = analyses.where((a) => a.prediction.valid).toList();
        final correct = valid.where((a) => a.predictionWasCorrect).length;
        final total = valid.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AccuracySummary(correct: correct, total: total),
            const SizedBox(height: AppSizes.paddingL),
            Row(
              children: [
                const Text(
                  'PARTIDAS ANALIZADAS',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh,
                      color: AppColors.textSecondary, size: 18),
                  tooltip: 'Re-analizar',
                ),
              ],
            ),
            const SizedBox(height: 4),
            ...analyses.map((a) => _MatchPredictionCard(analysis: a)),
            const SizedBox(height: 16),
            const _HowItWorks(),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        CircularProgressIndicator(color: AppColors.accent),
        SizedBox(height: 16),
        Text(
          'Analizando últimas partidas...',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        SizedBox(height: 4),
        Text(
          '(descarga timelines de Riot, ~10-15 seg)',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.error_outline, color: AppColors.defeat),
                SizedBox(width: 8),
                Text(
                  'Error al analizar',
                  style: TextStyle(
                    color: AppColors.defeat,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccuracySummary extends StatelessWidget {
  final int correct;
  final int total;
  const _AccuracySummary({required this.correct, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : (correct / total) * 100;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aciertos del modelo',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$correct / $total',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${pct.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: pct >= 60 ? AppColors.victory : AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : correct / total,
              minHeight: 8,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation(
                pct >= 60 ? AppColors.victory : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchPredictionCard extends StatelessWidget {
  final MatchAnalysis analysis;
  const _MatchPredictionCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final m = analysis.match;
    final pred = analysis.prediction;

    if (!pred.valid) {
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${m.matchId} — ${pred.invalidReason ?? 'no válida'}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final selfParticipant = analysis.player;
    final won = analysis.playerWonReal;
    final correct = analysis.predictionWasCorrect;
    final playerProb = pred.playerProbability;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: selfParticipant.championIconUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      color: AppColors.surfaceLight,
                      child: const Icon(Icons.help_outline,
                          color: AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selfParticipant.championName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '${m.gameMode} • ${m.timeAgo}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (won ? AppColors.victory : AppColors.defeat)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    won ? 'WIN' : 'LOSS',
                    style: TextStyle(
                      color: won ? AppColors.victory : AppColors.defeat,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  correct ? Icons.check_circle : Icons.cancel,
                  color: correct ? AppColors.victory : AppColors.defeat,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  correct ? 'Modelo acertó' : 'Modelo falló',
                  style: TextStyle(
                    color: correct ? AppColors.victory : AppColors.defeat,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Text(
                  pred.playerOnBlue ? 'Jugó en BLUE' : 'Jugó en RED',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Probabilidad de ganar al minuto 10',
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: playerProb,
                      minHeight: 10,
                      backgroundColor: AppColors.surfaceLight,
                      valueColor: AlwaysStoppedAnimation(
                        playerProb >= 0.5
                            ? AppColors.victory
                            : AppColors.defeat,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 50,
                  child: Text(
                    '${(playerProb * 100).toStringAsFixed(0)}%',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lightbulb_outline,
                  color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                '¿Cómo funciona?',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Para cada partida descargamos la timeline desde la Riot API y '
            'extraemos 38 features del minuto 10: oro, kills, dragones, '
            'visión, diferencia de oro, etc. El Random Forest (entrenado en '
            'Python con scikit-learn) calcula la probabilidad de victoria. '
            'Comparamos esa predicción con el resultado real.',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
