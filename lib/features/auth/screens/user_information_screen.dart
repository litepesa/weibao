import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _nameController = TextEditingController();
  final _aboutMeController = TextEditingController(text: "Hey there, I'm using WeiBao");
  final _formKey = GlobalKey<FormState>();
  
  File? _profileImage;
  bool _isImageProcessing = false;
  bool _isSavingData = false;

  @override
  void initState() {
    super.initState();
    _setupSystemUI();
  }

  void _setupSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutMeController.dispose();
    super.dispose();
  }

  Future<void> _selectImage(bool fromCamera) async {
    try {
      Navigator.pop(context);
      setState(() => _isImageProcessing = true);

      final File? pickedImage = await pickImage(
        fromCamera: fromCamera,
        onFail: (message) {
          if (mounted) showSnackBar(context, message);
        },
      );

      if (pickedImage != null) await _cropImage(pickedImage.path);
    } catch (e) {
      debugPrint("Image selection error: $e");
      if (mounted) showSnackBar(context, 'Error selecting image');
    } finally {
      if (mounted) setState(() => _isImageProcessing = false);
    }
  }

  Future<void> _cropImage(String? filePath) async {
    if (filePath == null) return;
    
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: filePath,
        maxHeight: 500,
        maxWidth: 500,
        compressQuality: 80,
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
            showCropGrid: false,
          ),
          IOSUiSettings(
            minimumAspectRatio: 1.0,
            aspectRatioLockEnabled: true,
            title: 'Crop Image',
          ),
        ],
      );

      if (croppedFile != null && mounted) {
        setState(() => _profileImage = File(croppedFile.path));
      } else if (mounted) {
        showSnackBar(context, 'Image cropping cancelled');
      }
    } catch (e) {
      debugPrint("Image cropping error: $e");
      if (mounted) showSnackBar(context, 'Error cropping image');
    }
  }

  void _showImageOptionsBottomSheet() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ), // Added closing bracket here
    backgroundColor: Colors.white,
    builder: (context) => _ImageOptionsBottomSheet(
      onCameraTap: () => _selectImage(true),
      onGalleryTap: () => _selectImage(false),
    ),
  );
  }

  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) return;
    
    FocusScope.of(context).unfocus();
    setState(() => _isSavingData = true);
    
    try {
      await ref.read(authControllerProvider.notifier).saveUserData(
        name: _nameController.text.trim(),
        aboutMe: _aboutMeController.text.trim(), 
        profileImage: _profileImage,
        onSuccess: () {
          if (mounted) AppRouter.navigateAndRemoveUntil(context, Constants.homeScreen);
        },
        onError: (error) {
          if (mounted) {
            setState(() => _isSavingData = false);
            showSnackBar(context, error);
          }
        },
      );
    } catch (e) {
      debugPrint("Error saving user data: $e");
      if (mounted) {
        setState(() => _isSavingData = false);
        showSnackBar(context, 'Error saving user data');
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_nameController.text.isEmpty && _profileImage == null) return true;
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
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
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (await _onWillPop() && mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
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
            child: SingleChildScrollView(
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
                    _buildProfileImageSelector(),
                    _buildProfileImageHelperText(),
                    _buildNameField(),
                    const SizedBox(height: 24),
                    _buildAboutMeField(),
                    const SizedBox(height: 30),
                    _buildPrivacySection(),
                    const SizedBox(height: 40),
                    _buildContinueButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageSelector() {
    return Tooltip(
      message: 'Tap to select image',
      child: GestureDetector(
        onTap: _isImageProcessing ? null : _showImageOptionsBottomSheet,
        child: Center(
          child: Stack(
            children: [
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
                ),
                child: ClipOval(
                  child: _profileImage != null
                      ? Image.file(
                          _profileImage!,
                          fit: BoxFit.cover,
                          width: 130,
                          height: 130,
                          errorBuilder: (_, __, ___) => const Icon(Icons.error),
                        )
                      : Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.grey.shade400,
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF07C160),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              if (_isImageProcessing)
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageHelperText() {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 36.0),
      child: Text(
        'Add a profile photo to personalize your account',
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      enabled: !_isSavingData,
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
        prefixIcon: Icon(Icons.person_outline, color: Colors.grey.shade600),
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
    );
  }

  Widget _buildAboutMeField() {
    return TextFormField(
      controller: _aboutMeController,
      enabled: !_isSavingData,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      maxLines: 3,
      style: GoogleFonts.poppins(fontSize: 16),
      decoration: InputDecoration(
        hintText: 'Tell us about yourself',
        labelText: 'About Me',
        prefixIcon: Icon(Icons.description_outlined, color: Colors.grey.shade600),
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
    );
  }

  Widget _buildPrivacySection() {
    return Container(
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
              const Icon(Icons.shield_outlined, color: Color(0xFF07C160)),
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
          _buildPrivacyFeature(
            icon: Icons.check_circle_outline,
            text: Constants.privacyFeatures,
          ),
          const SizedBox(height: 4),
          _buildPrivacyFeature(
            icon: Icons.lock_outline,
            text: Constants.securityInfo,
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyFeature({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF07C160), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF07C160).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
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
        onPressed: _isSavingData ? null : _saveUserData,
        child: _isSavingData
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
    );
  }
}

class _ImageOptionsBottomSheet extends StatelessWidget {
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;

  const _ImageOptionsBottomSheet({
    required this.onCameraTap,
    required this.onGalleryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
          _buildOptionTile(
            icon: Icons.camera_alt,
            text: 'Take Photo',
            onTap: onCameraTap,
          ),
          const Divider(),
          _buildOptionTile(
            icon: Icons.image,
            text: 'Choose from Gallery',
            onTap: onGalleryTap,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF07C160).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF07C160)),
      ),
      title: Text(text),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    );
  }
}