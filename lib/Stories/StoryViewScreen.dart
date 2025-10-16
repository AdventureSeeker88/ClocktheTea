// screens/story_view_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'Controller/StoryController.dart';
import 'Model/StoryModel.dart';



class StoryViewScreen extends StatefulWidget {
  final List<List<Story>> userStories;
  final int initialIndex;
  final bool isOwnStory;

  const StoryViewScreen({
    super.key,
    required this.userStories,
    required this.initialIndex,
    this.isOwnStory = false,
  });

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> with SingleTickerProviderStateMixin {
  final StoryController _storyController = Get.find<StoryController>();
  late PageController _pageController;
  late AnimationController _animationController;
  int _currentUserIndex = 0;
  int _currentStoryIndex = 0;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _currentUserIndex = widget.initialIndex;
    _currentStoryIndex = 0;
    _pageController = PageController(initialPage: widget.initialIndex);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _loadCurrentStory();
    _markStoryAsViewed();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _loadCurrentStory() {
    final currentStory = _getCurrentStory();

    // Dispose previous video controller
    _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;
    _isPaused = false;

    if (currentStory.isVideo) {
      _initializeVideo(currentStory.mediaUrl);
    } else {
      _startAutoPlay();
    }
  }

  void _initializeVideo(String videoUrl) async {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
      ..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
        });
        _videoController!.play();
        // For videos, use video duration instead of fixed 5 seconds
        final videoDuration = _videoController!.value.duration;
        _animationController.duration = videoDuration > const Duration(seconds: 30)
            ? const Duration(seconds: 30)
            : videoDuration;
        _startAutoPlay();

        // Listen for video completion
        _videoController!.addListener(() {
          if (_videoController!.value.position >= _videoController!.value.duration) {
            _nextStory();
          }
        });
      });
  }

  void _startAutoPlay() {
    if (!_isPaused) {
      _animationController.reset();
      _animationController.forward().then((_) {
        if (mounted) {
          _nextStory();
        }
      });
    }
  }

  void _pauseStory() {
    _animationController.stop();
    _videoController?.pause();
    _isPaused = true;
  }

  void _resumeStory() {
    if (_isPaused) {
      _animationController.forward();
      _videoController?.play();
      _isPaused = false;
    }
  }

  void _nextStory() {
    final currentUserStories = widget.userStories[_currentUserIndex];

    if (_currentStoryIndex < currentUserStories.length - 1) {
      // Next story in same user
      setState(() {
        _currentStoryIndex++;
      });
      _loadCurrentStory();
    } else {
      // Next user
      if (_currentUserIndex < widget.userStories.length - 1) {
        setState(() {
          _currentUserIndex++;
          _currentStoryIndex = 0;
        });
        _pageController.animateToPage(
          _currentUserIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _loadCurrentStory();
      } else {
        // End of all stories
        Get.back();
      }
    }
    _markStoryAsViewed();
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      setState(() {
        _currentStoryIndex--;
      });
      _loadCurrentStory();
    } else if (_currentUserIndex > 0) {
      setState(() {
        _currentUserIndex--;
        _currentStoryIndex = widget.userStories[_currentUserIndex].length - 1;
      });
      _pageController.animateToPage(
        _currentUserIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _loadCurrentStory();
    }
    _markStoryAsViewed();
  }

  void _markStoryAsViewed() {
    final currentStory = _getCurrentStory();
    _storyController.markStoryAsViewed(currentStory.id);
  }

  Story _getCurrentStory() {
    return widget.userStories[_currentUserIndex][_currentStoryIndex];
  }

  void _showViewersList() {
    final currentStory = _getCurrentStory();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Text(
                'Story Viewers (${currentStory.viewers.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _storyController.getStoryViewers(currentStory.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final viewers = snapshot.data ?? [];

                    if (viewers.isEmpty) {
                      return const Center(
                        child: Text('No views yet'),
                      );
                    }

                    return ListView.builder(
                      itemCount: viewers.length,
                      itemBuilder: (context, index) {
                        final viewer = viewers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: CachedNetworkImageProvider(
                              viewer['profileImage'] ?? '',
                            ),
                            child: viewer['profileImage']?.isEmpty ?? true
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(viewer['username'] ?? 'Unknown'),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentStory = _getCurrentStory();
    final isPrivateAccount = currentStory.isPrivateAccount;
    final isOwnStory = widget.isOwnStory;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.localPosition.dx < screenWidth / 2) {
            _previousStory();
          } else {
            _nextStory();
          }
        },
        onLongPress: _pauseStory,
        onLongPressEnd: (details) => _resumeStory,
        onLongPressCancel: _resumeStory,
        child: Stack(
          children: [
            // Story Content
            PageView.builder(
              controller: _pageController,
              itemCount: widget.userStories.length,
              onPageChanged: (index) {
                setState(() {
                  _currentUserIndex = index;
                  _currentStoryIndex = 0;
                });
                _loadCurrentStory();
              },
              itemBuilder: (context, userIndex) {
                final userStories = widget.userStories[userIndex];
                return _buildUserStoriesPage(userStories);
              },
            ),

            // Progress Indicators
            _buildProgressIndicators(),

            // Header
            _buildHeader(isPrivateAccount, isOwnStory),

            // Caption with better visibility
            _buildCaption(currentStory),

            // Video Play/Pause Controls
            if (currentStory.isVideo) _buildVideoControls(),

            // Viewers Button for own stories
            if (isOwnStory) _buildViewersButton(currentStory),
          ],
        ),
      ),
    );
  }

  Widget _buildUserStoriesPage(List<Story> userStories) {
    final currentStory = userStories[_currentStoryIndex];

    return Stack(
      children: [
        // Media Content
        if (currentStory.isImage)
          CachedNetworkImage(
            imageUrl: currentStory.mediaUrl,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[900],
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[900],
              child: const Icon(
                Icons.error,
                color: Colors.white,
                size: 50,
              ),
            ),
          )
        else if (currentStory.isVideo && _isVideoInitialized)
          VideoPlayer(_videoController!)
        else
          Container(
            color: Colors.grey[900],
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildProgressIndicators() {
    final currentUserStories = widget.userStories[_currentUserIndex];

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 8,
      right: 8,
      child: Row(
        children: List.generate(currentUserStories.length, (index) {
          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Stack(
                children: [
                  // Progress
                  if (index == _currentStoryIndex)
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _animationController.value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      },
                    )
                  else if (index < _currentStoryIndex)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeader(bool isPrivateAccount, bool isOwnStory) {
    final currentStory = _getCurrentStory();

    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Profile Image with Privacy Check
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipOval(
                child: isPrivateAccount && !isOwnStory
                    ? Container(
                  color: Colors.grey[800],
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                )
                    : CachedNetworkImage(
                  imageUrl: currentStory.userProfileImage,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[800],
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[800],
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPrivateAccount && !isOwnStory ? 'Anonymous' : currentStory.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _timeAgo(currentStory.createdAt),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isOwnStory) ...[
              _buildViewersCount(currentStory),
              const SizedBox(width: 8),
            ],
            IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewersCount(Story story) {
    return GestureDetector(
      onTap: _showViewersList,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.remove_red_eye_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              story.viewers.length.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewersButton(Story story) {
    return Positioned(
      bottom: 100,
      right: 16,
      child: GestureDetector(
        onTap: _showViewersList,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.visibility_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                '${story.viewers.length} views',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaption(Story story) {
    if (story.caption == null || story.caption!.isEmpty) return const SizedBox();

    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            story.caption!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildVideoControls() {
    return Positioned(
      bottom: 150,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              if (_videoController?.value.isPlaying ?? false) {
                _videoController!.pause();
                _animationController.stop();
              } else {
                _videoController!.play();
                _animationController.forward();
              }
              setState(() {});
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _videoController?.value.isPlaying ?? false
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}