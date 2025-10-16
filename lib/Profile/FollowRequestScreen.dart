import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'Controller/FollowController.dart';

class FollowRequestsScreen extends StatelessWidget {
  final FollowController _controller = Get.put(FollowController());

  FollowRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Follow Requests',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _controller.getFollowRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return _buildEmptyState();
        }

        return _buildRequestsList(requests);
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading requests...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add_rounded,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'No Follow Requests',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When someone requests to follow you, it will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList(List<Map<String, dynamic>> requests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Text(
            '${requests.length} Pending Request${requests.length == 1 ? '' : 's'}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: requests.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 0.5,
              color: Colors.grey[200],
            ),
            itemBuilder: (context, index) {
              final request = requests[index];
              return _buildRequestItem(request);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRequestItem(Map<String, dynamic> request) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _buildProfileAvatar(request),
          const SizedBox(width: 12),
          Expanded(
            child: _buildUserInfo(request),
          ),
          const SizedBox(width: 12),
          _buildActionButtons(request),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(Map<String, dynamic> request) {
    final profileImage = request['profileImage']?.toString() ?? '';

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: ClipOval(
        child: profileImage.isNotEmpty
            ? CachedNetworkImage(
          imageUrl: profileImage,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[100],
            child: const Icon(
              Icons.person,
              color: Colors.grey,
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[100],
            child: const Icon(
              Icons.person,
              color: Colors.grey,
            ),
          ),
        )
            : Container(
          color: Colors.grey[100],
          child: const Icon(
            Icons.person,
            color: Colors.grey,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo(Map<String, dynamic> request) {
    final username = request['username']?.toString() ?? 'Unknown User';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          username,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          'Wants to follow you',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '2 days ago', // You can replace this with actual timestamp if available
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> request) {
    final requesterId = request['uid']?.toString() ?? '';

    return Row(
      children: [
        _buildAcceptButton(requesterId),
        const SizedBox(width: 8),
        _buildDeleteButton(requesterId),
      ],
    );
  }

  Widget _buildAcceptButton(String requesterId) {
    return Obx(() {
      final isLoading = false.obs; // You can manage loading state in controller

      return isLoading.value
          ? Container(
        width: 36,
        height: 36,
        padding: const EdgeInsets.all(8),
        child: const CircularProgressIndicator(strokeWidth: 2),
      )
          : GestureDetector(
        onTap: () => _controller.acceptFollowRequest(requesterId),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.green[50],
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.green[100]!,
              width: 1,
            ),
          ),
          child: Icon(
            Icons.check_rounded,
            size: 20,
            color: Colors.green[600],
          ),
        ),
      );
    });
  }

  Widget _buildDeleteButton(String requesterId) {
    return GestureDetector(
      onTap: () => _showDeleteConfirmation(requesterId),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.red[50],
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.red[100]!,
            width: 1,
          ),
        ),
        child: Icon(
          Icons.close_rounded,
          size: 20,
          color: Colors.red[600],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String requesterId) {
    Get.dialog(
      AlertDialog(
        title: const Text(
          'Ignore Request?',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'This person will not be able to follow you. You can still send them a follow request later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              // Add your delete/ignore logic here
              _ignoreFollowRequest(requesterId);
            },
            child: const Text(
              'Ignore',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  void _ignoreFollowRequest(String requesterId) {
    // Add your ignore/delete follow request logic here
    Get.snackbar(
      'Request Ignored',
      'Follow request has been ignored',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.grey[800],
      colorText: Colors.white,
    );
  }
}