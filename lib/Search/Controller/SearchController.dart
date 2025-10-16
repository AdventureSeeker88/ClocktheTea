// search_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class SearchsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Reactive variables
  RxList<Map<String, dynamic>> searchResults = <Map<String, dynamic>>[].obs;
  RxList<String> trendingHashtags = <String>[].obs;
  RxList<String> searchHistory = <String>[].obs;
  RxBool isLoading = false.obs;
  RxString currentQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTrendingHashtags();
    loadSearchHistory();
  }


  /// 🔹 Update like status in search results
  void updateLikeStatus(String teaId, List<dynamic> updatedLikes) {
    final index = searchResults.indexWhere((tea) => tea['id'] == teaId);
    if (index != -1) {
      searchResults[index]['likes'] = updatedLikes;
      searchResults.refresh(); // This triggers UI update
    }
  }

  /// 🔹 Toggle like with immediate UI update
  Future<void> toggleLikeWithUpdate(String teaId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Find the tea in search results
      final teaIndex = searchResults.indexWhere((tea) => tea['id'] == teaId);
      if (teaIndex == -1) return;

      final currentTea = searchResults[teaIndex];
      List likes = List.from(currentTea['likes'] ?? []);

      // Update locally first for immediate UI response
      if (likes.contains(user.uid)) {
        likes.remove(user.uid);
      } else {
        likes.add(user.uid);
      }

      // Update local state immediately
      searchResults[teaIndex]['likes'] = likes;
      searchResults.refresh();

      // Then update in Firestore
      final docRef = _firestore.collection('teas').doc(teaId);
      await docRef.update({'likes': likes});

    } catch (e) {
      print('Error toggling like: $e');
      // Revert local changes if Firestore update fails
      searchResults.refresh();
      Get.snackbar('Error', 'Failed to like/unlike tea: $e');
    }
  }

  /// 🔹 Fetch trending hashtags from all teas
  Future<void> fetchTrendingHashtags() async {
    try {
      final teasSnapshot = await _firestore.collection('teas').get();

      // Count hashtag frequency
      final hashtagCount = <String, int>{};

      for (final doc in teasSnapshot.docs) {
        final hashtags = List<String>.from(doc['hashtags'] ?? []);
        for (final hashtag in hashtags) {
          hashtagCount[hashtag] = (hashtagCount[hashtag] ?? 0) + 1;
        }
      }

      // Sort by frequency and get top 10
      final sortedHashtags = hashtagCount.entries
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      trendingHashtags.assignAll(
          sortedHashtags.take(10).map((e) => e.key).toList()
      );

    } catch (e) {
      print('Error fetching trending hashtags: $e');
    }
  }

  /// 🔹 Search teas by hashtags, content, or user
  Future<void> searchTeas(String query) async {
    if (query.isEmpty) {
      searchResults.clear();
      return;
    }

    try {
      isLoading.value = true;
      currentQuery.value = query;

      // Add to search history
      await _addToSearchHistory(query);

      final teasSnapshot = await _firestore
          .collection('teas')
          .where('privacy', isEqualTo: 'public')
          .get();

      final results = teasSnapshot.docs
          .where((doc) {
        final data = doc.data();
        final hashtags = List<String>.from(data['hashtags'] ?? []);
        final teaMoment = data['teaMoment']?.toString().toLowerCase() ?? '';
        final queryLower = query.toLowerCase();

        // Check if query matches any hashtag (exact match for hashtags)
        final hashtagMatch = hashtags.any((hashtag) =>
            hashtag.toLowerCase().contains(queryLower));

        // Check if query matches tea moment content
        final contentMatch = teaMoment.contains(queryLower);

        return hashtagMatch || contentMatch;
      })
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList()
        ..sort((a, b) {
          // Sort by creation date (newest first)
          final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
          final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
          return bTime.compareTo(aTime);
        });

      searchResults.assignAll(results);
    } catch (e) {
      print('Error searching teas: $e');
      Get.snackbar('Error', 'Failed to search: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 🔹 Add search query to user's search history
  Future<void> _addToSearchHistory(String query) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Remove query if it already exists (to avoid duplicates)
      searchHistory.remove(query);

      // Add to beginning of list
      searchHistory.insert(0, query);

      // Keep only last 10 searches
      if (searchHistory.length > 10) {
        searchHistory.removeLast();
      }

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({
        'searchHistory': searchHistory,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving search history: $e');
    }
  }

  /// 🔹 Load user's search history
  Future<void> loadSearchHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final history = List<String>.from(userDoc['searchHistory'] ?? []);
        searchHistory.assignAll(history);
      }
    } catch (e) {
      print('Error loading search history: $e');
    }
  }

  /// 🔹 Clear search history
  Future<void> clearSearchHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      searchHistory.clear();

      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({
        'searchHistory': [],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar('Cleared', 'Search history cleared');
    } catch (e) {
      Get.snackbar('Error', 'Failed to clear history: $e');
    }
  }

  /// 🔹 Clear current search
  void clearSearch() {
    currentQuery.value = '';
    searchResults.clear();
  }
}