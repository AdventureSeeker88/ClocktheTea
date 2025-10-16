import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../Const/AppColors.dart';
import 'Controller/TeaController.dart';

class CreateTeaScreen extends StatefulWidget {
  const CreateTeaScreen({super.key});

  @override
  State<CreateTeaScreen> createState() => _CreateTeaScreenState();
}

class _CreateTeaScreenState extends State<CreateTeaScreen> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  String _selectedImage = '';
  bool _isPublic = true;
  List<String> _tags = [];
  final TeaController _teaController = Get.put(TeaController());
  final ImagePicker _picker = ImagePicker();
  File? _pickedFile;
  bool _isVideo = false;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.deepPurple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textOnDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Tea Post',
          style: TextStyle(
            color: AppColors.textOnDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _validateAndSubmit,
            child: const Text(
              'Post',
              style: TextStyle(
                color: AppColors.textOnDark,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Upload Section
            _buildImageUploadSection(),

            const SizedBox(height: 24),

            // Caption Section
            _buildCaptionSection(),

            const SizedBox(height: 24),

            // Tags Section
            _buildTagsSection(),

            const SizedBox(height: 24),

            // Privacy Settings
            _buildPrivacySection(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Container(
      width: double.infinity,
      height: 200,
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
      child: _selectedImage.isEmpty
          ? GestureDetector(
        onTap: _pickMedia,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.deepPurple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_photo_alternate_outlined,
                color: AppColors.deepPurple,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add Tea Moment',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to upload photo or video',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      )
          : Stack(
        children: [
          // ✅ Show image or video preview
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _isVideo
                ? Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black12,
                  child: const Icon(
                    Icons.videocam,
                    color: Colors.deepPurple,
                    size: 60,
                  ),
                ),
                const Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 64,
                ),
              ],
            )
                : Image.file(
              File(_selectedImage),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          // ✅ Edit button
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: _pickMedia,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.deepPurple.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit,
                  color: AppColors.white,
                  size: 16,
                ),
              ),
            ),
          ),

          // ✅ Remove button (optional)
          Positioned(
            top: 8,
            left: 8,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedImage = '';
                  _pickedFile = null;
                  _isVideo = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCaptionSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepPurple.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Share Your Tea Moment',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _captionController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'What makes this tea moment special? Share your thoughts...',
              hintStyle: TextStyle(color: AppColors.textSecondary),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${_captionController.text.length}/500',
                style: TextStyle(
                  color: _captionController.text.length > 500 ? AppColors.rosePink : AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepPurple.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Hashtags',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Add tags to help others discover your post',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),

          // Tag Input Field
          Container(
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.deepPurple.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: InputDecoration(
                      hintText: 'Type a tag and press enter...',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      prefixIcon: Icon(Icons.tag, color: AppColors.deepPurple),
                    ),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    onSubmitted: (value) {
                      _addTag(value);
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add_circle,
                    color: AppColors.deepPurple,
                  ),
                  onPressed: () {
                    if (_tagController.text.isNotEmpty) {
                      _addTag(_tagController.text);
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Selected Tags
          if (_tags.isNotEmpty) ...[
            Text(
              'Added Tags:',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((tag) {
                return _buildTagChip(tag);
              }).toList(),
            ),
          ],

          // Suggested Tags
          const SizedBox(height: 16),
          Text(
            'Popular Tags:',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSuggestedTag('#TeaLovers'),
              _buildSuggestedTag('#MorningRitual'),
              _buildSuggestedTag('#Mindfulness'),
              _buildSuggestedTag('#SelfCare'),
              _buildSuggestedTag('#TeaTime'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.deepPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag.startsWith('#') ? tag : '#$tag',
            style: TextStyle(
              color: AppColors.deepPurple,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _removeTag(tag),
            child: Icon(
              Icons.close,
              color: AppColors.deepPurple,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedTag(String tag) {
    return GestureDetector(
      onTap: () => _addTag(tag.replaceFirst('#', '')),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.deepPurple.withOpacity(0.3)),
        ),
        child: Text(
          tag,
          style: TextStyle(
            color: AppColors.deepPurple,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepPurple.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Share With',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Public Option
          _buildPrivacyOption(
            title: 'Public',
            subtitle: 'Visible to everyone',
            icon: Icons.public,
            isSelected: _isPublic,
            onTap: () {
              setState(() {
                _isPublic = true;
              });
            },
          ),

          const SizedBox(height: 12),

          // Friends Only Option
          _buildPrivacyOption(
            title: 'Friends Only',
            subtitle: 'Visible only to your friends',
            icon: Icons.people_outline,
            isSelected: !_isPublic,
            onTap: () {
              setState(() {
                _isPublic = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.deepPurple.withOpacity(0.1) : AppColors.cream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.deepPurple : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.deepPurple : AppColors.textSecondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.white : AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.deepPurple,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  void _addTag(String tag) {
    if (tag.trim().isNotEmpty) {
      final formattedTag = tag.trim().startsWith('#') ? tag.trim() : '#${tag.trim()}';

      if (!_tags.contains(formattedTag) && _tags.length < 10) {
        setState(() {
          _tags.add(formattedTag);
          _tagController.clear();
        });
      }
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _pickMedia() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: Colors.deepPurple),
              title: const Text('Upload Photo'),
              onTap: () => Navigator.pop(context, 'image'),
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.deepPurple),
              title: const Text('Upload Video'),
              onTap: () => Navigator.pop(context, 'video'),
            ),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.redAccent),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );

    if (choice == null) return;

    final picked = choice == 'image'
        ? await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80)
        : await _picker.pickVideo(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _pickedFile = File(picked.path);
        _selectedImage = picked.path;
        _isVideo = (choice == 'video');
      });
    }
  }



  void _validateAndSubmit() async {
    if (_pickedFile == null) {
      _showError('Please add a photo or video');
      return;
    }

    if (_captionController.text.isEmpty) {
      _showError('Please add a caption');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.deepPurple),
      ),
    );

    try {
      await _teaController.createTea(
        contentFile: _pickedFile!,
        isVideo: _isVideo,
        teaMoment: _captionController.text,
        hashtags: _tags,
        privacy: _isPublic ? 'public' : 'private',
      );

      Navigator.pop(context);
      _showSuccessDialog();
    } catch (e) {
      Navigator.pop(context);
      _showError('Failed to upload: $e');
    }
  }



  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.rosePink,
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.teal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_cafe,
                color: AppColors.teal,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tea Post Created!',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isPublic
                  ? 'Your tea moment is now public'
                  : 'Your tea moment is private',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to feed
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepPurple,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }


  @override
  void dispose() {
    _captionController.dispose();
    _tagController.dispose();
    super.dispose();
  }
}