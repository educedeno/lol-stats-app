import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';
import '../../data/models/match.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summoner = ref.watch(currentSummonerProvider);

    if (summoner == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('STATISTICS')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bar_chart,
                  size: 80,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: 16),
                Text(
                  'Search a summoner to see stats',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final matchesAsync = ref.watch(matchHistoryProvider(summoner.puuid));

    return Scaffold(
      appBar: AppBar(title: Text('${summoner.name} Stats')),
      body: matchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (matches) {
          if (matches.isEmpty) {
            return const Center(child: Text('No match data'));
          }

          final stats = _computeStats(matches, summoner.puuid);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary cards
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: 'Win Rate',
                        value:
                            '${stats.overallWinRate.toStringAsFixed(0)}%',
                        color: stats.overallWinRate >= 50
                            ? AppColors.victory
                            : AppColors.defeat,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Avg KDA',
                        value: stats.averageKda.toStringAsFixed(2),
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Games',
                        value: '${stats.totalGames}',
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingL),

                // Win rate by champion
                _SectionTitle('WIN RATE BY CHAMPION'),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingM),
                    child: SizedBox(
                      height: 240,
                      child: _ChampionWinRateChart(
                        data: stats.winRateByChampion,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.paddingL),

                // KDA over time
                _SectionTitle('KDA TREND'),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingM),
                    child: SizedBox(
                      height: 220,
                      child: _KdaLineChart(kdaList: stats.kdaTrend),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.paddingL),

                // Role distribution
                _SectionTitle('ROLE DISTRIBUTION'),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingM),
                    child: SizedBox(
                      height: 250,
                      child: _RolePieChart(roleDistribution: stats.rolesPlayed),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.paddingL),
              ],
            ),
          );
        },
      ),
    );
  }

  _ComputedStats _computeStats(List<Match> matches, String puuid) {
    int wins = 0;
    int totalKills = 0, totalDeaths = 0, totalAssists = 0;
    final champStats = <String, _ChampStat>{};
    final kdaTrend = <double>[];
    final roles = <String, int>{};

    for (final match in matches.reversed) {
      final p = match.participantByPuuid(puuid);
      if (p == null) continue;

      if (p.win) wins++;
      totalKills += p.kills;
      totalDeaths += p.deaths;
      totalAssists += p.assists;

      kdaTrend.add(p.kda);

      final cs = champStats.putIfAbsent(
        p.championName,
        () => _ChampStat(),
      );
      cs.games++;
      if (p.win) cs.wins++;

      roles[p.displayRole] = (roles[p.displayRole] ?? 0) + 1;
    }

    final winRateByChamp = <String, double>{};
    final sorted = champStats.entries.toList()
      ..sort((a, b) => b.value.games.compareTo(a.value.games));

    for (final entry in sorted.take(6)) {
      winRateByChamp[entry.key] =
          (entry.value.wins / entry.value.games) * 100;
    }

    final totalKda = totalDeaths == 0
        ? (totalKills + totalAssists).toDouble()
        : (totalKills + totalAssists) / totalDeaths;

    return _ComputedStats(
      totalGames: matches.length,
      overallWinRate: matches.isEmpty ? 0 : (wins / matches.length) * 100,
      averageKda: totalKda,
      winRateByChampion: winRateByChamp,
      kdaTrend: kdaTrend,
      rolesPlayed: roles,
    );
  }
}

// ============= HELPER CLASSES =============

class _ComputedStats {
  final int totalGames;
  final double overallWinRate;
  final double averageKda;
  final Map<String, double> winRateByChampion;
  final List<double> kdaTrend;
  final Map<String, int> rolesPlayed;

  _ComputedStats({
    required this.totalGames,
    required this.overallWinRate,
    required this.averageKda,
    required this.winRateByChampion,
    required this.kdaTrend,
    required this.rolesPlayed,
  });
}

class _ChampStat {
  int games = 0;
  int wins = 0;
}

// ============= UI COMPONENTS =============

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
        fontSize: 14,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============= CHARTS =============

class _ChampionWinRateChart extends StatelessWidget {
  final Map<String, double> data;
  const _ChampionWinRateChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final entries = data.entries.toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: AppColors.surfaceLight,
            getTooltipItem: (group, _, rod, __) {
              return BarTooltipItem(
                '${entries[group.x.toInt()].key}\n${rod.toY.toStringAsFixed(1)}%',
                const TextStyle(color: AppColors.primary),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 25,
              getTitlesWidget: (value, _) => Text(
                '${value.toInt()}%',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= entries.length) return const SizedBox();
                final name = entries[i].key;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    name.length > 6 ? '${name.substring(0, 5)}.' : name,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: AppColors.border,
            strokeWidth: 0.5,
          ),
        ),
        barGroups: List.generate(entries.length, (i) {
          final value = entries[i].value;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: value,
                color: value >= 50 ? AppColors.victory : AppColors.defeat,
                width: 22,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _KdaLineChart extends StatelessWidget {
  final List<double> kdaList;
  const _KdaLineChart({required this.kdaList});

  @override
  Widget build(BuildContext context) {
    if (kdaList.isEmpty) return const Center(child: Text('No data'));

    final maxY = kdaList.reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY * 1.2,
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: AppColors.border,
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, _) => Text(
                value.toStringAsFixed(1),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: (kdaList.length / 5).ceilToDouble().clamp(1, 100),
              getTitlesWidget: (value, _) => Text(
                'M${value.toInt() + 1}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              kdaList.length,
              (i) => FlSpot(i.toDouble(), kdaList[i]),
            ),
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            dotData: FlDotData(
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 3,
                color: AppColors.primary,
                strokeWidth: 1.5,
                strokeColor: AppColors.background,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.3),
                  AppColors.primary.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RolePieChart extends StatelessWidget {
  final Map<String, int> roleDistribution;
  const _RolePieChart({required this.roleDistribution});

  @override
  Widget build(BuildContext context) {
    if (roleDistribution.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final entries = roleDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<int>(0, (s, e) => s + e.value);

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: entries.map((e) {
                final color =
                    AppColors.roleColors[e.key] ?? AppColors.primary;
                final percentage = (e.value / total) * 100;
                return PieChartSectionData(
                  color: color,
                  value: e.value.toDouble(),
                  title: '${percentage.toStringAsFixed(0)}%',
                  radius: 60,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries.map((e) {
              final color =
                  AppColors.roleColors[e.key] ?? AppColors.primary;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: color,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${e.key}: ${e.value}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
