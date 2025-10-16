import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Auth/Controller/ProfileController.dart';
import '../Const/AppColors.dart';
// ✅ Import your controller

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final ProfileController profileController = Get.find<ProfileController>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  String? _selectedPronoun;
  String? _selectedOrientation;
  int? _selectedAge;

  final List<String> _pronouns = ["He/Him", "She/Her", "They/Them", "Other"];
  final List<String> _orientations = [
    "Gay",
    "Bisexual",
    "Trans",
    "Queer",
    "Nonbinary",
    "Other",
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// ✅ Load existing user info from controller
  void _loadUserData() {
    final user = profileController.userProfile;

    _usernameController.text = user['username'] ?? '';
    _bioController.text = user['bio'] ?? '';
    _selectedPronoun = user['pronun'];
    _selectedOrientation = user['sexual_orientations'];
    _selectedAge = user['age'];
  }

  /// ✅ Save updated data to Firebase via controller
  Future<void> _saveChanges() async {
    if (_usernameController.text.trim().isEmpty ||
        _selectedPronoun == null ||
        _selectedOrientation == null ||
        _selectedAge == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.rosePink,
          content: const Text('Please complete all required fields'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    await profileController.updateProfileInfo(
      username: _usernameController.text.trim(),
      pronun: _selectedPronoun,
      sexualOrientations: _selectedOrientation,
      age: _selectedAge,
      bio: _bioController.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.teal,
        content: const Text('Profile updated successfully'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

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
          'Account Settings',
          style: TextStyle(
            color: AppColors.textOnDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Obx(() => TextButton(
            onPressed: profileController.isSaving.value
                ? null
                : () => _saveChanges(),
            child: profileController.isSaving.value
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: AppColors.textOnDark,
                strokeWidth: 2,
              ),
            )
                : const Text(
              'Save',
              style: TextStyle(
                color: AppColors.textOnDark,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          )),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileInfoSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoSection() {
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
            'Profile Information',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildTextField(
            label: 'Username',
            controller: _usernameController,
            icon: Icons.alternate_email,
          ),

          const SizedBox(height: 16),

          _buildDropdownField(
            label: 'Pronouns',
            value: _selectedPronoun,
            hintText: 'Select pronouns',
            items: _pronouns,
            onChanged: (value) => setState(() => _selectedPronoun = value),
            icon: Icons.person_outline,
          ),

          const SizedBox(height: 16),

          _buildDropdownField(
            label: 'Sexual Orientation',
            value: _selectedOrientation,
            hintText: 'Select orientation',
            items: _orientations,
            onChanged: (value) => setState(() => _selectedOrientation = value),
            icon: Icons.diversity_3_outlined,
          ),

          const SizedBox(height: 16),

          _buildAgeDropdown(),

          const SizedBox(height: 16),

          _buildTextField(
            label: 'Bio',
            controller: _bioController,
            icon: Icons.description_outlined,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.deepPurple.withOpacity(0.1)),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              prefixIcon: Icon(icon, color: AppColors.deepPurple),
            ),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required String hintText,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.deepPurple.withOpacity(0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonFormField<String>(
              value: value,
              decoration: InputDecoration(
                border: InputBorder.none,
                prefixIcon: Icon(icon, color: AppColors.deepPurple),
              ),
              items: items
                  .map((String item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item,
                    style: TextStyle(
                        color: AppColors.textPrimary, fontSize: 14)),
              ))
                  .toList(),
              onChanged: onChanged,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              icon: Icon(Icons.arrow_drop_down, color: AppColors.deepPurple),
              isExpanded: true,
              dropdownColor: AppColors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Age',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.deepPurple.withOpacity(0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonFormField<int>(
              value: _selectedAge,
              decoration: const InputDecoration(
                border: InputBorder.none,
                prefixIcon:
                Icon(Icons.cake_outlined, color: AppColors.deepPurple),
              ),
              items: List.generate(83, (i) {
                final age = i + 18;
                return DropdownMenuItem<int>(
                  value: age,
                  child: Text(age.toString(),
                      style: TextStyle(
                          color: AppColors.textPrimary, fontSize: 14)),
                );
              }),
              onChanged: (value) => setState(() => _selectedAge = value),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              icon: Icon(Icons.arrow_drop_down, color: AppColors.deepPurple),
              isExpanded: true,
              dropdownColor: AppColors.white,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}
