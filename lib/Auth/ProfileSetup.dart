import 'dart:io';
import 'package:clock_tea/Const/AppColors.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'Controller/ProfileController.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final ProfileController controller = Get.put(ProfileController());

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  String? selectedPronoun;
  String? selectedAvatar; // Local asset path
  String? selectedOrientation;
  int? selectedAge;
  File? galleryImage; // Image file from gallery

  final picker = ImagePicker();

  final List<String> pronouns = ["He/Him", "She/Her", "They/Them", "Other"];
  final List<String> orientations = [
    "Gay",
    "Bisexual",
    "Trans",
    "Queer",
    "Nonbinary",
    "Other",
  ];

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
    "assets/avatar/avatar11.png",
    "assets/avatar/avatar12.png",
    "assets/avatar/avatar13.png",
    "assets/avatar/avatar14.png",
    "assets/avatar/avatar15.png",
    "assets/avatar/avatar16.png",
    "assets/avatar/avatar17.png",
    "assets/avatar/avatar18.png",
    "assets/avatar/avatar19.png",
    "assets/avatar/avatar20.png",
  ];

  /// ✅ Show avatar dialog
  void _showAvatarDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Choose Your Avatar",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepPurple,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: avatarPaths.map((path) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedAvatar = path;
                          galleryImage = null; // clear gallery image
                        });
                        Navigator.pop(context);
                      },
                      child: CircleAvatar(
                        radius: 35,
                        backgroundImage: AssetImage(path),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: AppColors.rosePink),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ✅ Pick image from gallery
  Future<void> _pickFromGallery() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        galleryImage = File(picked.path);
        selectedAvatar = null; // clear asset avatar
      });
    }
  }

  /// ✅ Save Profile
  Future<void> _saveProfile() async {
    if ((selectedAvatar == null && galleryImage == null) ||
        usernameController.text.trim().isEmpty ||
        selectedOrientation == null ||
        selectedAge == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all required fields.")),
      );
      return;
    }

    String profileImagePath;

    // if user chose local avatar
    if (selectedAvatar != null) {
      profileImagePath = selectedAvatar!;
    }
    // if user uploaded custom image
    else {
      profileImagePath = galleryImage!.path;
    }

    await controller.saveUserProfile(
      profileImage: profileImagePath,
      username: usernameController.text.trim(),
      pronun: selectedPronoun ?? "Not specified",
      sexualOrientations: selectedOrientation!,
      age: selectedAge!,
      bio: bioController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Text(
                "Set Up Your Profile",
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.deepPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // ✅ Avatar Section
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.teal.withOpacity(0.2),
                    backgroundImage: galleryImage != null
                        ? FileImage(galleryImage!)
                        : (selectedAvatar != null
                                  ? AssetImage(selectedAvatar!)
                                  : null)
                              as ImageProvider<Object>?,
                    child: (selectedAvatar == null && galleryImage == null)
                        ? const Icon(
                            Icons.person,
                            color: AppColors.deepPurple,
                            size: 45,
                          )
                        : null,
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.add_circle,
                      color: AppColors.deepPurple,
                    ),
                    onSelected: (value) {
                      if (value == 'avatar') _showAvatarDialog();
                      if (value == 'gallery') _pickFromGallery();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'avatar',
                        child: Text("Choose Avatar"),
                      ),
                      const PopupMenuItem(
                        value: 'gallery',
                        child: Text("Upload from Gallery"),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Username
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "Enter username",
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: AppColors.teal,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Pronouns
              DropdownButtonFormField<String>(
                value: selectedPronoun,
                icon: const Icon(
                  Icons.arrow_drop_down_circle,
                  color: AppColors.deepPurple,
                ),

                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "Select pronouns",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                ),
                items: pronouns
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (val) => setState(() => selectedPronoun = val),
              ),
              const SizedBox(height: 16),

              // Orientation
              DropdownButtonFormField<String>(
                value: selectedOrientation,
                icon: const Icon(
                  Icons.arrow_drop_down_circle,
                  color: AppColors.deepPurple,
                ),

                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "Select orientation",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                ),
                items: orientations
                    .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                    .toList(),
                onChanged: (val) => setState(() => selectedOrientation = val),
              ),
              const SizedBox(height: 16),

              // Age
              DropdownButtonFormField<int>(
                value: selectedAge,
                icon: const Icon(
                  Icons.arrow_drop_down_circle,
                  color: AppColors.deepPurple,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "Select age",

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                ),
                items: List.generate(83, (i) {
                  final age = i + 18;
                  return DropdownMenuItem(
                    value: age,
                    child: Text(age.toString()),
                  );
                }),
                onChanged: (val) => setState(() => selectedAge = val),
              ),
              const SizedBox(height: 16),

              // Bio
              TextField(
                controller: bioController,
                maxLines: 3,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "Write a short bio...",
                  prefixIcon: const Icon(Icons.edit, color: AppColors.rosePink),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              Obx(() {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.isSaving.value ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepPurple,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: controller.isSaving.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Save Profile",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
