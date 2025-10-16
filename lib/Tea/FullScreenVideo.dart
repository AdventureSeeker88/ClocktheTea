import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../Const/AppColors.dart';

class FullScreenVideoPage extends StatefulWidget {
  final VideoPlayerController videoController;
  final ChewieController chewieController;
  final bool isMuted;
  final Function(bool) onMuteToggle;

  const FullScreenVideoPage({
    Key? key,
    required this.videoController,
    required this.chewieController,
    required this.isMuted,
    required this.onMuteToggle,
  }) : super(key: key);

  @override
  State<FullScreenVideoPage> createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<FullScreenVideoPage> {
  late ChewieController _fullScreenChewieController;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _isMuted = widget.isMuted;

    // Set initial volume
    if (_isMuted) {
      widget.videoController.setVolume(0.0);
    }

    _fullScreenChewieController = ChewieController(
      videoPlayerController: widget.videoController,
      autoPlay: true,
      looping: true,
      showControls: true,
      allowFullScreen: false, // We're already in fullscreen
      allowMuting: true,
      showOptions: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: AppColors.rosePink,
        handleColor: AppColors.rosePink,
        backgroundColor: Colors.grey.shade700,
        bufferedColor: Colors.grey.shade500,
      ),
      customControls: const CupertinoControls(
        backgroundColor: Color.fromRGBO(0, 0, 0, 0.7),
        iconColor: Colors.white,
      ),
    );

    // Play video when fullscreen opens
    if (!widget.videoController.value.isPlaying) {
      widget.videoController.play();
    }
  }

  @override
  void dispose() {
    _fullScreenChewieController.dispose();
    super.dispose();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      widget.videoController.setVolume(_isMuted ? 0.0 : 1.0);
      widget.onMuteToggle(_isMuted);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Video Player
            Center(
              child: Chewie(controller: _fullScreenChewieController),
            ),

            // Custom Top Controls
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),

                    // Mute Button
                    GestureDetector(
                      onTap: _toggleMute,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isMuted ? Icons.volume_off : Icons.volume_up,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
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
}