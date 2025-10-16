import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Auth/Controller/ProfileController.dart';
import '../Const/AppColors.dart';


class PrivacySecurityScreen extends StatelessWidget {
  final ProfileController controller = Get.find<ProfileController>();

  PrivacySecurityScreen({super.key});

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
          'Privacy & Security',
          style: TextStyle(
            color: AppColors.textOnDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Obx(() {
        final privacy = controller.userProfile['privacy'] ?? {};

        bool isPrivate = privacy['private_account'] ?? false;
        bool allowTags = privacy['allow_tags'] ?? true;
        bool allowComments = privacy['allow_comment'] ?? true;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildPrivacySection(
                context,
                isPrivate: isPrivate,
                allowTags: allowTags,
                allowComments: allowComments,
              ),
              const SizedBox(height: 24),
              _buildSecuritySection(context),
              const SizedBox(height: 40),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPrivacySection(
      BuildContext context, {
        required bool isPrivate,
        required bool allowTags,
        required bool allowComments,
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
              const Icon(Icons.privacy_tip_outlined,
                  color: AppColors.deepPurple, size: 20),
              const SizedBox(width: 8),
              Text(
                'Privacy',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 🔹 Private Account
          _buildPrivacyOption(
            title: 'Private Account',
            subtitle: 'Only approved followers can see your posts',
            value: isPrivate,
            onChanged: (value) =>
                controller.updatePrivacySettings(privateAccount: value),
          ),

          _buildDivider(),

          // 🔹 Allow Tagging
          _buildPrivacyOption(
            title: 'Allow Tagging',
            subtitle: 'Let others tag you in posts',
            value: allowTags,
            onChanged: (value) =>
                controller.updatePrivacySettings(allowTags: value),
          ),

          _buildDivider(),

          // 🔹 Allow Comments
          _buildPrivacyOption(
            title: 'Allow Comments',
            subtitle: 'Let others comment on your posts',
            value: allowComments,
            onChanged: (value) =>
                controller.updatePrivacySettings(allowComment: value),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection(BuildContext context) {
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
              const Icon(Icons.security_outlined,
                  color: AppColors.deepPurple, size: 20),
              const SizedBox(width: 8),
              Text(
                'Security',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ListTile(
            leading: _buildIcon(Icons.lock_outline, AppColors.teal),
            title: Text(
              'Change Password',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Update your password regularly',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            trailing: Icon(Icons.arrow_forward_ios,
                color: AppColors.textSecondary, size: 16),
            onTap: () => print('Change password'),
          ),

          _buildDivider(),

          ListTile(
            leading: _buildIcon(Icons.devices_outlined, AppColors.gold),
            title: Text(
              'Active Sessions',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Manage your logged-in devices',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            trailing: Icon(Icons.arrow_forward_ios,
                color: AppColors.textSecondary, size: 16),
            onTap: () => print('Active sessions'),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyOption({
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
              Text(title,
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
    height: 32,
    color: AppColors.cream,
    thickness: 1,
  );

  Widget _buildIcon(IconData icon, Color color) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, color: color, size: 20),
  );
}
