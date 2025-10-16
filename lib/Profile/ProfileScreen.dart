import 'dart:io';

import 'package:clock_tea/Auth/Controller/AuthController.dart';
import 'package:clock_tea/Auth/Controller/ProfileController.dart';
import 'package:clock_tea/Profile/AccountSettingsScreen.dart';
import 'package:clock_tea/Settings/NotificationsSettings.dart';
import 'package:clock_tea/Settings/privacyandSecurityScreen.dart';
import 'package:clock_tea/Support/SupportScreen.dart';
import 'package:clock_tea/Tea/SavedTeaScreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../Const/AppColors.dart';
import 'FollowRequestScreen.dart';
import 'FollowersRequestScreen.dart';
import 'FollowingScreen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AuthController controller=Get.put(AuthController());
  ProfileController profileController=Get.put(ProfileController());

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    profileController.fetchUserProfile();
  }
  // User data
  final Map<String, dynamic> user = {
    'name': '@Alexandra Chen',
    'username': '@alexandra_tea',
    'bio': 'Tea enthusiast & mindfulness advocate ☕️✨\nSharing daily tea rituals and mindful moments',
    'followers': '12.4K',
    'following': '856',
    'teas': '127',
  };

  // Settings cards data
  final List<Map<String, dynamic>> settingsCards = [
    {
      'title': 'Saved Teas',
      'subtitle': 'Your favorite tea moments',
      'icon': Icons.bookmark_border,
      'color': AppColors.gold,
      'count': 24,
    },
    {
      'title': 'Account Settings',
      'subtitle': 'Manage your profile and preferences',
      'icon': Icons.person_outline,
      'color': AppColors.teal,
    },
    {
      'title': 'Privacy & Security',
      'subtitle': 'Control your privacy settings',
      'icon': Icons.lock_outline,
      'color': AppColors.deepPurple,
    },
    {
      'title': 'Notifications',
      'subtitle': 'Manage your notifications',
      'icon': Icons.notifications_none,
      'color': AppColors.rosePink,
    },
  ];

  final List<Map<String, dynamic>> supportCards = [
    {
      'title': 'Help & Support',
      'subtitle': 'Get help and contact support',
      'icon': Icons.help_outline,
      'color': AppColors.teal,
    },
    {
      'title': 'Privacy Policy',
      'subtitle': 'Read our privacy policy',
      'icon': Icons.privacy_tip_outlined,
      'color': AppColors.deepPurple,
    },
    {
      'title': 'Terms of Service',
      'subtitle': 'Read our terms and conditions',
      'icon': Icons.description_outlined,
      'color': AppColors.gold,
    },
    {
      'title': 'About TeaTime',
      'subtitle': 'Learn more about our app',
      'icon': Icons.info_outline,
      'color': AppColors.rosePink,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header with Edit Profile
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.settings_outlined,
                      color: AppColors.deepPurple,
                    ),
                    onPressed: _openSettings,
                  ),
                  Text(
                    'Profile',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      color: AppColors.deepPurple,
                    ),
                    onPressed: _editProfile,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // User Avatar and Info
              _buildUserProfile(context),

              const SizedBox(height: 32),

              // Stats Overview
              _buildStatsOverview(),

              const SizedBox(height: 32),

              // Settings Section
              _buildSectionHeader('Preferences'),
              const SizedBox(height: 16),
              _buildSettingsGrid(),

              const SizedBox(height: 32),

              // Support Section
              _buildSectionHeader('Support & About'),
              const SizedBox(height: 16),
              _buildSupportGrid(),

              const SizedBox(height: 32),

              // Logout Button
              _buildLogoutButton(),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }





  Widget _buildStatsOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepPurple.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Obx(
        () {
          final user = profileController.userProfile;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              InkWell(
                onTap: (){
                  Get.to(()=> FollowRequestsScreen());
                  },
                  child: _buildStatItem('Request', "0", Icons.people_outline)),
              InkWell(
                onTap: (){
                  Get.to(() => FollowersScreen());
                },
                  child: _buildStatItem('Followers', user['followers']?.length.toString()??"0", Icons.people_outline)),
              InkWell(
                onTap: (){
                  Get.to(() => FollowingScreen());
                },
                  child: _buildStatItem('Following', user['following']?.length.toString()??"0", Icons.person_outline)),
            ],
          );
        }

      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
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
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
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

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: settingsCards.length,
      itemBuilder: (context, index) {
        return _buildSettingsCard(settingsCards[index]);
      },
    );
  }

  Widget _buildSettingsCard(Map<String, dynamic> card) {
    return GestureDetector(
      onTap: () => _handleSettingsTap(card['title']),
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon and Count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: card['color'].withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      card['icon'],
                      color: card['color'],
                      size: 20,
                    ),
                  ),
                  if (card['count'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.deepPurple,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        card['count'].toString(),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              // Text Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card['title'],
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card['subtitle'],
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildUserProfile(BuildContext context) {
    return Obx(() {
      final user = profileController.userProfile;

      // Determine image source
      String? imagePath = user['profileImage'];
      File? localImage = profileController.userProfile['localImage'] as File?;

      Widget imageWidget;

      if (localImage != null && localImage.existsSync()) {
        // ✅ Local file (gallery image)
        imageWidget = Image.file(localImage, fit: BoxFit.cover);
      }
      else if (imagePath != null && imagePath.startsWith('assets/')) {
        // ✅ Asset avatar
        imageWidget = Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
          const Icon(Icons.person, size: 50, color: AppColors.deepPurple),
        );
      }
      else if (imagePath != null && imagePath.startsWith('http')) {
        // ✅ Firebase Storage URL
        imageWidget = Image.network(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
          const Icon(Icons.person, size: 50, color: AppColors.deepPurple),
        );
      }
      else {
        // ✅ Default icon (no image)
        imageWidget =
        const Icon(Icons.person, size: 50, color: AppColors.deepPurple);
      }

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar with camera button
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.deepPurple, AppColors.rosePink],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.deepPurple.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.white,
                    ),
                    child: ClipOval(child: imageWidget),
                  ),
                ),
              ),

              // Camera icon (tap to change)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _changeProfilePicture(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.deepPurple,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 3),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: AppColors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Username
          Text(
            user['username'] ?? "No Username",
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          // Email
          Text(
            user['email'] ?? "",
            style: const TextStyle(
              color: AppColors.deepPurple,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 16),

          // Bio
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              user['bio'] ?? "No bio added yet.",
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    });
  }


  /// ✅ Pick image and update
  Future<void> _changeProfilePicture(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              runSpacing: 16,
              children: [
                Center(
                  child: Container(
                    height: 5,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    "Change Profile Picture",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepPurple,
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: AppColors.deepPurple),
                  title: const Text("Choose from Gallery"),
                  onTap: () async {
                    Navigator.pop(context);
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 70,
                    );
                    if (picked != null) {
                      final file = File(picked.path);
                      profileController.userProfile['localImage'] = file;
                      profileController.userProfile.refresh();
                      await profileController.updateProfileInfo(profileImage: file.path);
                      Get.snackbar("Updated", "Profile image updated successfully");
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.face_retouching_natural, color: AppColors.rosePink),
                  title: const Text("Choose an Avatar"),
                  onTap: () {
                    Navigator.pop(context);
                    _showAvatarDialog(context);
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAvatarDialog(BuildContext context) {
    final List<String> avatarPaths = [
      "assets/avatar/avatar1.png",
      "assets/avatar/avatar2.png",
      "assets/avatar/avatar3.png",
      "assets/avatar/avatar4.png",
      "assets/avatar/avatar5.png",
      "assets/avatar/avatar6.png",
      "assets/avatar/avatar7.png",
      "assets/avatar/avatar8.png",
      "assets/avatar/avatar9.png",
      "assets/avatar/avatar10.png",
    ];

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Select an Avatar",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.deepPurple,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: avatarPaths.map((path) {
                    return GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        profileController.userProfile['localImage'] = null;
                        profileController.userProfile['profileImage'] = path;
                        profileController.userProfile.refresh();

                        await profileController.updateProfileInfo(profileImage: path);
                        Get.snackbar("Updated", "Avatar updated successfully");
                      },
                      child: CircleAvatar(
                        radius: 34,
                        backgroundImage: AssetImage(path),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: AppColors.rosePink)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSupportGrid() {
    return Column(
      children: supportCards.map((card) {
        return _buildSupportCard(card);
      }).toList(),
    );
  }

  Widget _buildSupportCard(Map<String, dynamic> card) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepPurple.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: card['color'].withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            card['icon'],
            color: card['color'],
            size: 20,
          ),
        ),
        title: Text(
          card['title'],
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          card['subtitle'],
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: AppColors.textSecondary,
          size: 16,
        ),
        onTap: () => _handleSupportTap(card['title']),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      height: 56,
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
      child: TextButton.icon(
        icon: Icon(
          Icons.logout,
          color: AppColors.rosePink,
        ),
        label: Text(
          'Log Out',
          style: TextStyle(
            color: AppColors.rosePink,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: _showLogoutConfirmation,
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  void _openSettings() {
    print('Open settings');
  }

  void _editProfile() {
    print('Edit profile');
  }



  void _handleSettingsTap(String title) {
    switch (title) {
      case 'Saved Teas':
        Get.to(()=> SavedTeaScreen());
        break;
      case 'Account Settings':
        Get.to(()=> AccountSettingsScreen());
        break;
      case 'Privacy & Security':
        Get.to(()=> PrivacySecurityScreen());
        break;
      case 'Notifications':
        Get.to(()=> NotificationsScreen());
        break;
    }
  }

  void _handleSupportTap(String title) {
    switch (title) {
      case 'Help & Support':
        Get.to(()=> SupportScreen());
        break;
      case 'Privacy Policy':
        print('Navigate to Privacy Policy');
        break;
      case 'Terms of Service':
        print('Navigate to Terms of Service');
        break;
      case 'About TeaTime':
        print('Navigate to About TeaTime');
        break;
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.rosePink.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.logout,
                color: AppColors.rosePink,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Log Out',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to log out? You will need to sign in again to access your account.',
          style: TextStyle(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async{
            await  controller.logoutUser();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rosePink,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

}