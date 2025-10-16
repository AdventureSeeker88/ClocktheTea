import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../Const/AppColors.dart';

class TeaController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  RxList<Map<String, dynamic>> userTeas = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> publicTeas = <Map<String, dynamic>>[].obs;

  /// 🔹 Upload Image/Video to Firebase Storage (Optional content)
  Future<String?> _uploadContent(File? file, bool isVideo) async {
    if (file == null) return null;
    try {
      String path = isVideo ? 'tea_videos' : 'tea_images';
      String fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref = _storage.ref().child('$path/$fileName');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      Get.snackbar('Upload Error', e.toString());
      return null;
    }
  }

  /// 🔹 Create Tea Post
  Future<void> createTea({
    File? contentFile,
    required bool isVideo,
    required String teaMoment,
    required List<String> hashtags,
    required String privacy,
    List<String>? tagged,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      String? contentUrl = await _uploadContent(contentFile, isVideo);

      final teaData = {
        'userId': user.uid,
        'contentUrl': contentUrl,
        'isVideo': isVideo,
        'teaMoment': teaMoment,
        'hashtags': hashtags,
        'privacy': privacy,
        'totalViews': 0,
        'comments': [],
        'likes': [],
        'shares': [],
        'reports': [],
        'tagged': tagged ?? [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('teas').add(teaData);

      Get.snackbar('Success', 'Tea posted successfully!');
      fetchUserTeas(); // refresh user teas
      fetchPublicTeas(); // refresh global teas
    } catch (e) {
      Get.snackbar('Error', 'Failed to post tea: $e');
    }
  }

  /// 🔹 Fetch Current User’s Teas (no index needed)
  Future<void> fetchUserTeas() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // ✅ Remove orderBy to avoid needing an index
      final query = await _firestore
          .collection('teas')
          .where('userId', isEqualTo: user.uid)
          .get();

      // ✅ Manually sort by createdAt descending
      final teas = query.docs
          .map((d) => {'id': d.id, ...d.data()})
          .toList()
        ..sort((a, b) {
          final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
          final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
          return bTime.compareTo(aTime);
        });

      userTeas.assignAll(teas);
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch user teas: $e');
    }
  }

  /// 🔹 Fetch Public Teas (others, no index needed)
  Future<void> fetchPublicTeas() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // ✅ Remove orderBy to avoid index requirement
      final query = await _firestore
          .collection('teas')
          .where('privacy', isEqualTo: 'public')
          .get();

      // ✅ Filter out current user’s teas and sort manually
      final teas = query.docs
          .where((d) => d['userId'] != user.uid)
          .map((d) => {'id': d.id, ...d.data()})
          .toList()
        ..sort((a, b) {
          final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
          final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
          return bTime.compareTo(aTime);
        });

      publicTeas.assignAll(teas);
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch public teas: $e');
    }
  }


  /// 🔹 Like or Unlike Tea
  Future<void> toggleLike(String teaId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final docRef = _firestore.collection('teas').doc(teaId);
      final doc = await docRef.get();
      List likes = doc['likes'];

      if (likes.contains(user.uid)) {
        likes.remove(user.uid);
      } else {
        likes.add(user.uid);
      }

      await docRef.update({'likes': likes});
      fetchPublicTeas();
      fetchUserTeas();
    } catch (e) {
      Get.snackbar('Error', 'Failed to like/unlike tea: $e');
    }
  }

  /// 🔹 Add Comment
  Future<void> addComment(String teaId, String comment, {String? parentCommentId}) async {
    try {
      print('🟢 Starting to add ${parentCommentId == null ? "comment" : "reply"}...');
      print('Tea ID: $teaId');
      print('Text: $comment');
      if (parentCommentId != null) print('Parent Comment ID: $parentCommentId');

      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No user logged in. Cannot add comment.');
        Get.snackbar('Error', 'Please log in to comment.');
        return;
      }

      final userId = user.uid;
      final commentData = {
        'userId': userId,
        'comment': comment.trim(),
        'timestamp': Timestamp.now(),
        'replies': [],
      };

      final docRef = _firestore.collection('teas').doc(teaId);
      final teaSnapshot = await docRef.get();

      if (!teaSnapshot.exists) {
        print('❌ Tea post not found for ID: $teaId');
        Get.snackbar('Error', 'Tea post not found.');
        return;
      }

      final teaData = teaSnapshot.data() as Map<String, dynamic>;
      final comments = List<Map<String, dynamic>>.from(teaData['comments'] ?? []);

      // If reply to another comment
      if (parentCommentId != null) {
        final updatedComments = comments.map((commentItem) {
          if (commentItem['timestamp'].toString() == parentCommentId) {
            final replies = List<Map<String, dynamic>>.from(commentItem['replies'] ?? []);
            replies.add({
              'userId': userId,
              'comment': comment.trim(),
              'timestamp': Timestamp.now(),
            });
            commentItem['replies'] = replies;
          }
          return commentItem;
        }).toList();

        await docRef.update({'comments': updatedComments});
        print('✅ Reply added successfully.');
      }
      // If new comment
      else {
        await docRef.update({
          'comments': FieldValue.arrayUnion([commentData]),
        });
        print('✅ Comment added successfully.');
      }

      // Refresh data after update
      await fetchPublicTeas();
      await fetchUserTeas();

    } catch (e) {
      print('❌ Error adding comment/reply: $e');
      Get.snackbar('Error', 'Failed to post comment. Please try again.');
    }
  }



  /// 🔹 Delete Tea
  Future<void> deleteTea(String teaId) async {
    try {
      await _firestore.collection('teas').doc(teaId).delete();
      Get.snackbar('Deleted', 'Tea removed successfully');
      fetchUserTeas();
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete tea: $e');
    }
  }

  /// 🔹 Save Tea to User’s Saved Collection
  Future<void> saveTea(String teaId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('savedTeas')
          .doc(teaId)
          .set({'savedAt': FieldValue.serverTimestamp()});

      Get.snackbar('Saved', 'Tea saved successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to save tea: $e');
    }
  }

  /// 🔹 Fetch Saved Teas
  Future<List<Map<String, dynamic>>> fetchSavedTeas() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final savedDocs = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('savedTeas')
          .get();

      final savedTeaIds = savedDocs.docs.map((d) => d.id).toList();

      if (savedTeaIds.isEmpty) return [];

      final teasQuery = await _firestore
          .collection('teas')
          .where(FieldPath.documentId, whereIn: savedTeaIds)
          .get();

      return teasQuery.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch saved teas: $e');
      return [];
    }
  }

  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  Future<void> sendFollowRequest(String targetUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      print('📤 Sending follow request to user: $targetUserId');

      await _firestore.collection('users').doc(targetUserId).update({
        'Requests': FieldValue.arrayUnion([currentUser.uid]),
      });

      Get.snackbar(
        'Request Sent',
        'Your follow request has been sent successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.teal.withOpacity(0.1),
        colorText: AppColors.textPrimary,
      );

      print('✅ Follow request successfully added in Firestore');
    } catch (e) {
      print('❌ Error sending follow request: $e');
      Get.snackbar('Error', 'Failed to send follow request: $e');
    }
  }

}
