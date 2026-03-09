import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:ismart_shop/providers/auth_provider.dart' as app_auth;
import 'package:ismart_shop/utils/ios_theme.dart';
import 'package:ismart_shop/widgets/ios_app_bar.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<app_auth.AuthProvider>();
    _nameController.text = authProvider.userModel?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickMedia(
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _saveProfile() async {
    final authProvider = context.read<app_auth.AuthProvider>();
    final String newName = _nameController.text.trim();

    if (newName.isEmpty) {
      _showErrorDialog('Please enter your name');
      return;
    }

    // Show loading indicator
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: const CupertinoActivityIndicator(),
      ),
    );

    String? imageUrl;
    if (_selectedImage != null) {
      try {
        // Upload image to Firebase Storage
        final storage = FirebaseStorage.instance;
        final storageRef = storage.ref().child(
            'profile_images/${authProvider.userModel?.id}/${DateTime.now().millisecondsSinceEpoch}');

        // Determine file type and set metadata
        final mimeType = _getMimeType(_selectedImage!.path);
        final metadata = SettableMetadata(contentType: mimeType);

        // Upload the file
        await storageRef.putFile(File(_selectedImage!.path), metadata);

        // Get the download URL
        imageUrl = await storageRef.getDownloadURL();
        debugPrint('Image uploaded successfully: $imageUrl');
      } catch (e) {
        debugPrint('Error uploading image: $e');
        // Fallback to local path if upload fails
        imageUrl = _selectedImage!.path;
      }
    }

    await authProvider.updateProfile(
      displayName: newName,
      profileImageUrl: imageUrl,
    );

    // Pop the loading indicator
    Navigator.pop(context);

    if (authProvider.error.isNotEmpty) {
      _showErrorDialog(authProvider.error);
    } else {
      // Pop the screen
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  String _getMimeType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      case 'bmp':
        return 'image/bmp';
      case 'tiff':
      case 'tif':
        return 'image/tiff';
      default:
        return 'image/jpeg';
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<app_auth.AuthProvider>();

    return Scaffold(
      backgroundColor: IOSColors.secondarySystemBackground,
      appBar: IOSNavigationBar(
        title: 'Edit Profile',
        automaticallyImplyLeading: true,
        actions: [
          CupertinoButton(
            onPressed: authProvider.isLoading ? null : _saveProfile,
            child: const Text(
              'Save',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: IOSColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(IOSSpacing.md),
        child: Column(
          children: [
            const SizedBox(height: IOSSpacing.lg),
            // Profile Picture Section
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: IOSColors.primary.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(60),
                        child: _selectedImage != null
                            ? Image.file(
                                File(_selectedImage!.path),
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              )
                            : authProvider.userModel?.profileImageUrl != null
                                ? Image.network(
                                    authProvider.userModel!.profileImageUrl!,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildPlaceholderIcon();
                                    },
                                  )
                                : _buildPlaceholderIcon(),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: IOSColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: IOSColors.systemBackground,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          CupertinoIcons.camera_fill,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: IOSSpacing.md),
            const Text(
              'Tap to change photo',
              style: TextStyle(
                color: IOSColors.labelSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: IOSSpacing.xl),
            // Name Field
            IOSCard(
              child: Column(
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: 'Name',
                    placeholder: 'Enter your name',
                    icon: CupertinoIcons.person_fill,
                  ),
                ],
              ),
            ),
            const SizedBox(height: IOSSpacing.xl),
            // Email (read-only)
            IOSCard(
              child: Column(
                children: [
                  _buildReadOnlyField(
                    label: 'Email',
                    value: authProvider.userModel?.email ?? 'Not set',
                    icon: CupertinoIcons.envelope_fill,
                  ),
                ],
              ),
            ),
            const SizedBox(height: IOSSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: IOSColors.tertiarySystemBackground,
      ),
      child: const Icon(
        CupertinoIcons.person_fill,
        size: 60,
        color: IOSColors.labelTertiary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: IOSSpacing.sm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: IOSColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
            ),
            child: Icon(icon, color: IOSColors.primary, size: 20),
          ),
          const SizedBox(width: IOSSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: IOSColors.labelSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                CupertinoTextField(
                  controller: controller,
                  placeholder: placeholder,
                  style: const TextStyle(
                    fontSize: 16,
                    color: IOSColors.labelPrimary,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.transparent),
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: IOSSpacing.sm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: IOSColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
            ),
            child: Icon(icon, color: IOSColors.primary, size: 20),
          ),
          const SizedBox(width: IOSSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: IOSColors.labelSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: IOSColors.labelTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
