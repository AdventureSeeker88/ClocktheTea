import 'dart:io';
import 'package:clock_tea/MainScreen.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  RxBool isSaving = false.obs;
  RxBool isLoading = false.obs;

  /// ✅ User profile data stored here
  RxMap<String, dynamic> userProfile = <String, dynamic>{}.obs;

  /// ✅ Uploads an image to Firebase Storage and returns the URL
  Future<String> _uploadImage(File imageFile, String userId) async {
    final ref = _storage.ref().child('profile_images/$userId.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  /// ✅ Save or update user profile
  Future<void> saveUserProfile({
    required String profileImage,
    required String username,
    required String pronun,
    required String sexualOrientations,
    required int age,
    required String bio,
    bool privateAccount = false,
    bool allowComment = false,
    bool allowTags = false,
    bool pushNotifications = true,
    bool likeNotifications = true,
    bool commentsNotifications = true,
    bool newFollowers = true,
    bool newTeaPost = true,
    bool teaRecommendations = true,
  }) async {
    try {
      isSaving.value = true;
      final User? user = _auth.currentUser;

      if (user == null) {
        Get.snackbar('Error', 'User not logged in.');
        return;
      }

      String imageUrl = profileImage;

      // ✅ If user selected a gallery image (local file), upload it
      if (File(profileImage).existsSync()) {
        imageUrl = await _uploadImage(File(profileImage), user.uid);
      }

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'profileImage': imageUrl,
        'username': username,
        'pronun': pronun,
        'sexual_orientations': sexualOrientations,
        'age': age,
        'bio': bio,
        'followers':[],
        'following':[],
        'Requests':[],
        'privacy': {
          'private_account': privateAccount,
          'allow_comment': allowComment,
          'allow_tags': allowTags,
        },
        'notifications': {
          'push_notifications': pushNotifications,
          'like_notifications': likeNotifications,
          'comments_notifications': commentsNotifications,
          'new_followers': newFollowers,
          'new_tea_post': newTeaPost,
          'tea_recommendations': teaRecommendations,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'Success',
        'Your profile has been saved!',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.offAll(()=> MainShell());
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSaving.value = false;
    }
  }

  /// ✅ Fetch user profile from Firestore
  Future<void> fetchUserProfile() async {
    try {
      isLoading.value = true;
      final User? user = _auth.currentUser;

      if (user == null) {
        Get.snackbar('Error', 'User not logged in.');
        return;
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        userProfile.value = doc.data() ?? {};
      } else {
        userProfile.clear();
        Get.snackbar('Notice', 'No profile data found.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch profile: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// ✅ Save or update user profile info (general info)
  Future<void> updateProfileInfo({
    String? username,
    String? pronun,
    String? sexualOrientations,
    int? age,
    String? bio,
    String? profileImage,
  }) async {
    try {
      print("🔄 Starting profile update...");
      isSaving.value = true;

      final user = _auth.currentUser;
      if (user == null) {
        print("❌ No user found.");
        return;
      }

      print("✅ Current user UID: ${user.uid}");

      Map<String, dynamic> updates = {};

      if (username != null) updates['username'] = username;
      if (pronun != null) updates['pronun'] = pronun;
      if (sexualOrientations != null) updates['sexual_orientations'] = sexualOrientations;
      if (age != null) updates['age'] = age;
      if (bio != null) updates['bio'] = bio;

      // ✅ Handle profile image (gallery or asset)
      if (profileImage != null) {
        if (profileImage.startsWith('assets/')) {
          // It's a built-in avatar → save asset path directly
          print("🖼️ Using built-in avatar: $profileImage");
          updates['profileImage'] = profileImage;
        } else if (File(profileImage).existsSync()) {
          // It's a gallery image → upload it
          print("📸 Uploading gallery image: $profileImage");
          final imageUrl = await _uploadImage(File(profileImage), user.uid);
          updates['profileImage'] = imageUrl;
          print("✅ Gallery image uploaded successfully: $imageUrl");
        } else {
          print("⚠️ Invalid image path: $profileImage");
        }
      }

      print("📤 Updating Firestore document for UID: ${user.uid}");
      await _firestore.collection('users').doc(user.uid).update(updates);
      print("✅ Firestore document updated successfully!");

      await fetchUserProfile(); // refresh data
      print("🔁 User profile refreshed successfully.");

      Get.snackbar('Success', 'Profile info updated successfully.');
    } catch (e) {
      print("❌ Error while updating profile: $e");
      Get.snackbar('Error', 'Failed to update profile: $e');
    } finally {
      isSaving.value = false;
      print("🏁 Profile update process completed.");
    }
  }


  /// ✅ Update privacy settings
  Future<void> updatePrivacySettings({
    bool? privateAccount,
    bool? allowComment,
    bool? allowTags,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      Map<String, dynamic> updates = {};
      if (privateAccount != null) updates['privacy.private_account'] = privateAccount;
      if (allowComment != null) updates['privacy.allow_comment'] = allowComment;
      if (allowTags != null) updates['privacy.allow_tags'] = allowTags;

      await _firestore.collection('users').doc(user.uid).update(updates);
      await fetchUserProfile();

      // Get.snackbar('Success', 'Privacy settings updated.');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update privacy: $e');
    }
  }


  /// ✅ Update notification settings
  Future<void> updateNotificationSettings({
    bool? pushNotifications,
    bool? likeNotifications,
    bool? commentsNotifications,
    bool? newFollowers,
    bool? newTeaPost,
    bool? teaRecommendations,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      Map<String, dynamic> updates = {};
      if (pushNotifications != null) updates['notifications.push_notifications'] = pushNotifications;
      if (likeNotifications != null) updates['notifications.like_notifications'] = likeNotifications;
      if (commentsNotifications != null) updates['notifications.comments_notifications'] = commentsNotifications;
      if (newFollowers != null) updates['notifications.new_followers'] = newFollowers;
      if (newTeaPost != null) updates['notifications.new_tea_post'] = newTeaPost;
      if (teaRecommendations != null) updates['notifications.tea_recommendations'] = teaRecommendations;

      await _firestore.collection('users').doc(user.uid).update(updates);
      await fetchUserProfile();

      Get.snackbar('Success', 'Notification settings updated.');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update notifications: $e');
    }
  }
}

