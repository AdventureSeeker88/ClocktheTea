import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FollowController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Rx variables for state management
  final RxMap<String, bool> _loadingStates = <String, bool>{}.obs;
  final RxBool _isLoading = false.obs;

  bool isLoading(String uid) => _loadingStates[uid] ?? false;

  //.........................getFollowRequests..........................................
  Stream<List<Map<String, dynamic>>> getFollowRequests() {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      print('❌ No user logged in — cannot fetch follow requests.');
      return const Stream.empty();
    }

    print('👤 Fetching follow requests for User ID: ${currentUser.uid}');

    return _firestore.collection('users').doc(currentUser.uid).snapshots().map((doc) async {
      print('📡 Received snapshot for current user.');

      if (!doc.exists) {
        print('⚠️ User document does not exist in Firestore.');
        return <Map<String, dynamic>>[];
      }

      final data = doc.data() ?? {};
      final List<String> requests = List<String>.from(data['Requests'] ?? []);
      print('📋 Requests field found: ${requests.length} request(s).');

      if (requests.isEmpty) {
        print('ℹ️ No follow requests found for this user.');
        return <Map<String, dynamic>>[];
      }

      final List<Map<String, dynamic>> requesterDetails = [];

      for (String uid in requests) {
        print('🔍 Fetching requester data for UID: $uid');
        try {
          final userDoc = await _firestore.collection('users').doc(uid).get();

          if (userDoc.exists) {
            print('✅ Requester document found for UID: $uid');

            final userData = userDoc.data() ?? {};
            final privacy = userData['privacy'] ?? {};
            final bool isPrivate = privacy['private_account'] ?? false;

            final requesterData = {
              'uid': uid,
              'isPrivate': isPrivate,
              'username': isPrivate ? 'Anonymous' : (userData['username'] ?? 'Unknown'),
              'profileImage': isPrivate ? '' : (userData['profileImage'] ?? ''),
              'timestamp': userData['requestTimestamp'] ?? FieldValue.serverTimestamp(),
            };

            print('📝 Requester data (with privacy check): $requesterData');
            requesterDetails.add(requesterData);
          } else {
            print('⚠️ No user document found for requester UID: $uid');
          }
        } catch (e) {
          print('❌ Error fetching requester data for $uid: $e');
        }
      }

      print('✅ Final requester details list prepared: ${requesterDetails.length} user(s).');
      return requesterDetails;
    }).asyncExpand((f) => Stream.fromFuture(f));
  }



  //.........................accept followers................................
  Future<void> acceptFollowRequest(String requesterId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Set loading state
    _loadingStates[requesterId] = true;
    _loadingStates.refresh();

    final batch = _firestore.batch();

    try {
      final currentUserRef = _firestore.collection('users').doc(currentUser.uid);
      final requesterRef = _firestore.collection('users').doc(requesterId);

      // ✅ 1. Remove request from current user's Requests
      batch.update(currentUserRef, {
        'Requests': FieldValue.arrayRemove([requesterId]),
        'followers': FieldValue.arrayUnion([requesterId]),
      });

      // ✅ 2. Add accepter to requester's following list
      batch.update(requesterRef, {
        'following': FieldValue.arrayUnion([currentUser.uid]),
      });

      await batch.commit();

      Get.snackbar(
        'Follow Accepted',
        'You are now following each other.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      print('✅ Follow request accepted: $requesterId');
    } catch (e) {
      print('❌ Error accepting follow request: $e');
      Get.snackbar(
        'Error',
        'Failed to accept request',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
      );
    } finally {
      // Clear loading state
      _loadingStates[requesterId] = false;
      _loadingStates.refresh();
    }
  }

  //.........................ignore follow request................................
  Future<void> ignoreFollowRequest(String requesterId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    _loadingStates[requesterId] = true;
    _loadingStates.refresh();

    try {
      await _firestore.collection('users').doc(currentUser.uid).update({
        'Requests': FieldValue.arrayRemove([requesterId]),
      });

      Get.snackbar(
        'Request Ignored',
        'Follow request has been removed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.grey[800]!,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      print('✅ Follow request ignored: $requesterId');
    } catch (e) {
      print('❌ Error ignoring follow request: $e');
      Get.snackbar(
        'Error',
        'Failed to ignore request',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
      );
    } finally {
      _loadingStates[requesterId] = false;
      _loadingStates.refresh();
    }
  }


  /// Fetches followers of the current user
  Stream<List<Map<String, dynamic>>> getFollowers() {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      print('❌ No user logged in — cannot fetch followers.');
      return const Stream.empty();
    }

    print('👤 Fetching followers for user: ${currentUser.uid}');

    return _firestore.collection('users').doc(currentUser.uid).snapshots().map((doc) async {
      if (!doc.exists) {
        print('⚠️ User document not found.');
        return <Map<String, dynamic>>[];
      }

      final data = doc.data() ?? {};
      final List<String> followers = List<String>.from(data['followers'] ?? []);
      print('📋 Found ${followers.length} follower(s).');

      if (followers.isEmpty) return <Map<String, dynamic>>[];

      final List<Map<String, dynamic>> followerDetails = [];

      for (String uid in followers) {
        print('🔍 Fetching follower details for UID: $uid');
        try {
          final userDoc = await _firestore.collection('users').doc(uid).get();
          if (userDoc.exists) {
            final userData = userDoc.data() ?? {};
            final privacy = userData['privacy'] ?? {};
            final bool isPrivate = privacy['private_account'] ?? false;

            followerDetails.add({
              'uid': uid,
              'isPrivate': isPrivate,
              'username': isPrivate ? 'Anonymous' : (userData['username'] ?? 'Unknown'),
              'profileImage': isPrivate ? '' : (userData['profileImage'] ?? ''),
            });
          }
        } catch (e) {
          print('❌ Error fetching follower $uid: $e');
        }
      }

      print('✅ Loaded ${followerDetails.length} follower(s).');
      return followerDetails;
    }).asyncExpand((f) => Stream.fromFuture(f));
  }

  /// Fetches the users that the current user is following
  Stream<List<Map<String, dynamic>>> getFollowing() {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      print('❌ No user logged in — cannot fetch following list.');
      return const Stream.empty();
    }

    print('👤 Fetching following list for user: ${currentUser.uid}');

    return _firestore.collection('users').doc(currentUser.uid).snapshots().map((doc) async {
      if (!doc.exists) {
        print('⚠️ User document not found.');
        return <Map<String, dynamic>>[];
      }

      final data = doc.data() ?? {};
      final List<String> following = List<String>.from(data['following'] ?? []);
      print('📋 Found ${following.length} following user(s).');

      if (following.isEmpty) return <Map<String, dynamic>>[];

      final List<Map<String, dynamic>> followingDetails = [];

      for (String uid in following) {
        print('🔍 Fetching following user details for UID: $uid');
        try {
          final userDoc = await _firestore.collection('users').doc(uid).get();
          if (userDoc.exists) {
            final userData = userDoc.data() ?? {};
            final privacy = userData['privacy'] ?? {};
            final bool isPrivate = privacy['private_account'] ?? false;

            followingDetails.add({
              'uid': uid,
              'isPrivate': isPrivate,
              'username': isPrivate ? 'Anonymous' : (userData['username'] ?? 'Unknown'),
              'profileImage': isPrivate ? '' : (userData['profileImage'] ?? ''),
            });
          }
        } catch (e) {
          print('❌ Error fetching following user $uid: $e');
        }
      }

      print('✅ Loaded ${followingDetails.length} following user(s).');
      return followingDetails;
    }).asyncExpand((f) => Stream.fromFuture(f));
  }

  /// Unfollow another user
  Future<void> unfollowUser(String targetUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('❌ No user logged in — cannot unfollow.');
      return;
    }

    try {
      print('🚫 Unfollowing user: $targetUserId');

      final currentUserRef = _firestore.collection('users').doc(currentUser.uid);
      final targetUserRef = _firestore.collection('users').doc(targetUserId);

      // Remove from both lists
      await currentUserRef.update({
        'following': FieldValue.arrayRemove([targetUserId]),
      });

      await targetUserRef.update({
        'followers': FieldValue.arrayRemove([currentUser.uid]),
      });

      print('✅ Successfully unfollowed user: $targetUserId');
    } catch (e) {
      print('❌ Error during unfollow operation: $e');
      Get.snackbar('Error', 'Failed to unfollow user. Please try again.');
    }
  }


  @override
  void onClose() {
    _loadingStates.clear();
    super.onClose();
  }
}