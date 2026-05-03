import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';
import '../../data/models/summoner.dart';
import '../../data/models/match.dart';

class MatchHistoryScreen extends ConsumerWidget {
  final Summoner summoner;
  const MatchHistoryScreen({super.key, required this.summoner});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchHistoryProvider(summoner.puuid));

    return Scaffold(
      appBar: AppBar(title: Text('${summoner.name} - Matches')),
      body: matchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (matches) {
          if (matches.isEmpty) {
            return const Center(child: Text(AppStrings.noMatches));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(matchHistoryProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              itemCount: matches.length,
              itemBuilder: (context, i) {
                final match = matches[i];
                final p = match.participantByPuuid(summoner.puuid);
                if (p == null) return const SizedBox.shrink();
                return _MatchCard(match: match, participant: p);
              },
            ),
          );
        },
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final Match match;
  final Participant participant;
  const _MatchCard({required this.match, required this.participant});

  @override
  Widget build(BuildContext context) {
    final win = participant.win;
    final color = win ? AppColors.victory : AppColors.defeat;
    final roleColor =
        AppColors.roleColors[participant.displayRole] ?? AppColors.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          child: Column(
            children: [
              Row(
                children: [
                  // Champion icon
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: participant.championIconUrl,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            width: 56,
                            height: 56,
                            color: AppColors.surfaceLight,
                          ),
                          errorWidget: (_, __, ___) => Container(
                            width: 56,
                            height: 56,
                            color: AppColors.surfaceLight,
                            child: const Icon(Icons.shield),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: roleColor),
                          ),
                          child: Text(
                            participant.displayRole,
                            style: TextStyle(
                              color: roleColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Match info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                win ? 'VICTORY' : 'DEFEAT',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              match.gameMode,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          participant.championName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${match.timeAgo} • ${match.durationFormatted}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // KDA
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${participant.kills}',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(
                              text: ' / ',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            TextSpan(
                              text: '${participant.deaths}',
                              style: const TextStyle(
                                color: AppColors.defeat,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(
                              text: ' / ',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            TextSpan(
                              text: '${participant.assists}',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${participant.kda.toStringAsFixed(2)} KDA',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 12),

              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatChip(
                    icon: Icons.grass,
                    value: '${participant.cs}',
                    label: 'CS',
                  ),
                  _StatChip(
                    icon: Icons.monetization_on,
                    value: '${(participant.goldEarned / 1000).toStringAsFixed(1)}k',
                    label: 'Gold',
                  ),
                  _StatChip(
                    icon: Icons.local_fire_department,
                    value:
                        '${(participant.totalDamageDealtToChampions / 1000).toStringAsFixed(1)}k',
                    label: 'DMG',
                  ),
                  _StatChip(
                    icon: Icons.visibility,
                    value: '${participant.visionScore}',
                    label: 'Vision',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 16),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
