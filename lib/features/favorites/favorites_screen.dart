import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';
import '../profile/profile_screen.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('FAVORITES')),
      body: favorites.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.star_border,
                      size: 80,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No favorite summoners yet',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Search for a summoner and tap the star',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              itemCount: favorites.length,
              itemBuilder: (context, i) {
                final summoner = favorites[i];
                return Card(
                  child: ListTile(
                    leading: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: summoner.profileIconUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 48,
                          height: 48,
                          color: AppColors.surfaceLight,
                          child: const Icon(Icons.person),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 48,
                          height: 48,
                          color: AppColors.surfaceLight,
                          child: const Icon(Icons.person),
                        ),
                      ),
                    ),
                    title: Text(
                      summoner.fullName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Level ${summoner.summonerLevel}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.defeat,
                      ),
                      onPressed: () {
                        ref
                            .read(favoritesProvider.notifier)
                            .remove(summoner.puuid);
                      },
                    ),
                    onTap: () {
                      ref.read(currentSummonerProvider.notifier).state =
                          summoner;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileScreen(summoner: summoner),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
