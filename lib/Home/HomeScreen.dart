import 'package:clock_tea/Stories/Controller/StoryController.dart';
import 'package:clock_tea/Stories/StoriesSection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'dart:async';

import '../Const/AppColors.dart';
import '../Tea/Controller/TeaController.dart';
import '../Tea/FullScreenVideo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TeaController _teaController = Get.put(TeaController());
  final StoryController storyController=Get.put(StoryController());
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController comment=TextEditingController();

  // Video management
  final Map<String, VideoPlayerController> _videoControllers = {};
  final Map<String, ChewieController> _chewieControllers = {};
  final Map<String, bool> _videoInitialized = {};
  final Map<String, bool> _showVideoControls = {};
  final Map<String, Timer?> _controlHideTimers = {};
  final Map<String, Map<String, dynamic>> _userCache = {};
  final Map<String, bool> _videoMuted = {};

  @override
  void initState() {
    super.initState();
    _loadPublicTeas();
  }

  @override
  void dispose() {
    _disposeAllVideos();
    super.dispose();
  }


  final List<Story> stories = [
    Story(
      username: 'Your Story',
      imageUrl: 'https://picsum.photos/200',
      isOwn: true,
    ),
    Story(
      username: 'Alex Morgan',
      imageUrl: 'https://picsum.photos/201',
      isViewed: false,
    ),
    Story(
      username: 'Jordan Lee',
      imageUrl: 'https://picsum.photos/202',
      isViewed: false,
    ),
    Story(
      username: 'Taylor Swift',
      imageUrl: 'https://picsum.photos/203',
      isViewed: true,
    ),
    Story(
      username: 'Chris Evans',
      imageUrl: 'https://picsum.photos/204',
      isViewed: false,
    ),
    Story(
      username: 'Emma Watson',
      imageUrl: 'https://picsum.photos/205',
      isViewed: true,
    ),
  ];

  void _disposeAllVideos() {
    for (var controller in _chewieControllers.values) {
      controller.dispose();
    }
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    for (var timer in _controlHideTimers.values) {
      timer?.cancel();
    }
    _chewieControllers.clear();
    _videoControllers.clear();
    _videoInitialized.clear();
    _showVideoControls.clear();
    _controlHideTimers.clear();
    _videoMuted.clear();
  }

  Future<void> _loadPublicTeas() async {
    await _teaController.fetchPublicTeas();
    await storyController.getFollowingStories();
  }

  // Initialize video controller
  Future<void> _initializeVideo(String teaId, String videoUrl) async {
    if (_videoControllers.containsKey(teaId)) return;

    try {
      final videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await videoController.initialize();

      final chewieController = ChewieController(
        videoPlayerController: videoController,
        autoPlay: false,
        looping: true,
        showControls: false,
        allowFullScreen: false,
        allowMuting: true,
        showOptions: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.rosePink,
          handleColor: AppColors.rosePink,
          backgroundColor: Colors.grey.shade700,
          bufferedColor: Colors.grey.shade500,
        ),
      );

      setState(() {
        _videoControllers[teaId] = videoController;
        _chewieControllers[teaId] = chewieController;
        _videoInitialized[teaId] = true;
        _showVideoControls[teaId] = false;
        _videoMuted[teaId] = false;
      });
    } catch (e) {
      print('Failed to initialize video for tea $teaId: $e');
      setState(() {
        _videoInitialized[teaId] = false;
      });
    }
  }

  // Get user data with privacy check
  Future<Map<String, dynamic>> _getUserData(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId]!;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final bool isPrivate = userData['privacy']["private_account"] ?? false;

        final userInfo = {
          'username': isPrivate ? 'Anonymous' : (userData['username'] ?? 'Anonymous'),
          'profileImage': isPrivate ? null : userData['profileImage'],
          'isPrivate': isPrivate,
        };

        _userCache[userId] = userInfo;
        return userInfo;
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }

    // Return default data if user not found
    final defaultData = {
      'username': 'Anonymous',
      'profileImage': null,
      'isPrivate': true,
    };
    _userCache[userId] = defaultData;
    return defaultData;
  }


  // Handle video visibility for auto-play
  void _onVideoVisibilityChanged(String teaId, double visibility) {
    if (!_videoInitialized[teaId]!) return;

    final videoController = _videoControllers[teaId];
    if (videoController == null) return;

    if (visibility > 0.7) {
      if (!videoController.value.isPlaying) {
        videoController.play();
      }
    } else {
      if (videoController.value.isPlaying) {
        videoController.pause();
      }
      if (_showVideoControls[teaId]!) {
        setState(() {
          _showVideoControls[teaId] = false;
        });
      }
    }
  }

  // Toggle controls visibility
  void _toggleVideoControls(String teaId) {
    if (!_videoInitialized[teaId]!) return;

    setState(() {
      _showVideoControls[teaId] = !_showVideoControls[teaId]!;
    });

    _controlHideTimers[teaId]?.cancel();

    if (_showVideoControls[teaId]!) {
      _controlHideTimers[teaId] = Timer(Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showVideoControls[teaId] = false;
          });
        }
      });
    }
  }

  // Toggle video playback
  void _toggleVideoPlayback(String teaId) {
    final videoController = _videoControllers[teaId];
    if (videoController != null && _videoInitialized[teaId]!) {
      if (videoController.value.isPlaying) {
        videoController.pause();
      } else {
        videoController.play();
      }

      _controlHideTimers[teaId]?.cancel();
      _controlHideTimers[teaId] = Timer(Duration(seconds: 2), () {
        if (mounted && _showVideoControls[teaId]!) {
          setState(() {
            _showVideoControls[teaId] = false;
          });
        }
      });
    }
  }

  // Toggle mute
  void _toggleMute(String teaId) {
    if (_videoControllers.containsKey(teaId)) {
      setState(() {
        _videoMuted[teaId] = !(_videoMuted[teaId] ?? false);
        _videoControllers[teaId]!.setVolume(_videoMuted[teaId]! ? 0.0 : 1.0);
      });
    }
  }

  // Open full screen
  void _openFullScreen(String teaId) {
    if (!_videoInitialized[teaId]!) return;

    // Pause the video before opening fullscreen
    if (_videoControllers[teaId]!.value.isPlaying) {
      _videoControllers[teaId]!.pause();
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenVideoPage(
          videoController: _videoControllers[teaId]!,
          chewieController: _chewieControllers[teaId]!,
          isMuted: _videoMuted[teaId] ?? false,
          onMuteToggle: (muted) {
            setState(() {
              _videoMuted[teaId] = muted;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.deepPurple,
        elevation: 0,
        title: Text(
          'Clock the Tea',
          style: TextStyle(
            color: AppColors.textOnDark,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: AppColors.textOnDark),
            onPressed: () {},
          ),

        ],
      ),
      body: RefreshIndicator(
        backgroundColor: AppColors.deepPurple,
        color: AppColors.gold,
        onRefresh: _loadPublicTeas,
        child: Obx(() {
          final publicTeas = _teaController.publicTeas;

          if (publicTeas.isEmpty) {
            return Column(
              children: [
                StoriesSection(),
                _buildEmptyState(),
              ],
            );
          }

          return Column(
            children: [
              StoriesSection(),
              Expanded(
                child: ListView.builder(
                  itemCount: publicTeas.length,
                  itemBuilder: (context, index) {
                    final tea = publicTeas[index];
                    return _buildTeaPost(tea);
                  },
                ),
              ),
            ],
          );
        }),
      ),
    );
  }



  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_cafe,
              color: AppColors.deepPurple,
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              'No Teas Available',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share a tea moment or check back later for new posts!',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeaPost(Map<String, dynamic> tea) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getUserData(tea['userId']),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildPostSkeleton();
        }

        final userData = snapshot.data!;
        final isPrivate = userData['isPrivate'] ?? false;
        final username = isPrivate ? 'Anonymous' : userData['username'];
        final profileImage = isPrivate ? null : userData['profileImage'];

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.deepPurple.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post Header
              _buildPostHeader(tea, username, profileImage, isPrivate),

              // Post Content (Image/Video/Text)
              _buildPostContent(tea),

              // Post Actions
              _buildPostActions(tea),

              // Post Likes and Caption
              _buildPostFooter(tea, username),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPostSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepPurple.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Skeleton header
          ListTile(
            leading: CircleAvatar(backgroundColor: AppColors.cream),
            title: Container(
              height: 16,
              width: 100,
              color: AppColors.cream,
            ),
            subtitle: Container(
              height: 12,
              width: 60,
              color: AppColors.cream,
            ),
          ),
          // Skeleton content
          Container(
            height: 300,
            color: AppColors.cream,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(String imagePath, bool isPrivate) {
    if (isPrivate) return _buildDefaultAvatar(isPrivate);

    try {
      // Check if it's a network URL
      final isNetwork = imagePath.startsWith('http') || imagePath.startsWith('https');
      if (isNetwork) {
        return Image.network(
          imagePath,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('⚠️ Network image failed: $error');
            return _buildDefaultAvatar(isPrivate);
          },
        );
      } else {
        // Assume it's a local asset
        return Image.asset(
          imagePath,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('⚠️ Asset image failed: $error');
            return _buildDefaultAvatar(isPrivate);
          },
        );
      }
    } catch (e) {
      print('❌ Error loading profile image: $e');
      return _buildDefaultAvatar(isPrivate);
    }
  }


  Widget _buildPostHeader(
      Map<String, dynamic> tea,
      String username,
      String? profileImage,
      bool isPrivate,
      ) {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final currentUser = _auth.currentUser;
    final postOwnerId = tea['userId'];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Profile Image
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isPrivate ? AppColors.textSecondary : AppColors.gold,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: profileImage != null && profileImage.toString().isNotEmpty
                  ? _buildProfileImage(profileImage, isPrivate)
                  : _buildDefaultAvatar(isPrivate),
            ),
          ),

          const SizedBox(width: 12),

          // Username + Timestamp
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatTimestamp(tea['createdAt']),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Follow Button (only for other users)
          if (currentUser != null && currentUser.uid != postOwnerId)
            FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('users').doc(postOwnerId).get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final userDoc = snapshot.data!;
                final data = userDoc.data() as Map<String, dynamic>? ?? {};
                final followers = List<String>.from(data['followers'] ?? []);
                final requests = List<String>.from(data['Requests'] ?? []);

                bool isFollowing = followers.contains(currentUser.uid);
                bool isRequested = requests.contains(currentUser.uid);

                String buttonText = isFollowing
                    ? 'Following'
                    : isRequested
                    ? 'Requested'
                    : 'Follow';

                Color buttonColor = isFollowing
                    ? AppColors.deepPurple
                    : isRequested
                    ? AppColors.textSecondary.withOpacity(0.5)
                    : AppColors.teal;

                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: isFollowing || isRequested
                      ? null
                      : () async {
                    await _teaController.sendFollowRequest(postOwnerId);
                  },
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: buttonColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      buttonText,
                      style: TextStyle(
                        color: isFollowing || isRequested
                            ? AppColors.white
                            : Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),

          // Menu Icon
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: AppColors.textSecondary,
            ),
            onPressed: () => _showTeaOptions(tea),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(bool isPrivate) {
    return Container(
      color: AppColors.cream,
      child: Icon(
        isPrivate ? Icons.security : Icons.person,
        color: isPrivate ? AppColors.textSecondary : AppColors.deepPurple,
      ),
    );
  }

  Widget _buildPostContent(Map<String, dynamic> tea) {
    final contentUrl = tea['contentUrl'];
    final isVideo = tea['isVideo'] ?? false;
    final teaId = tea['id'];

    if (contentUrl == null) {
      return _buildTextOnlyContent(tea);
    }

    if (isVideo) {
      return _buildVideoContent(tea, contentUrl, teaId);
    }

    return _buildImageContent(contentUrl);
  }

  Widget _buildTextOnlyContent(Map<String, dynamic> tea) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Text(
        tea['teaMoment'] ?? '',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildImageContent(String imageUrl) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildContentErrorPlaceholder();
          },
        ),
      ),
    );
  }

  Widget _buildVideoContent(Map<String, dynamic> tea, String videoUrl, String teaId) {
    // Initialize video if not already done
    if (!_videoInitialized.containsKey(teaId) || !_videoInitialized[teaId]!) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeVideo(teaId, videoUrl);
      });
    }

    return VisibilityDetector(
      key: Key('home_video_$teaId'),
      onVisibilityChanged: (info) {
        final visibility = info.visibleFraction;
        _onVideoVisibilityChanged(teaId, visibility);
      },
      child: GestureDetector(
        onTap: () => _toggleVideoControls(teaId),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video Player
            Container(
              color: Colors.black,
              height: 300,
              width: double.infinity,
              child: _videoInitialized[teaId] == true
                  ? Chewie(controller: _chewieControllers[teaId]!)
                  : _buildVideoPlaceholder(),
            ),

            // Custom Controls Overlay
            if (_videoInitialized[teaId] == true && _showVideoControls[teaId]!)
              Positioned.fill(
                child: Column(
                  children: [
                    // Top Controls (Mute & Fullscreen)
                    _buildTopControls(teaId),

                    // Middle Play/Pause
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _toggleVideoPlayback(teaId),
                        child: Container(
                          color: Colors.transparent,
                          child: Center(
                            child: AnimatedOpacity(
                              opacity: _videoControllers[teaId]!.value.isPlaying ? 0.0 : 0.7,
                              duration: Duration(milliseconds: 300),
                              child: Icon(
                                _videoControllers[teaId]!.value.isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Video Indicator
            if (_videoInitialized[teaId] == true)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.videocam, color: Colors.white, size: 12),
                      if (_videoControllers[teaId]!.value.isPlaying)
                        Row(
                          children: [
                            SizedBox(width: 4),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

            // Loading Indicator
            if (!_videoInitialized.containsKey(teaId) || _videoInitialized[teaId] == false)
              Positioned.fill(
                child: Container(
                  color: Colors.black,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopControls(String teaId) {
    return Container(
      padding: EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Mute/Unmute Button
          GestureDetector(
            onTap: () => _toggleMute(teaId),
            child: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _videoMuted[teaId] == true ? Icons.volume_off : Icons.volume_up,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),

          // Fullscreen Button
          GestureDetector(
            onTap: () => _openFullScreen(teaId),
            child: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.fullscreen,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam, color: Colors.white54, size: 40),
            SizedBox(height: 8),
            Text('Loading video...', style: TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  Widget _buildContentErrorPlaceholder() {
    return Container(
      color: AppColors.cream,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: AppColors.deepPurple, size: 40),
          SizedBox(height: 8),
          Text('Failed to load content', style: TextStyle(color: AppColors.deepPurple)),
        ],
      ),
    );
  }

  Widget _buildPostActions(Map<String, dynamic> tea) {
    final teaId = tea['id'];
    final likes = (tea['likes'] as List?)?.length ?? 0;
    final isLiked = (tea['likes'] as List?)?.contains(_teaController.getCurrentUserId()) ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Like Button
              IconButton(
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? AppColors.rosePink : AppColors.textSecondary,
                  size: 28,
                ),
                onPressed: () => _teaController.toggleLike(teaId),
              ),
              const SizedBox(width: 8),
              // Comment Button
              IconButton(
                icon: Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.textSecondary,
                  size: 26,
                ),
                onPressed: () => _showCommentsBottomSheet(tea),
              ),
              const SizedBox(width: 8),
              // Share Button
              IconButton(
                icon: Icon(
                  Icons.send_outlined,
                  color: AppColors.textSecondary,
                  size: 26,
                ),
                onPressed: () => _showShareOptions(tea),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              Icons.bookmark_border,
              color: AppColors.textSecondary,
              size: 28,
            ),
            onPressed: () => _teaController.saveTea(teaId),
          ),
        ],
      ),
    );
  }

  Widget _buildPostFooter(Map<String, dynamic> tea, String username) {
    final likes = (tea['likes'] as List?)?.length ?? 0;
    final comments = (tea['comments'] as List?)?.length ?? 0;
    final caption = tea['teaMoment'] ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$likes likes',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$username ',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: caption,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (comments > 0)
            GestureDetector(
              onTap: () => _showCommentsBottomSheet(tea),
              child: Text(
                'View all $comments comments',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _showCommentsBottomSheet(tea),
            child: Text(
              'Add a comment...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Recently';

    try {
      final date = timestamp is Timestamp
          ? timestamp.toDate()
          : DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      if (difference.inDays < 7) return '${difference.inDays}d ago';

      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Recently';
    }
  }

  void _showTeaOptions(Map<String, dynamic> tea) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.report, color: AppColors.rosePink),
                title: Text('Report Post'),
                onTap: () {
                  Navigator.pop(context);
                  Get.snackbar('Reported', 'Post has been reported');
                },
              ),
              ListTile(
                leading: Icon(Icons.block, color: AppColors.textSecondary),
                title: Text('Block User'),
                onTap: () {
                  Navigator.pop(context);
                  Get.snackbar('Blocked', 'User has been blocked');
                },
              ),
              ListTile(
                leading: Icon(Icons.share, color: AppColors.teal),
                title: Text('Share Post'),
                onTap: () {
                  Navigator.pop(context);
                  _showShareOptions(tea);
                },
              ),
              ListTile(
                leading: Icon(Icons.save_alt, color: AppColors.deepPurple),
                title: Text('Save Tea'),
                onTap: () {
                  Navigator.pop(context);
                  _teaController.saveTea(tea['id']);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCommentsBottomSheet(Map<String, dynamic> tea) {
    final comments = tea['comments'] as List? ?? [];
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Comments',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // 🧾 Comment List
                Expanded(
                  child: comments.isEmpty
                      ? Center(
                    child: Text(
                      'No comments yet',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  )
                      : ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];

                      return FutureBuilder<Map<String, dynamic>>(
                        future: _getUserData(comment['userId']),
                        builder: (context, snapshot) {
                          final userData = snapshot.data ?? {};
                          final privacy = userData['privacy'] ?? {};
                          final isPrivate = privacy['private_account'] ?? false;
                          final username = isPrivate
                              ? 'Anonymous'
                              : (userData['username'] ?? 'Unknown');
                          final profileImage = isPrivate
                              ? null
                              : userData['profileImage'];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 🔹 Main Comment
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.cream,
                                    child: isPrivate
                                        ? const Icon(Icons.lock, color: Colors.grey)
                                        : (profileImage != null
                                        ? ClipOval(
                                      child: Image.network(
                                        profileImage,
                                        width: 36,
                                        height: 36,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(Icons.person, color: Colors.grey);
                                        },
                                      ),
                                    )
                                        : const Icon(Icons.person, color: Colors.grey)),
                                  ),
                                  title: Text(
                                    username,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        comment['comment'] ?? '',
                                        style: TextStyle(color: AppColors.textPrimary),
                                      ),
                                      const SizedBox(height: 4),
                                      GestureDetector(
                                        onTap: () {
                                          _showReplyInput(context, tea['id'], comment['timestamp'].toString());
                                        },
                                        child: Text(
                                          'Reply',
                                          style: TextStyle(
                                            color: AppColors.teal,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // 🔹 Replies Section with Line
                                if (comment['replies'] != null && comment['replies'].isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 40, top: 4),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          left: BorderSide(
                                            color: Colors.grey,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: (comment['replies'] as List)
                                              .map((reply) => FutureBuilder<Map<String, dynamic>>(
                                            future: _getUserData(reply['userId']),
                                            builder: (context, snapshot) {
                                              final replyUser = snapshot.data ?? {};
                                              final rProfile = replyUser['profileImage'];
                                              final rName = replyUser['username'] ?? 'Unknown';

                                              return Padding(
                                                padding: const EdgeInsets.only(top: 8),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 14,
                                                      backgroundColor: AppColors.cream,
                                                      backgroundImage: rProfile != null
                                                          ? NetworkImage(rProfile)
                                                          : null,
                                                      child: rProfile == null
                                                          ? const Icon(Icons.person,
                                                          size: 16, color: Colors.grey)
                                                          : null,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            rName,
                                                            style: const TextStyle(
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                          Text(
                                                            reply['comment'] ?? '',
                                                            style: const TextStyle(fontSize: 13),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ))
                                              .toList(),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // 💬 Add Comment Input
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.cream),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle: TextStyle(color: AppColors.textSecondary),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onSubmitted: (text) {
                            if (text.trim().isNotEmpty) {
                              _teaController.addComment(tea['id'], text.trim());
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.send, color: AppColors.teal),
                        onPressed: () {
                          if (commentController.text.trim().isNotEmpty) {
                            _teaController.addComment(tea['id'], commentController.text.trim());
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  void _showReplyInput(BuildContext context, String teaId, String parentCommentId) {
    final replyController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 16,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: replyController,
                decoration: InputDecoration(
                  hintText: 'Write a reply...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Reply'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () {
                  if (replyController.text.trim().isNotEmpty) {
                    _teaController.addComment(
                      teaId,
                      replyController.text.trim(),
                      parentCommentId: parentCommentId,
                    );
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }



  void _showShareOptions(Map<String, dynamic> tea) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Share Post',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildShareOption(Icons.send, 'Send', () {}),
                  _buildShareOption(Icons.copy, 'Copy Link', () {}),
                  _buildShareOption(Icons.bookmark_border, 'Save', () {
                    _teaController.saveTea(tea['id']);
                    Navigator.pop(context);
                  }),
                  _buildShareOption(Icons.share, 'Share', () {}),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.cream,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.deepPurple, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// Data Models
class Story {
  final String username;
  final String imageUrl;
  final bool isOwn;
  bool isViewed;

  Story({
    required this.username,
    required this.imageUrl,
    this.isOwn = false,
    this.isViewed = false,
  });
}
