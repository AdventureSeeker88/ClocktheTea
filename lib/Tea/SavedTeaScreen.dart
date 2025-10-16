// saved_tea_screen.dart
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

class SavedTeaScreen extends StatefulWidget {
  const SavedTeaScreen({super.key});

  @override
  State<SavedTeaScreen> createState() => _SavedTeaScreenState();
}

class _SavedTeaScreenState extends State<SavedTeaScreen> {
  final TeaController _teaController = Get.find<TeaController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Video management
  final Map<String, VideoPlayerController> _videoControllers = {};
  final Map<String, ChewieController> _chewieControllers = {};
  final Map<String, bool> _videoInitialized = {};
  final Map<String, bool> _showVideoControls = {};
  final Map<String, Timer?> _controlHideTimers = {};
  final Map<String, Map<String, dynamic>> _userCache = {};
  final Map<String, bool> _videoMuted = {};

  List<Map<String, dynamic>> _savedTeas = [];
  bool _isLoading = true;
  bool _isEmpty = false;

  @override
  void initState() {
    super.initState();
    _loadSavedTeas();
  }

  @override
  void dispose() {
    _disposeAllVideos();
    super.dispose();
  }

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

  Future<void> _loadSavedTeas() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final savedTeas = await _teaController.fetchSavedTeas();

      setState(() {
        _savedTeas = savedTeas;
        _isEmpty = savedTeas.isEmpty;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading saved teas: $e');
      setState(() {
        _isLoading = false;
        _isEmpty = true;
      });
      Get.snackbar('Error', 'Failed to load saved teas');
    }
  }

  Future<void> _removeSavedTea(String teaId) async {
    try {
      final user = _teaController.getCurrentUserId();
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user)
          .collection('savedTeas')
          .doc(teaId)
          .delete();

      // Remove from local list
      setState(() {
        _savedTeas.removeWhere((tea) => tea['id'] == teaId);
        _isEmpty = _savedTeas.isEmpty;
      });

      // Dispose video controllers if any
      if (_videoControllers.containsKey(teaId)) {
        _videoControllers[teaId]?.dispose();
        _videoControllers.remove(teaId);
      }
      if (_chewieControllers.containsKey(teaId)) {
        _chewieControllers[teaId]?.dispose();
        _chewieControllers.remove(teaId);
      }

      Get.snackbar('Removed', 'Tea removed from saved',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.teal.withOpacity(0.1),
        colorText: AppColors.textPrimary,
      );
    } catch (e) {
      print('Error removing saved tea: $e');
      Get.snackbar('Error', 'Failed to remove tea from saved');
    }
  }

  // Video management methods
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

    final defaultData = {
      'username': 'Anonymous',
      'profileImage': null,
      'isPrivate': true,
    };
    _userCache[userId] = defaultData;
    return defaultData;
  }

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

  void _toggleMute(String teaId) {
    if (_videoControllers.containsKey(teaId)) {
      setState(() {
        _videoMuted[teaId] = !(_videoMuted[teaId] ?? false);
        _videoControllers[teaId]!.setVolume(_videoMuted[teaId]! ? 0.0 : 1.0);
      });
    }
  }

  void _openFullScreen(String teaId) {
    if (!_videoInitialized[teaId]!) return;

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

  // FIX: Handle like with immediate UI update
  void _handleLikeTap(String teaId, bool isCurrentlyLiked) {
    // Find the tea in the list
    final teaIndex = _savedTeas.indexWhere((tea) => tea['id'] == teaId);
    if (teaIndex == -1) return;

    // Get current user ID
    final userId = _teaController.getCurrentUserId();
    if (userId == null) return;

    // Update local state immediately for instant UI feedback
    setState(() {
      final currentLikes = List<dynamic>.from(_savedTeas[teaIndex]['likes'] ?? []);

      if (isCurrentlyLiked) {
        currentLikes.remove(userId);
      } else {
        currentLikes.add(userId);
      }

      _savedTeas[teaIndex]['likes'] = currentLikes;
    });

    // Then update in Firestore
    _teaController.toggleLike(teaId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.deepPurple,
        elevation: 0,
        title: const Text(
          'Saved Teas',
          style: TextStyle(
            color: AppColors.textOnDark,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!_isEmpty)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.textOnDark),
              onPressed: _loadSavedTeas,
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingIndicator()
          : _isEmpty
          ? _buildEmptyState()
          : _buildSavedTeasList(),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.deepPurple),
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
              Icons.bookmark_border,
              color: AppColors.deepPurple,
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              'No Saved Teas',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Teas you save will appear here for easy access later',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadSavedTeas,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Refresh',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedTeasList() {
    return RefreshIndicator(
      backgroundColor: AppColors.deepPurple,
      color: AppColors.gold,
      onRefresh: _loadSavedTeas,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _savedTeas.length,
        itemBuilder: (context, index) {
          final tea = _savedTeas[index];
          return _buildSavedTeaCard(tea);
        },
      ),
    );
  }

  Widget _buildSavedTeaCard(Map<String, dynamic> tea) {
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

        return Dismissible(
          key: Key('saved_tea_${tea['id']}'),
          direction: DismissDirection.endToStart,
          background: Container(
            decoration: BoxDecoration(
              color: AppColors.rosePink.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: Icon(
              Icons.delete_outline,
              color: AppColors.rosePink,
              size: 30,
            ),
          ),
          confirmDismiss: (direction) async {
            return await _showDeleteConfirmation(tea['id']);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
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
                _buildPostHeader(tea, username, profileImage, isPrivate),
                _buildPostContent(tea),
                _buildPostActions(tea),
                _buildPostFooter(tea, username),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _showDeleteConfirmation(String teaId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Saved Tea'),
        content: const Text('Are you sure you want to remove this tea from your saved items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Remove',
              style: TextStyle(color: AppColors.rosePink),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Widget _buildPostSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      final isNetwork = imagePath.startsWith('http') || imagePath.startsWith('https');
      if (isNetwork) {
        return Image.network(
          imagePath,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar(isPrivate);
          },
        );
      } else {
        return Image.asset(
          imagePath,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar(isPrivate);
          },
        );
      }
    } catch (e) {
      return _buildDefaultAvatar(isPrivate);
    }
  }

  Widget _buildPostHeader(
      Map<String, dynamic> tea,
      String username,
      String? profileImage,
      bool isPrivate,
      ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
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

          // Remove from saved button
          IconButton(
            icon: Icon(
              Icons.bookmark,
              color: AppColors.teal,
              size: 28,
            ),
            onPressed: () => _removeSavedTea(tea['id']),
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
    if (!_videoInitialized.containsKey(teaId) || !_videoInitialized[teaId]!) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeVideo(teaId, videoUrl);
      });
    }

    return VisibilityDetector(
      key: Key('saved_video_$teaId'),
      onVisibilityChanged: (info) {
        final visibility = info.visibleFraction;
        _onVideoVisibilityChanged(teaId, visibility);
      },
      child: GestureDetector(
        onTap: () => _toggleVideoControls(teaId),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              color: Colors.black,
              height: 300,
              width: double.infinity,
              child: _videoInitialized[teaId] == true
                  ? Chewie(controller: _chewieControllers[teaId]!)
                  : _buildVideoPlaceholder(),
            ),

            if (_videoInitialized[teaId] == true && _showVideoControls[teaId]!)
              Positioned.fill(
                child: Column(
                  children: [
                    _buildTopControls(teaId),
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

  // FIX: Updated post actions with immediate like feedback
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
              // Like Button with immediate feedback
              GestureDetector(
                onTap: () => _handleLikeTap(teaId, isLiked),
                child: Row(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        key: ValueKey(isLiked),
                        color: isLiked ? AppColors.rosePink : AppColors.textSecondary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _formatLikeCount(likes),
                        key: ValueKey('$teaId-$likes'),
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              IconButton(
                icon: Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.textSecondary,
                  size: 26,
                ),
                onPressed: () => _showCommentsBottomSheet(tea),
              ),
              const SizedBox(width: 8),
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
          // Already saved - show filled bookmark
          IconButton(
            icon: Icon(
              Icons.bookmark,
              color: AppColors.teal,
              size: 28,
            ),
            onPressed: () => _removeSavedTea(teaId),
          ),
        ],
      ),
    );
  }

  String _formatLikeCount(int count) {
    if (count == 0) return '0';
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
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

  // FIX: Complete comments bottom sheet implementation
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
                      return _buildCommentItem(comment, tea['id']);
                    },
                  ),
                ),

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
                              Get.snackbar('Success', 'Comment added!');
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
                            Get.snackbar('Success', 'Comment added!');
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

  Widget _buildCommentItem(Map<String, dynamic> comment, String teaId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getUserData(comment['userId']),
      builder: (context, snapshot) {
        final userData = snapshot.data ?? {};
        final isPrivate = userData['isPrivate'] ?? false;
        final username = isPrivate ? 'Anonymous' : (userData['username'] ?? 'Unknown');
        final profileImage = isPrivate ? null : userData['profileImage'];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        _showReplyInput(context, teaId, comment['timestamp'].toString());
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
                            .map((reply) => _buildReplyItem(reply))
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
  }

  Widget _buildReplyItem(Map<String, dynamic> reply) {
    return FutureBuilder<Map<String, dynamic>>(
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
                backgroundImage: rProfile != null ? NetworkImage(rProfile) : null,
                child: rProfile == null
                    ? const Icon(Icons.person, size: 16, color: Colors.grey)
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
                    Get.snackbar('Success', 'Reply added!');
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