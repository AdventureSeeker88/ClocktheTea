// controllers/story_controller.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

import '../Model/StoryModel.dart';

class StoryController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final RxDouble _uploadProgress = 0.0.obs;
  final RxBool _isUploading = false.obs;
  final RxString _uploadStatus = ''.obs;

  double get uploadProgress => _uploadProgress.value;
  bool get isUploading => _isUploading.value;
  String get uploadStatus => _uploadStatus.value;

  // Get stories from users that current user follows INCLUDING own stories
  Stream<List<Story>> getFollowingStories() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .snapshots()
        .asyncMap((userDoc) async {
      if (!userDoc.exists) return <Story>[];

      final data = userDoc.data() ?? {};
      final List<String> following = List<String>.from(data['following'] ?? []);

      // Always include current user's stories
      if (!following.contains(currentUser.uid)) {
        following.add(currentUser.uid);
      }

      final List<Story> allStories = [];

      for (String userId in following) {
        final stories = await _getUserStories(userId);
        allStories.addAll(stories);
      }

      // Sort by creation time (newest first) and filter expired stories
      allStories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return allStories.where((story) => !story.isExpired).toList();
    });
  }

  // Get current user's own stories
  Stream<List<Story>> getMyStories() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const Stream.empty();

    return _firestore
        .collection('stories')
        .where('userId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final story = Story.fromMap(data, doc.id);

        dynamic expiresAt = data['expiresAt'];

        // ✅ Safely handle both Timestamp and DateTime
        DateTime? expiresAtDate;
        if (expiresAt is Timestamp) {
          expiresAtDate = expiresAt.toDate();
        } else if (expiresAt is DateTime) {
          expiresAtDate = expiresAt;
        } else {
          expiresAtDate = null;
        }

        return {'story': story, 'expiresAt': expiresAtDate};
      })
      // ✅ Filter expired stories
          .where((item) {
        final expiresAt = item['expiresAt'] as DateTime?;
        return expiresAt != null && expiresAt.isAfter(now);
      })
          .map((item) => item['story'] as Story)
          .toList();
    });
  }

  Future<List<Story>> _getUserStories(String userId) async {
    try {
      // First get all stories for this user, then filter and sort in memory
      final querySnapshot = await _firestore
          .collection('stories')
          .where('userId', isEqualTo: userId)
          .get();

      // Get user privacy info
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() ?? {};
      final privacy = userData['privacy'] ?? {};
      final bool isPrivateAccount = privacy['private_account'] ?? false;

      final now = DateTime.now();

      // Filter expired stories and add privacy info
      final stories = querySnapshot.docs
          .map((doc) {
        final storyData = doc.data();
        return Story.fromMap({
          ...storyData,
          'isPrivateAccount': isPrivateAccount,
        }, doc.id);
      })
          .where((story) => !story.isExpired)
          .toList();

      // Sort by expiration date (newest first) in memory
      stories.sort((a, b) => b.expiresAt.compareTo(a.expiresAt));

      return stories;
    } catch (e) {
      print('Error getting user stories: $e');
      return [];
    }
  }

  // Alternative method for getting user stories with better performance
  Future<List<Story>> _getUserStoriesOptimized(String userId) async {
    try {
      // Use a timestamp that's 24 hours ago to filter expired stories
      final twentyFourHoursAgo = Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 24))
      );

      // Query for stories created in the last 24 hours (not expired)
      final querySnapshot = await _firestore
          .collection('stories')
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThan: twentyFourHoursAgo)
          .orderBy('createdAt', descending: true)
          .get();

      // Get user privacy info
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() ?? {};
      final privacy = userData['privacy'] ?? {};
      final bool isPrivateAccount = privacy['private_account'] ?? false;

      return querySnapshot.docs
          .map((doc) {
        final storyData = doc.data();
        return Story.fromMap({
          ...storyData,
          'isPrivateAccount': isPrivateAccount,
        }, doc.id);
      })
          .toList();
    } catch (e) {
      print('Error getting user stories: $e');
      // Fallback to the simpler method if this fails
      return _getUserStoriesSimple(userId);
    }
  }

  // Simple method without complex queries
  Future<List<Story>> _getUserStoriesSimple(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('stories')
          .where('userId', isEqualTo: userId)
          .get();

      // Get user privacy info
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() ?? {};
      final privacy = userData['privacy'] ?? {};
      final bool isPrivateAccount = privacy['private_account'] ?? false;

      final now = DateTime.now();

      // Filter and sort in memory
      final stories = querySnapshot.docs
          .map((doc) {
        final storyData = doc.data();
        return Story.fromMap({
          ...storyData,
          'isPrivateAccount': isPrivateAccount,
        }, doc.id);
      })
          .where((story) => !story.isExpired)
          .toList();

      // Sort by creation time (newest first)
      stories.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return stories;
    } catch (e) {
      print('Error getting user stories: $e');
      return [];
    }
  }

  // Enhanced upload story with progress and preview
  Future<void> uploadStory(File mediaFile, StoryType type, {String? caption}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    _isUploading.value = true;
    _uploadProgress.value = 0.0;
    _uploadStatus.value = 'Preparing...';

    try {
      // Get user data
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) throw Exception('User not found');

      final userData = userDoc.data()!;
      final username = userData['username'] ?? 'Unknown';
      final profileImage = userData['profileImage'] ?? '';

      // Get privacy settings
      final privacy = userData['privacy'] ?? {};
      final bool isPrivateAccount = privacy['private_account'] ?? false;

      // Upload media to storage with progress tracking
      _uploadStatus.value = 'Uploading media...';
      final String fileExtension = path.extension(mediaFile.path).replaceFirst('.', '');
      final String fileName = 'stories/${currentUser.uid}/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      final Reference storageRef = _storage.ref().child(fileName);
      final UploadTask uploadTask = storageRef.putFile(
        mediaFile,
        SettableMetadata(
          contentType: type == StoryType.image ? 'image/jpeg' : 'video/mp4',
        ),
      );

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        _uploadProgress.value = progress;
        _uploadStatus.value = 'Uploading: ${progress.toStringAsFixed(1)}%';
      });

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      final String mediaUrl = await snapshot.ref.getDownloadURL();

      // Create story document
      _uploadStatus.value = 'Finalizing...';
      final storyId = _firestore.collection('stories').doc().id;
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 24));

      final story = Story(
        id: storyId,
        userId: currentUser.uid,
        username: username,
        userProfileImage: profileImage,
        mediaUrl: mediaUrl,
        caption: caption,
        createdAt: now,
        expiresAt: expiresAt,
        type: type,
        viewers: [], // Empty array for new story
        isPrivateAccount: isPrivateAccount, // Add privacy info
      );

      await _firestore.collection('stories').doc(storyId).set(story.toMap());

      // Success
      _uploadStatus.value = 'Success!';
      await Future.delayed(const Duration(milliseconds: 500));

      Get.back(); // Close upload dialog

      Get.snackbar(
        '🎉 Story Shared!',
        'Your story has been uploaded successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );

    } catch (e) {
      print('Error uploading story: $e');
      _uploadStatus.value = 'Upload failed';

      // More specific error handling
      String errorMessage = 'Failed to upload story. Please try again.';
      if (e.toString().contains('storage/unauthorized')) {
        errorMessage = 'Storage permission denied. Please check your settings.';
      } else if (e.toString().contains('storage/canceled')) {
        errorMessage = 'Upload was canceled. Please try again.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      }

      Get.snackbar(
        '❌ Upload Failed',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      _isUploading.value = false;
      _uploadProgress.value = 0.0;
      _uploadStatus.value = '';
    }
  }

  // Updated hasActiveStories to avoid composite index
  Stream<bool> hasActiveStories() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(false);

    return _firestore
        .collection('stories')
        .where('userId', isEqualTo: currentUser.uid)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      return snapshot.docs.any((doc) {
        final data = doc.data();
        final expiresAt = data['expiresAt'];
        DateTime? expiresAtDate;

        if (expiresAt is Timestamp) {
          expiresAtDate = expiresAt.toDate();
        } else if (expiresAt is DateTime) {
          expiresAtDate = expiresAt;
        }

        return expiresAtDate != null && expiresAtDate.isAfter(now);
      });
    });
  }

  // Pick image with compression options
  Future<File?> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) return File(image.path);
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  // Pick video with duration limit
  Future<File?> pickVideo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 30),
      );
      if (video != null) return File(video.path);
      return null;
    } catch (e) {
      print('Error picking video: $e');
      return null;
    }
  }

  // Delete story
  Future<void> deleteStory(String storyId) async {
    try {
      final storyDoc = await _firestore.collection('stories').doc(storyId).get();
      if (storyDoc.exists) {
        final story = Story.fromMap(storyDoc.data()!, storyId);

        // Delete from storage
        try {
          await _storage.refFromURL(story.mediaUrl).delete();
        } catch (e) {
          print('Error deleting media file: $e');
        }

        // Delete from firestore
        await _firestore.collection('stories').doc(storyId).delete();

        Get.snackbar(
          '🗑️ Story Deleted',
          'Your story has been removed',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.grey[800]!,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Error deleting story: $e');
      Get.snackbar(
        'Error',
        'Failed to delete story',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Mark story as viewed
  Future<void> markStoryAsViewed(String storyId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore.collection('stories').doc(storyId).update({
        'viewers': FieldValue.arrayUnion([currentUser.uid]),
      });
    } catch (e) {
      print('Error marking story as viewed: $e');
    }
  }

  // Get story viewers with user details
  Stream<List<Map<String, dynamic>>> getStoryViewers(String storyId) {
    return _firestore
        .collection('stories')
        .doc(storyId)
        .snapshots()
        .asyncMap((snapshot) async {
      if (!snapshot.exists) return [];

      final story = Story.fromMap(snapshot.data()!, snapshot.id);
      final List<Map<String, dynamic>> viewerDetails = [];

      for (String viewerId in story.viewers) {
        final userDoc = await _firestore.collection('users').doc(viewerId).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          viewerDetails.add({
            'uid': viewerId,
            'username': userData['username'] ?? 'Unknown',
            'profileImage': userData['profileImage'] ?? '',
          });
        }
      }

      return viewerDetails;
    });
  }

  // Auto-play next story after delay
  void startAutoPlay(AnimationController animationController, VoidCallback onComplete) {
    animationController.duration = const Duration(seconds: 5);
    animationController.forward().then((_) {
      onComplete();
    });
  }

  // Reset and restart animation
  void restartAnimation(AnimationController animationController) {
    animationController.reset();
    animationController.forward();
  }
}