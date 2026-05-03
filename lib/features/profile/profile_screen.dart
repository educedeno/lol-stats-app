import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';
import '../../data/models/summoner.dart';
import '../match_history/match_history_screen.dart';

class ProfileScreen extends ConsumerWidget {
  final Summoner summoner;
  const ProfileScreen({super.key, required this.summoner});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankedAsync = ref.watch(rankedInfoProvider(summoner.puuid));
    final masteryAsync = ref.watch(masteryProvider(summoner.puuid));
    final favorites = ref.watch(favoritesProvider);
    final isFavorite = favorites.any((s) => s.puuid == summoner.puuid);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            actions: [
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  color: AppColors.primary,
                ),
                onPressed: () {
                  ref.read(favoritesProvider.notifier).toggle(summoner);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isFavorite ? 'Removed from favorites' : 'Added to favorites',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background splash
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.surfaceLight, AppColors.background],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.background.withValues(alpha: 0.3),
                          AppColors.background,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Profile content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 3,
                            ),
                          ),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: summoner.profileIconUrl,
                              placeholder: (_, __) => Container(
                                color: AppColors.surface,
                                child: const Icon(
                                  Icons.person,
                                  color: AppColors.primary,
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: AppColors.surface,
                                child: const Icon(
                                  Icons.person,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          summoner.fullName,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary),
                          ),
                          child: Text(
                            'Level ${summoner.summonerLevel}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.history),
                        label: const Text('Matches'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  MatchHistoryScreen(summoner: summoner),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingL),

                // Ranked section
                Text(
                  'RANKED',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        letterSpacing: 2,
                      ),
                ),
                const SizedBox(height: 8),
                rankedAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, _) => Text('Error: $e'),
                  data: (ranks) {
                    if (ranks.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Unranked'),
                        ),
                      );
                    }
                    return Column(
                      children: ranks.map((r) => _RankCard(rank: r)).toList(),
                    );
                  },
                ),

                const SizedBox(height: AppSizes.paddingL),

                // Mastery section
                Text(
                  'TOP CHAMPIONS',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        letterSpacing: 2,
                      ),
                ),
                const SizedBox(height: 8),
                masteryAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (e, _) => Text('Error: $e'),
                  data: (masteries) {
                    return Column(
                      children: masteries.map((m) {
                        return Card(
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: m.iconUrl,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  width: 48,
                                  height: 48,
                                  color: AppColors.surfaceLight,
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  width: 48,
                                  height: 48,
                                  color: AppColors.surfaceLight,
                                  child: const Icon(Icons.shield),
                                ),
                              ),
                            ),
                            title: Text(
                              m.championName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${m.championPoints} pts',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.primary),
                              ),
                              child: Text(
                                'M${m.championLevel}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  final RankedInfo rank;
  const _RankCard({required this.rank});

  @override
  Widget build(BuildContext context) {
    final tierColor = AppColors.tierColors[rank.tier] ?? AppColors.textPrimary;
    final queueLabel = rank.queueType == 'RANKED_SOLO_5x5'
        ? 'Solo / Duo'
        : rank.queueType == 'RANKED_FLEX_SR'
            ? 'Flex'
            : rank.queueType;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tierColor.withValues(alpha: 0.2),
                border: Border.all(color: tierColor, width: 2),
              ),
              child: Icon(Icons.shield, color: tierColor, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    queueLabel,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    rank.fullRank,
                    style: TextStyle(
                      color: tierColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${rank.leaguePoints} LP',
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${rank.wins}W ${rank.losses}L',
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  '${rank.winRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: rank.winRate >= 50
                        ? AppColors.victory
                        : AppColors.defeat,
                    fontWeight: FontWeight.bold,
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
