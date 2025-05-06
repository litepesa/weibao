import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:weibao/constants.dart';
import 'package:weibao/features/auth/controller/auth_controller.dart';
import 'package:weibao/routes/app_router.dart';
import 'package:weibao/shared/utils/global_methods.dart';
import 'package:weibao/shared/widgets/app_bar_back_button.dart';

class UserInformationScreen extends ConsumerStatefulWidget {
  const UserInformationScreen({super.key});

  @override
  ConsumerState<UserInformationScreen> createState() => _UserInformationScreenState();
}

class _UserInformationScreenState extends ConsumerState<UserInformationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _aboutMeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  File? _profileImage;
  bool _isImageProcessing = false;
  bool _isSavingData = false;

  @override
  void initState() {
    super.initState();
    _aboutMeController.text = "Hey there, I'm using WeiBao";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutMeController.dispose();
    super.dispose();
  }

  Future<void> _selectImage(bool fromCamera) async {
    try {
      setState(() {
        _isImageProcessing = true;
      });

      final File? pickedImage = await pickImage(
        fromCamera: fromCamera,
        onFail: (String message) {
          if (mounted) {
            showSnackBar(context, message);
          }
        },
      );

      if (pickedImage != null) {
        await _cropImage(pickedImage.path);
      } else {
        if (mounted) {
          showSnackBar(context, 'No image selected');
        }
      }
    } catch (e) {
      debugPrint("Error selecting image: $e");
      if (mounted) {
        showSnackBar(context, 'Error selecting image: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImageProcessing = false;
        });
        Navigator.pop(context);
      }
    }
  }

  Future<void> _cropImage(String? filePath) async {
    if (filePath == null) return;
    
    try {
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: filePath,
        maxHeight: 800,
        maxWidth: 800,
        compressQuality: 90,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.white,
            toolbarWidgetColor: const Color(0xFF07C160),
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            statusBarColor: Colors.white,
            activeControlsWidgetColor: const Color(0xFF07C160),
          ),
          IOSUiSettings(
            minimumAspectRatio: 1.0,
            aspectRatioLockEnabled: true,
            title: 'Crop Image',
          ),
        ],
      );

      if (croppedFile != null) {
        if (mounted) {
          setState(() {
            _profileImage = File(croppedFile.path);
          });
        }
      } else {
        if (mounted) {
          showSnackBar(context, 'Image cropping cancelled');
        }
      }
    } catch (e) {
      debugPrint("Error cropping image: $e");
      if (mounted) {
        showSnackBar(context, 'Error cropping image: $e');
      }
    }
  }

  void _showImageOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 8.0, bottom: 16.0),
              child: Text(
                'Profile Photo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(),
            ListTile(
              onTap: () => _selectImage(true),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF07C160).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: Color(0xFF07C160)),
              ),
              title: const Text('Take Photo'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
            const Divider(),
            ListTile(
              onTap: () => _selectImage(false),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF07C160).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.image, color: Color(0xFF07C160)),
              ),
              title: const Text('Choose from Gallery'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  void _saveUserData() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSavingData = true;
    });
    
    try {
      final authController = ref.read(authControllerProvider.notifier);

      await authController.saveUserData(
        name: _nameController.text.trim(),
        aboutMe: _aboutMeController.text.trim(), 
        profileImage: _profileImage,
        onSuccess: () {
          if (mounted) {
            AppRouter.navigateAndRemoveUntil(context, Constants.homeScreen);
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isSavingData = false;
            });
            showSnackBar(context, error);
          }
        },
      );
    } catch (e) {
      debugPrint("Error saving user data: $e");
      if (mounted) {
        setState(() {
          _isSavingData = false;
        });
        showSnackBar(context, 'Error saving user data: $e');
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_nameController.text.isNotEmpty || _profileImage != null) {
      return await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text('You have unsaved changes. Are you sure you want to go back?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF07C160))),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Discard', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ) ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _isSavingData;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: AppBarBackButton(
            onPressed: () async {
              if (await _onWillPop()) Navigator.of(context).pop();
            },
          ),
          title: Text(
            'Set Up Your Profile',
            style: GoogleFonts.poppins(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
        body: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Container(
              color: Colors.white,
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 20,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Profile image selector
                          Tooltip(
                            message: 'Tap to select image',
                            child: GestureDetector(
                              onTap: _showImageOptionsBottomSheet,
                              child: Center(
                                child: Stack(
                                  children: [
                                    // Profile image
                                    Container(
                                      width: 130,
                                      height: 130,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.grey.shade100,
                                        border: Border.all(
                                          color: const Color(0xFF07C160).withOpacity(0.4),
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: _profileImage != null
                                            ? Image.file(
                                                _profileImage!,
                                                fit: BoxFit.cover,
                                                width: 130,
                                                height: 130,
                                              )
                                            : Center(
                                                child: Icon(
                                                  Icons.person,
                                                  size: 60,
                                                  color: Colors.grey.shade400,
                                                ),
                                              ),
                                      ),
                                    ),
                                    
                                    // Camera icon
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF07C160),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 5,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          // Helper text
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0, bottom: 36.0),
                            child: Text(
                              'Add a profile photo to personalize your account',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          
                          // Name field
                          TextFormField(
                            controller: _nameController,
                            autofocus: true,
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words,
                            validator: (value) {
                              if (value == null || value.trim().length < 3) {
                                return 'Please enter at least 3 characters';
                              }
                              return null;
                            },
                            style: GoogleFonts.poppins(fontSize: 16),
                            decoration: InputDecoration(
                              hintText: 'Enter your name',
                              labelText: 'Your Name',
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: Colors.grey.shade600,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF07C160), width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // About me field
                          TextFormField(
                            controller: _aboutMeController,
                            keyboardType: TextInputType.multiline,
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: 3,
                            style: GoogleFonts.poppins(fontSize: 16),
                            decoration: InputDecoration(
                              hintText: 'Tell us about yourself',
                              labelText: 'About Me',
                              prefixIcon: Icon(
                                Icons.description_outlined,
                                color: Colors.grey.shade600,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF07C160), width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            ),
                          ),
                          
                          // Privacy section
                          const SizedBox(height: 30),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF07C160).withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF07C160).withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.shield_outlined,
                                      color: Color(0xFF07C160),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Privacy by Design',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  Constants.privacyManifesto,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 8),
                               Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline,
                                      color: Color(0xFF07C160),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        Constants.privacyFeatures,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.lock_outline,
                                      color: Color(0xFF07C160),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        Constants.securityInfo,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Continue button
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF07C160).withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                  spreadRadius: 0,
                                ),
                              ],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF07C160),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              onPressed: isLoading ? null : _saveUserData,
                              child: isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Get Started',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Loading overlay for image processing
                  if (_isImageProcessing)
                    Container(
                      color: Colors.black.withOpacity(0.5),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF07C160),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}