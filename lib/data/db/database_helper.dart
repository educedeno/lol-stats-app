import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/summoner.dart';

/// Almacenamiento en Firestore (sin auth, datos compartidos).
///
/// Estructura:
///   favorite_summoners/{puuid}
///   favorite_champions/{championId}
///   recent_searches/{autoId}
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static const _maxRecentSearches = 10;

  DatabaseHelper._init();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _favSummoners =>
      _db.collection('favorite_summoners');
  CollectionReference<Map<String, dynamic>> get _favChampions =>
      _db.collection('favorite_champions');
  CollectionReference<Map<String, dynamic>> get _recents =>
      _db.collection('recent_searches');

  // ============= FAVORITE SUMMONERS =============

  Future<void> addFavoriteSummoner(Summoner summoner) async {
    await _favSummoners.doc(summoner.puuid).set({
      ...summoner.toMap(),
      'added_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> removeFavoriteSummoner(String puuid) async {
    await _favSummoners.doc(puuid).delete();
  }

  Future<bool> isFavoriteSummoner(String puuid) async {
    final doc = await _favSummoners.doc(puuid).get();
    return doc.exists;
  }

  Future<List<Summoner>> getFavoriteSummoners() async {
    final snap =
        await _favSummoners.orderBy('added_at', descending: true).get();
    return snap.docs.map((d) => Summoner.fromMap(d.data())).toList();
  }

  // ============= FAVORITE CHAMPIONS =============

  Future<void> addFavoriteChampion(int id, String name) async {
    await _favChampions.doc(id.toString()).set({
      'champion_id': id,
      'champion_name': name,
      'added_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> removeFavoriteChampion(int id) async {
    await _favChampions.doc(id.toString()).delete();
  }

  Future<bool> isFavoriteChampion(int id) async {
    final doc = await _favChampions.doc(id.toString()).get();
    return doc.exists;
  }

  Future<List<Map<String, dynamic>>> getFavoriteChampions() async {
    final snap =
        await _favChampions.orderBy('added_at', descending: true).get();
    return snap.docs.map((d) => d.data()).toList();
  }

  // ============= RECENT SEARCHES =============

  Future<void> addRecentSearch(String name, String tagLine) async {
    final existing = await _recents
        .where('name', isEqualTo: name)
        .where('tag_line', isEqualTo: tagLine)
        .get();
    for (final doc in existing.docs) {
      await doc.reference.delete();
    }

    await _recents.add({
      'name': name,
      'tag_line': tagLine,
      'searched_at': DateTime.now().millisecondsSinceEpoch,
    });

    final all =
        await _recents.orderBy('searched_at', descending: true).get();
    if (all.docs.length > _maxRecentSearches) {
      for (var i = _maxRecentSearches; i < all.docs.length; i++) {
        await all.docs[i].reference.delete();
      }
    }
  }

  Future<List<Map<String, dynamic>>> getRecentSearches() async {
    final snap = await _recents
        .orderBy('searched_at', descending: true)
        .limit(_maxRecentSearches)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  Future<void> clearRecentSearches() async {
    final snap = await _recents.get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }
}
