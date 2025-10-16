// widgets/stories_section.dart (Updated)
import 'dart:io';
import 'package:clock_tea/Stories/Controller/StoryController.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'Model/StoryModel.dart';
import 'StoryUpload.dart';
import 'StoryViewScreen.dart';

class StoriesSection extends StatelessWidget {
  final StoryController _storyController = Get.put(StoryController());

  StoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: StreamBuilder<List<Story>>(
        stream: _storyController.getFollowingStories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingStories();
          }

          if (snapshot.hasError) {
            return _buildErrorState();
          }

          final stories = snapshot.data ?? [];
          final groupedStories = _groupStoriesByUser(stories);

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: groupedStories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildAddStoryButton();
              }

              final userStories = groupedStories[index - 1];
              return _buildStoryItem(userStories);
            },
          );
        },
      ),
    );
  }

  Widget _buildAddStoryButton() {
    return StreamBuilder<bool>(
      stream: _storyController.hasActiveStories(),
      builder: (context, snapshot) {
        final hasActiveStories = snapshot.data ?? false;

        return Container(
          margin: const EdgeInsets.only(right: 16),
          child: Column(
            children: [
              // Add Story Circle with different style if has active stories
              GestureDetector(
                onTap: _showUploadOptions,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasActiveStories
                        ? const LinearGradient(
                      colors: [Color(0xFF833AB4), Color(0xFFFD1D1D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                        : null,
                    border: Border.all(
                      color: hasActiveStories ? Colors.transparent : Colors.grey[300]!,
                      width: 2,
                    ),
                    color: hasActiveStories ? null : Colors.white,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        hasActiveStories ? Icons.auto_awesome_rounded : Icons.add_circle_rounded,
                        color: hasActiveStories ? Colors.white : Colors.deepPurple,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasActiveStories ? 'Your Story' : 'Add',
                        style: TextStyle(
                          color: hasActiveStories ? Colors.white : Colors.deepPurple,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hasActiveStories ? 'Add More' : 'Your Story',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStoryItem(List<Story> userStories) {
    final firstStory = userStories.first;
    final isOwnStory = firstStory.userId == _getCurrentUserId();
    final hasUnviewedStories = userStories.any((story) =>
    !story.viewers.contains(_getCurrentUserId()));

    // Check if account is private and it's not the current user's story
    final isPrivateAccount = firstStory.isPrivateAccount;
    final showAsAnonymous = isPrivateAccount && !isOwnStory;

    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          // Story Circle
          GestureDetector(
            onTap: () => _openStoryView(userStories, isOwnStory),
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasUnviewedStories || isOwnStory
                    ? const LinearGradient(
                  colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFF77737)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : LinearGradient(
                  colors: [Colors.grey[400]!, Colors.grey[600]!],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3.0),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Profile Image or Anonymous
                      if (showAsAnonymous)
                      // Anonymous display for private accounts
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey,
                          ),
                          child: const Icon(
                            Icons.lock_outline_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        )
                      else
                      // Actual profile image for public accounts or own stories
                        ClipOval(
                          child: Builder(
                            builder: (context) {
                              final imagePath = firstStory.userProfileImage ?? '';

                              // ✅ Handle empty or invalid URLs
                              if (imagePath.isEmpty) {
                                return Container(
                                  width: 64,
                                  height: 64,
                                  color: Colors.grey[200],
                                  child: Icon(Icons.person, color: Colors.grey[400]),
                                );
                              }

                              // ✅ Handle asset image (local path)
                              if (imagePath.startsWith('assets/') || imagePath.endsWith('.png') || imagePath.endsWith('.jpg')) {
                                return Image.asset(
                                  imagePath,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                );
                              }

                              // ✅ Handle Firebase Storage / Web URL
                              return CachedNetworkImage(
                                imageUrl: imagePath,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[200],
                                  child: Icon(Icons.person, color: Colors.grey[400]),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[200],
                                  child: Icon(Icons.person, color: Colors.grey[400]),
                                ),
                              );
                            },
                          ),
                        ),


                      // Own story indicator
                      if (isOwnStory)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.deepPurple,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 70,
            child: Text(
              showAsAnonymous ? 'Anonymous' : (isOwnStory ? 'Your Story' : firstStory.username),
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Create Story',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildUploadOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Photo',
                      subtitle: 'From gallery',
                      onTap: () => _pickAndPreviewMedia(StoryType.image),
                    ),
                    _buildUploadOption(
                      icon: Icons.video_library_rounded,
                      label: 'Video',
                      subtitle: 'Up to 30s',
                      onTap: () => _pickAndPreviewMedia(StoryType.video),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Stories disappear after 24 hours',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUploadOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF833AB4), Color(0xFFFD1D1D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndPreviewMedia(StoryType type) async {
    Get.back(); // Close bottom sheet

    File? mediaFile;
    if (type == StoryType.image) {
      mediaFile = await _storyController.pickImage();
    } else {
      mediaFile = await _storyController.pickVideo();
    }

    if (mediaFile != null) {
      // Show professional upload dialog with preview
      Get.dialog(
        StoryUploadDialog(
          mediaFile: mediaFile,
          type: type,
        ),
        barrierDismissible: false,
      );
    } else {
      Get.snackbar(
        'No Media Selected',
        'Please select a photo or video to share',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _openStoryView(List<Story> userStories, bool isOwnStory) {
    Get.to(() => StoryViewScreen(
      userStories: [userStories],
      initialIndex: 0,
      isOwnStory: isOwnStory,
    ));
  }

  List<List<Story>> _groupStoriesByUser(List<Story> stories) {
    final Map<String, List<Story>> grouped = {};

    for (final story in stories) {
      if (!grouped.containsKey(story.userId)) {
        grouped[story.userId] = [];
      }
      grouped[story.userId]!.add(story);
    }

    // Sort stories for each user by creation time
    grouped.forEach((userId, userStories) {
      userStories.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    });

    return grouped.values.toList();
  }

  String? _getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  // Loading and error states remain the same...
  Widget _buildLoadingStories() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(right: 16),
          child: Column(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300],
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 40,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Colors.grey[400],
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Failed to load stories',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}