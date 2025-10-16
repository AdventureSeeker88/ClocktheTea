// widgets/story_upload_dialog.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import 'Controller/StoryController.dart';
import 'Model/StoryModel.dart';



class StoryUploadDialog extends StatefulWidget {
  final File mediaFile;
  final StoryType type;

  const StoryUploadDialog({
    super.key,
    required this.mediaFile,
    required this.type,
  });

  @override
  State<StoryUploadDialog> createState() => _StoryUploadDialogState();
}

class _StoryUploadDialogState extends State<StoryUploadDialog> {
  final StoryController _storyController = Get.find<StoryController>();
  final TextEditingController _captionController = TextEditingController();
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.type == StoryType.video) {
      _initializeVideo();
    }
  }

  void _initializeVideo() async {
    _videoController = VideoPlayerController.file(widget.mediaFile)
      ..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
        });
        _videoController!.setLooping(true);
        _videoController!.play();
      });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(),
            // Media Preview
            _buildMediaPreview(),
            // Caption Input
            _buildCaptionInput(),
            // Upload Progress
            _buildUploadProgress(),
            // Actions
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            color: Colors.deepPurple,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Text(
            'Share to Your Story',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    return Container(
      height: 200,
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: widget.type == StoryType.image
            ? Image.file(
          widget.mediaFile,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        )
            : _isVideoInitialized
            ? VideoPlayer(_videoController!)
            : const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildCaptionInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _captionController,
        maxLength: 100,
        decoration: InputDecoration(
          hintText: 'Add a caption... (optional)',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.deepPurple),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildUploadProgress() {
    return Obx(() {
      if (!_storyController.isUploading) return const SizedBox();

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: _storyController.uploadProgress / 100,
              backgroundColor: Colors.grey[200],
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 8),
            Text(
              _storyController.uploadStatus,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Get.back(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(() {
              return ElevatedButton(
                onPressed: _storyController.isUploading
                    ? null
                    : () => _uploadStory(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _storyController.isUploading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text('Share Story'),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _uploadStory() async {
    await _storyController.uploadStory(
      widget.mediaFile,
      widget.type,
      caption: _captionController.text.trim().isEmpty
          ? null
          : _captionController.text.trim(),
    );
  }
}