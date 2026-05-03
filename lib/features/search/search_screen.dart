import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';
import '../profile/profile_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _nameController = TextEditingController();
  final _tagController = TextEditingController(text: 'LAN');
  bool _isSearching = false;

  @override
  void dispose() {
    _nameController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSearching = true);

    try {
      final summoner = await ref.read(
        summonerSearchProvider((
          name: name,
          tag: _tagController.text.trim(),
        )).future,
      );

      ref.read(currentSummonerProvider.notifier).state = summoner;
      ref.invalidate(recentSearchesProvider);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileScreen(summoner: summoner),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.defeat,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recentAsync = ref.watch(recentSearchesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('LOL STATS')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.paddingL),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.surface, AppColors.surfaceLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusL),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shield,
                        color: AppColors.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Summoner Search',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Discover stats, ranks, and match history',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.paddingL),

            // Search inputs
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _nameController,
                    onSubmitted: (_) => _search(),
                    decoration: const InputDecoration(
                      hintText: 'Game name',
                      prefixIcon: Icon(Icons.person, color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    '#',
                    style: TextStyle(
                      fontSize: 22,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    onSubmitted: (_) => _search(),
                    decoration: const InputDecoration(hintText: 'TAG'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingM),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSearching ? null : _search,
                icon: _isSearching
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.background,
                        ),
                      )
                    : const Icon(Icons.search),
                label: Text(_isSearching ? 'SEARCHING...' : 'SEARCH'),
              ),
            ),

            const SizedBox(height: AppSizes.paddingL),

            // Recent searches
            recentAsync.when(
              data: (recents) {
                if (recents.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent searches',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        TextButton(
                          onPressed: () async {
                            await ref
                                .read(dbProvider)
                                .clearRecentSearches();
                            ref.invalidate(recentSearchesProvider);
                          },
                          child: const Text(
                            'Clear',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...recents.map(
                      (r) => Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.history,
                            color: AppColors.primary,
                          ),
                          title: Text(
                            '${r['name']}#${r['tag_line']}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: AppColors.textSecondary,
                          ),
                          onTap: () {
                            _nameController.text = r['name'];
                            _tagController.text = r['tag_line'] ?? '';
                            _search();
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
