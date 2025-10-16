
import 'dart:async'; // Add this import
import 'package:clock_tea/Tea/CreateTeaScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:chewie/chewie.dart';
import '../Const/AppColors.dart';
import 'Controller/TeaController.dart';
import 'FullScreenVideo.dart';

class MyTeasScreen extends StatefulWidget {
  const MyTeasScreen({super.key});

  @override
  State<MyTeasScreen> createState() => _MyTeasScreenState();
}

class _MyTeasScreenState extends State<MyTeasScreen> {
  final TeaController _teaController = Get.put(TeaController());
  bool _isGridView = false;
  bool _isLoading = true;

  // Video management
  final Map<String, VideoPlayerController> _videoControllers = {};
  final Map<String, ChewieController> _chewieControllers = {};
  final Map<String, bool> _videoInitialized = {};
  final Map<String, double> _videoVisibility = {};
  final Map<String, bool> _videoMuted = {};
  bool _isFullScreen = false;
  final Map<String, bool> _showVideoControls = {};
  final Map<String, Timer?> _controlHideTimers = {};

  @override
  void initState() {
    super.initState();
    _loadUserTeas();
  }

  @override
  void dispose() {
    // Dispose all video controllers
    _disposeAllVideos();

    // Cancel all control hide timers
    for (var timer in _controlHideTimers.values) {
      timer?.cancel();
    }
    _controlHideTimers.clear();

    super.dispose();
  }

  void _disposeAllVideos() {
    for (var controller in _chewieControllers.values) {
      controller.dispose();
    }
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }

    // Cancel timers for all videos
    for (var timer in _controlHideTimers.values) {
      timer?.cancel();
    }

    _chewieControllers.clear();
    _videoControllers.clear();
    _videoInitialized.clear();
    _videoVisibility.clear();
    _videoMuted.clear();
    _showVideoControls.clear();
    _controlHideTimers.clear();
  }

  Future<void> _loadUserTeas() async {
    setState(() {
      _isLoading = true;
    });
    await _teaController.fetchUserTeas();
    setState(() {
      _isLoading = false;
    });
  }

  // Initialize video controller for a specific tea
  Future<void> _initializeVideo(String teaId, String videoUrl) async {
    if (_videoControllers.containsKey(teaId)) {
      return;
    }

    try {
      final videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await videoController.initialize();

      final chewieController = ChewieController(
        videoPlayerController: videoController,
        autoPlay: false,
        looping: true,
        showControls: false, // Disable Chewie controls since we use custom ones
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
        _videoVisibility[teaId] = 0.0;
        _videoMuted[teaId] = false;
        _showVideoControls[teaId] = false; // Start with controls hidden
      });
    } catch (e) {
      print('Failed to initialize video for tea $teaId: $e');
      setState(() {
        _videoInitialized[teaId] = false;
      });
    }
  }

  // Handle video visibility changes for auto-play
  void _onVideoVisibilityChanged(String teaId, double visibility) {
    if (!_videoInitialized[teaId]!) return;

    setState(() {
      _videoVisibility[teaId] = visibility;
    });

    final videoController = _videoControllers[teaId];

    if (videoController == null) return;

    // Auto-play when video is mostly visible (more than 50%)
    if (visibility > 0.5) {
      if (!videoController.value.isPlaying) {
        videoController.play();
      }
    } else {
      // Pause when video is not visible enough and hide controls
      if (videoController.value.isPlaying) {
        videoController.pause();
      }
      // Hide controls when video goes out of view
      if (_showVideoControls[teaId]!) {
        setState(() {
          _showVideoControls[teaId] = false;
        });
      }
    }
  }


  // Manual play/pause toggle
  void _toggleVideoPlayback(String teaId) {
    final videoController = _videoControllers[teaId];
    if (videoController != null && _videoInitialized[teaId]!) {
      if (videoController.value.isPlaying) {
        videoController.pause();
      } else {
        videoController.play();
      }

      // Hide controls after 2 seconds when playing/pausing
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


  // Dispose video controller for a specific tea
  void _disposeVideo(String teaId) {
    if (_chewieControllers.containsKey(teaId)) {
      _chewieControllers[teaId]!.dispose();
      _chewieControllers.remove(teaId);
    }
    if (_videoControllers.containsKey(teaId)) {
      _videoControllers[teaId]!.dispose();
      _videoControllers.remove(teaId);
    }
    _videoInitialized.remove(teaId);
    _videoVisibility.remove(teaId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.deepPurple,
        elevation: 0,
        title: const Text(
          'My Teas',
          style: TextStyle(
            color: AppColors.textOnDark,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: AppColors.textOnDark,
            ),
            onPressed: _loadUserTeas,
          ),
          IconButton(
            icon: Icon(
              _isGridView ? Icons.list : Icons.grid_view,
              color: AppColors.textOnDark,
            ),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          IconButton(
            icon: Icon(
              Icons.add_circle_outline,
              color: AppColors.textOnDark,
            ),
            onPressed: () {
              Get.to(() => CreateTeaScreen());
            },
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.deepPurple,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your teas...',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Obx(() {
      final userTeas = _teaController.userTeas;

      if (userTeas.isEmpty) {
        return _buildEmptyState();
      }

      return Column(
        children: [
          _buildStatsOverview(userTeas),
          Expanded(
            child: _isGridView ? _buildGridView(userTeas) : _buildListView(userTeas),
          ),
        ],
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.deepPurple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_cafe,
                color: AppColors.deepPurple,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Teas Yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Share your first tea moment with the community. Your journey starts here!',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Get.to(() => CreateTeaScreen());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepPurple,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Create Your First Tea',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview(List<Map<String, dynamic>> teas) {
    final int totalLikes = teas.fold<int>(0, (sum, tea) => sum + ((tea['likes']?.length ?? 0) as int));
    final int totalComments = teas.fold<int>(0, (sum, tea) => sum + ((tea['comments']?.length ?? 0) as int));
    final int totalViews = teas.fold<int>(0, (sum, tea) => sum + ((tea['totalViews'] ?? 0) as int));

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepPurple.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Teas', teas.length, Icons.local_cafe),
          _buildStatItem('Likes', totalLikes, Icons.favorite),
          _buildStatItem('Comments', totalComments, Icons.chat),
          _buildStatItem('Views', totalViews, Icons.remove_red_eye),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, IconData icon) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.deepPurple.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppColors.deepPurple,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _formatCount(count),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  Widget _buildGridView(List<Map<String, dynamic>> teas) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.8,
        ),
        itemCount: teas.length,
        itemBuilder: (context, index) {
          final tea = teas[index];
          return _buildGridTeaItem(tea);
        },
      ),
    );
  }

  Widget _buildGridTeaItem(Map<String, dynamic> tea) {
    final contentUrl = tea['contentUrl'];
    final isVideo = tea['isVideo'] ?? false;
    final caption = tea['teaMoment'] ?? '';
    final likes = (tea['likes'] as List?)?.length ?? 0;
    final comments = (tea['comments'] as List?)?.length ?? 0;
    final teaId = tea['id'];

    return GestureDetector(
      onTap: () => _showTeaDetails(tea),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepPurple.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: _buildContentPreview(
                  tea,
                  contentUrl,
                  isVideo,
                  teaId: teaId,
                  isLarge: false,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    caption.length > 50 ? '${caption.substring(0, 50)}...' : caption,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        color: AppColors.rosePink,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatCount(likes),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chat,
                        color: AppColors.teal,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatCount(comments),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> teas) {
    return RefreshIndicator(
      onRefresh: _loadUserTeas,
      color: AppColors.deepPurple,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: teas.length,
        itemBuilder: (context, index) {
          final tea = teas[index];
          return _buildListTeaItem(tea);
        },
      ),
    );
  }

  Widget _buildListTeaItem(Map<String, dynamic> tea) {
    final contentUrl = tea['contentUrl'];
    final isVideo = tea['isVideo'] ?? false;
    final caption = tea['teaMoment'] ?? '';
    final likes = (tea['likes'] as List?)?.length ?? 0;
    final comments = (tea['comments'] as List?)?.length ?? 0;
    final views = tea['totalViews'] ?? 0;
    final createdAt = tea['createdAt'];
    final isLiked = (tea['likes'] as List?)?.contains(_teaController.getCurrentUserId()) ?? false;
    final teaId = tea['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepPurple.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.cream,
                  child: Icon(
                    Icons.person,
                    color: AppColors.deepPurple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Profile',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatTimestamp(createdAt),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => _showTeaOptions(tea),
                ),
              ],
            ),
          ),
          _buildContentPreview(
            tea,
            contentUrl,
            isVideo,
            teaId: teaId,
            isLarge: true,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? AppColors.rosePink : AppColors.textSecondary,
                          ),
                          onPressed: () => _toggleLike(tea),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.chat_bubble_outline,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => _showComments(tea),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.share_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => _shareTea(tea),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.remove_red_eye,
                          color: AppColors.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatCount(views),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  '${_formatCount(likes)} likes',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  caption,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                if (comments > 0)
                  GestureDetector(
                    onTap: () => _showComments(tea),
                    child: Text(
                      'View all $comments comments',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentPreview(
      Map<String, dynamic> tea,
      String? contentUrl,
      bool isVideo, {
        String? teaId,
        bool isLarge = false,
      }) {
    if (contentUrl == null) {
      return Container(
        height: isLarge ? 300 : 150,
        color: AppColors.cream,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_cafe,
              color: AppColors.deepPurple,
              size: isLarge ? 50 : 30,
            ),
            const SizedBox(height: 8),
            Text(
              'Tea Moment',
              style: TextStyle(
                color: AppColors.deepPurple,
                fontWeight: FontWeight.w500,
                fontSize: isLarge ? 16 : 12,
              ),
            ),
          ],
        ),
      );
    }

    if (isVideo) {
      return _buildVideoContent(tea, contentUrl, teaId: teaId, isLarge: isLarge);
    }

    return Image.network(
      contentUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: isLarge ? 300 : 150,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: isLarge ? 300 : 150,
          color: AppColors.cream,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: AppColors.deepPurple,
                size: isLarge ? 40 : 24,
              ),
              const SizedBox(height: 4),
              Text(
                'Failed to load',
                style: TextStyle(
                  color: AppColors.deepPurple,
                  fontSize: isLarge ? 12 : 10,
                ),
              ),
            ],
          ),
        );
      },
    );
  }


// Add these new methods for mute and fullscreen functionality
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

  // Add this method to handle controls visibility
  void _toggleVideoControls(String teaId) {
    if (!_videoInitialized[teaId]!) return;

    setState(() {
      _showVideoControls[teaId] = !_showVideoControls[teaId]!;
    });

    // Cancel existing timer
    _controlHideTimers[teaId]?.cancel();

    // If showing controls, set timer to hide them after 3 seconds
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

  Widget _buildVideoContent(
      Map<String, dynamic> tea,
      String videoUrl, {
        String? teaId,
        bool isLarge = false,
      }) {
    if (teaId == null) {
      return _buildVideoPlaceholder(isLarge: isLarge);
    }

    // Initialize video if not already done
    if (!_videoInitialized.containsKey(teaId) || !_videoInitialized[teaId]!) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeVideo(teaId, videoUrl);
      });
    }

    // Initialize controls state
    if (!_showVideoControls.containsKey(teaId)) {
      _showVideoControls[teaId] = false;
    }

    return VisibilityDetector(
      key: Key('video_$teaId'),
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
              height: isLarge ? 300 : 150,
              width: double.infinity,
              child: _videoInitialized[teaId] == true
                  ? Chewie(controller: _chewieControllers[teaId]!)
                  : _buildVideoPlaceholder(isLarge: isLarge),
            ),

            // Custom Controls Overlay - Only show when tapped
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
                                size: isLarge ? 50 : 30,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Loading Indicator
            if (!_videoInitialized.containsKey(teaId) || _videoInitialized[teaId] == false)
              Positioned.fill(
                child: Container(
                  color: Colors.black,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),

            // Video Indicator (Always visible)
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
                      Icon(
                        Icons.videocam,
                        color: Colors.white,
                        size: 12,
                      ),
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
          ],
        ),
      ),
    );
  }


  Widget _buildVideoPlaceholder({bool isLarge = false}) {
    return Container(
      color: Colors.black,
      height: isLarge ? 300 : 150,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam,
            color: Colors.white54,
            size: isLarge ? 40 : 24,
          ),
          SizedBox(height: 8),
          Text(
            'Loading video...',
            style: TextStyle(
              color: Colors.white54,
              fontSize: isLarge ? 14 : 10,
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

  void _showTeaDetails(Map<String, dynamic> tea) {
    Get.snackbar(
      'Tea Details',
      'Showing details for tea post',
      backgroundColor: AppColors.deepPurple,
      colorText: AppColors.white,
    );
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
                leading: Icon(Icons.edit, color: AppColors.deepPurple),
                title: Text('Edit Tea Post'),
                onTap: () {
                  Navigator.pop(context);
                  _editTea(tea);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: AppColors.rosePink),
                title: Text('Delete Tea Post'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteTea(tea);
                },
              ),
              ListTile(
                leading: Icon(Icons.share, color: AppColors.teal),
                title: Text('Share Tea Post'),
                onTap: () {
                  Navigator.pop(context);
                  _shareTea(tea);
                },
              ),
              ListTile(
                leading: Icon(Icons.save_alt, color: AppColors.deepPurple),
                title: Text('Save Tea'),
                onTap: () {
                  Navigator.pop(context);
                  _saveTea(tea['id']);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _toggleLike(Map<String, dynamic> tea) {
    _teaController.toggleLike(tea['id']);
  }

  void _showComments(Map<String, dynamic> tea) {
    Get.snackbar(
      'Comments',
      'Showing comments for tea post',
      backgroundColor: AppColors.deepPurple,
      colorText: AppColors.white,
    );
  }

  void _shareTea(Map<String, dynamic> tea) {
    Get.snackbar(
      'Share',
      'Sharing tea post',
      backgroundColor: AppColors.deepPurple,
      colorText: AppColors.white,
    );
  }

  void _saveTea(String teaId) {
    _teaController.saveTea(teaId);
    Get.snackbar(
      'Saved',
      'Tea saved to your collection',
      backgroundColor: AppColors.teal,
      colorText: AppColors.white,
    );
  }

  void _editTea(Map<String, dynamic> tea) {
    Get.snackbar(
      'Edit',
      'Edit functionality coming soon',
      backgroundColor: AppColors.deepPurple,
      colorText: AppColors.white,
    );
  }

  void _deleteTea(Map<String, dynamic> tea) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        title: Text(
          'Delete Tea Post',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete this tea post? This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              _teaController.deleteTea(tea['id']);
              Navigator.pop(context);
              Get.snackbar(
                'Deleted',
                'Tea post deleted successfully',
                backgroundColor: AppColors.rosePink,
                colorText: AppColors.white,
              );
            },
            child: Text('Delete', style: TextStyle(color: AppColors.rosePink)),
          ),
        ],
      ),
    );
  }
}