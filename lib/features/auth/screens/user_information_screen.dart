import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:weibao/constants.dart';
import 'package:weibao/features/auth/provider/auth_provider.dart';
import 'package:weibao/models/user_model.dart';
import 'package:weibao/shared/theme/theme_constants.dart';
import 'package:weibao/shared/utils/global_methods.dart';

class UserInformationScreen extends ConsumerStatefulWidget {
  const UserInformationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UserInformationScreen> createState() => _UserInformationScreenState();
}

class _UserInformationScreenState extends ConsumerState<UserInformationScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _aboutMeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  File? _profileImage;
  bool _isImageProcessing = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Set default about text
    _aboutMeController.text = "Hey there, I'm using WeiBao";
    
    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _aboutMeController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  // Select profile image
  Future<void> _selectImage(bool fromCamera) async {
    setState(() {
      _isImageProcessing = true;
    });
    
    try {
      final File? pickedImage = await pickImage(
        fromCamera: fromCamera,
        onFail: (message) {
          showSnackBar(context, message);
        },
      );
      
      if (pickedImage != null) {
        await _cropImage(pickedImage.path);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      showSnackBar(context, 'Failed to pick image');
    } finally {
      setState(() {
        _isImageProcessing = false;
      });
      
      if (mounted) Navigator.pop(context);
    }
  }
  
  // Crop selected image
  Future<void> _cropImage(String imagePath) async {
    try {
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        maxHeight: 800,
        maxWidth: 800,
        compressQuality: 85,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: AppColors.surface,
            toolbarWidgetColor: AppColors.primaryGreen,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            statusBarColor: AppColors.surface,
            activeControlsWidgetColor: AppColors.primaryGreen,
          ),
          IOSUiSettings(
            minimumAspectRatio: 1.0,
            aspectRatioLockEnabled: true,
            title: 'Crop Image',
          ),
        ],
      );
      
      if (croppedFile != null) {
        setState(() {
          _profileImage = File(croppedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error cropping image: $e');
      showSnackBar(context, 'Failed to crop image');
    }
  }
  
  // Show image source bottom sheet
  void _showImageSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
                  color: Colors.white,
                ),
              ),
            ),
            const Divider(color: AppColors.border),
            ListTile(
              onTap: () => _selectImage(true),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: AppColors.primaryGreen),
              ),
              title: const Text(
                'Take Photo',
                style: TextStyle(color: Colors.white),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
            ),
            const Divider(color: AppColors.border),
            ListTile(
              onTap: () => _selectImage(false),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.image, color: AppColors.primaryGreen),
              ),
              title: const Text(
                'Choose from Gallery',
                style: TextStyle(color: Colors.white),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
  
  // Save user data and complete profile setup
  void _saveUserData() async {
    // Validate form
    if (!_formKey.currentState!.validate()) return;
    
    final authState = ref.read(authProvider);
    final authNotifier = ref.read(authProvider.notifier);
    
    if (authState.uid == null) {
      showSnackBar(context, 'Authentication error. Please try again.');
      return;
    }
    
    // Create user model
    final userModel = UserModel(
      uid: authState.uid!,
      name: _nameController.text.trim(),
      phoneNumber: authState.phoneNumber ?? '',
      image: '',  // Will be updated after storage upload
      token: '',  // Will be set later
      aboutMe: _aboutMeController.text.trim(),
      createdAt: '',  // Will be set in the provider
      contactsUIDs: [],
      blockedUIDs: [],
    );
    
    // Save to Firestore
    authNotifier.saveUserDataToFireStore(
      userModel: userModel,
      profileImage: _profileImage,
      onSuccess: () {
        // Navigate to home screen
        Navigator.of(context).pushNamedAndRemoveUntil(
          Constants.homeScreen,
          (route) => false,
        );
      },
      onFail: (error) {
        showSnackBar(context, 'Failed to save profile: $error');
      },
    );
  }
  
  // Confirm before closing the screen
  Future<bool> _onWillPop() async {
    if (_nameController.text.isNotEmpty || _profileImage != null) {
      return await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Discard changes?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'You have unsaved changes. Are you sure you want to go back?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.primaryGreen),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Discard',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ) ?? false;
    }
    return true;
  }
  
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () async {
              if (await _onWillPop()) Navigator.of(context).pop();
            },
          ),
          centerTitle: true,
          title: const Text(
            'Set Up Your Profile',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Stack(
            children: [
              SafeArea(
                child: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 20,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Profile image selector
                          GestureDetector(
                            onTap: _showImageSourceBottomSheet,
                            child: Stack(
                              children: [
                                Container(
                                  width: 130,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.surfaceVariant,
                                    border: Border.all(
                                      color: AppColors.primaryGreen.withOpacity(0.4),
                                      width: 3,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: _profileImage != null
                                        ? Image.file(
                                            _profileImage!,
                                            fit: BoxFit.cover,
                                            width: 130,
                                            height: 130,
                                          )
                                        : Icon(
                                            Icons.person,
                                            size: 60,
                                            color: Colors.white.withOpacity(0.5),
                                          ),
                                  ),
                                ),
                                
                                // Camera icon overlay
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGreen,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.background,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
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
                          
                          // Helper text
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0, bottom: 36.0),
                            child: Text(
                              'Add a profile photo to personalize your account',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.7),
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
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter your name',
                              labelText: 'Your Name',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: AppColors.error),
                              ),
                              filled: true,
                              fillColor: AppColors.surfaceVariant,
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
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Tell us about yourself',
                              labelText: 'About Me',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                              prefixIcon: Icon(
                                Icons.description_outlined,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
                              ),
                              filled: true,
                              fillColor: AppColors.surfaceVariant,
                              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Get started button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: authState.isLoading ? null : _saveUserData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: AppColors.primaryGreen.withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: authState.isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Get Started',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Loading overlay when processing image
              if (_isImageProcessing)
                Container(
                  color: Colors.black.withOpacity(0.7),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}