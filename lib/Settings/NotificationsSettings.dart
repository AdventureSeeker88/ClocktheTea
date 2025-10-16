import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Auth/Controller/ProfileController.dart';
import '../Const/AppColors.dart';


class NotificationsScreen extends StatelessWidget {
  final ProfileController controller = Get.find<ProfileController>();

  NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.deepPurple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textOnDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.textOnDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Obx(() {
        final notifications = controller.userProfile['notifications'] ?? {};

        bool pushNotifications = notifications['push_notifications'] ?? true;
        bool likeNotifications = notifications['like_notifications'] ?? true;
        bool commentsNotifications = notifications['comments_notifications'] ?? true;
        bool newFollowers = notifications['new_followers'] ?? true;
        bool newTeaPost = notifications['new_tea_post'] ?? true;
        bool teaRecommendations = notifications['tea_recommendations'] ?? true;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildChannelsSection(pushNotifications),
              const SizedBox(height: 24),
              _buildSocialNotifications(
                likeNotifications,
                commentsNotifications,
                newFollowers,
              ),
              const SizedBox(height: 24),
              _buildTeaNotifications(
                newTeaPost,
                teaRecommendations,
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      }),
    );
  }

  // 🔹 Notification Channels Section
  Widget _buildChannelsSection(bool pushNotifications) {
    return _buildContainer(
      title: 'Notification Channels',
      icon: Icons.notifications_active_outlined,
      children: [
        _buildOption(
          title: 'Push Notifications',
          subtitle: 'Receive notifications on your device',
          value: pushNotifications,
          onChanged: (value) {
            controller.updateNotificationSettings(pushNotifications: value);
          },
        ),
      ],
    );
  }

  // 🔹 Social Notifications
  Widget _buildSocialNotifications(
      bool likes, bool comments, bool follows) {
    return _buildContainer(
      title: 'Social Interactions',
      icon: Icons.people_outline,
      children: [
        _buildOption(
          title: 'Likes',
          subtitle: 'When someone likes your posts',
          value: likes,
          onChanged: (value) {
            controller.updateNotificationSettings(likeNotifications: value);
          },
        ),
        _buildDivider(),
        _buildOption(
          title: 'Comments',
          subtitle: 'When someone comments on your posts',
          value: comments,
          onChanged: (value) {
            controller.updateNotificationSettings(commentsNotifications: value);
          },
        ),
        _buildDivider(),
        _buildOption(
          title: 'New Followers',
          subtitle: 'When someone follows you',
          value: follows,
          onChanged: (value) {
            controller.updateNotificationSettings(newFollowers: value);
          },
        ),
      ],
    );
  }

  // 🔹 Tea Notifications
  Widget _buildTeaNotifications(bool newPosts, bool recommendations) {
    return _buildContainer(
      title: 'Tea Community',
      icon: Icons.local_cafe_outlined,
      children: [
        _buildOption(
          title: 'New Tea Posts',
          subtitle: 'From people you follow',
          value: newPosts,
          onChanged: (value) {
            controller.updateNotificationSettings(newTeaPost: value);
          },
        ),
        _buildDivider(),
        _buildOption(
          title: 'Tea Recommendations',
          subtitle: 'Personalized tea suggestions',
          value: recommendations,
          onChanged: (value) {
            controller.updateNotificationSettings(teaRecommendations: value);
          },
        ),
      ],
    );
  }

  // 🔹 Shared UI Widgets
  Widget _buildContainer({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.deepPurple, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildOption({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
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
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.deepPurple,
        ),
      ],
    );
  }

  Widget _buildDivider() => Divider(
    height: 24,
    color: AppColors.cream,
    thickness: 1,
  );
}
