import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:weibao/config/theme.dart';
import 'package:weibao/services/auth_service.dart';
import 'package:weibao/screens/home/home_screen.dart';

final usernameAvailableProvider = FutureProvider.family<bool, String>((ref, username) async {
  if (username.length < 3) return false;
  final authService = ref.watch(authServiceProvider);
  return !(await authService.isUsernameTaken(username));
});

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  File? _imageFile;
  bool _isUploading = false;
  String _errorMessage = '';
  
  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );
    
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }
  
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isUploading = true;
      _errorMessage = '';
    });
    
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw 'User not logged in';
      }
      
      String? photoURL;
      
      // Upload profile image if selected
      if (_imageFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${user.uid}.jpg');
            
        final uploadTask = storageRef.putFile(_imageFile!);
        final TaskSnapshot taskSnapshot = await uploadTask;
        photoURL = await taskSnapshot.ref.getDownloadURL();
      }
      
      // Update user profile
      final authService = ref.read(authServiceProvider);
      await authService.updateUserProfile(
        uid: user.uid,
        username: _usernameController.text,
        photoURL: photoURL,
        bio: _bioController.text.isEmpty ? null : _bioController.text,
      );
      
      // Navigate to home screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isUploading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final usernameAsync = ref.watch(
      usernameAvailableProvider(_usernameController.text.trim())
    );
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Profile'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Create your profile',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Customize your profile to get started',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // Profile image
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : null,
                            child: _imageFile == null
                                ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
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
                  const SizedBox(height: 32),
                  
                  // Username field
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      hintText: 'Choose a unique username',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.alternate_email),
                      suffixIcon: usernameAsync.when(
                        data: (isAvailable) => isAvailable && _usernameController.text.trim().length >= 3
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : _usernameController.text.trim().length >= 3
                                ? const Icon(Icons.cancel, color: Colors.red)
                                : null,
                        loading: () => const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        error: (_, __) => const Icon(Icons.error, color: Colors.orange),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Username is required';
                      }
                      if (value.trim().length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      if (value.trim().length > 30) {
                        return 'Username must be less than 30 characters';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(value)) {
                        return 'Username can only contain letters, numbers, periods, and underscores';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  
                  // Bio field
                  TextFormField(
                    controller: _bioController,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      hintText: 'Tell us about yourself (optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.info_outline),
                    ),
                    maxLines: 3,
                    maxLength: 150,
                  ),
                  
                  // Error message
                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // Save button
                  ElevatedButton(
                    onPressed: _isUploading
                        ? null
                        : usernameAsync.maybeWhen(
                            data: (isAvailable) => isAvailable ? _saveProfile : null,
                            orElse: () => null,
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isUploading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          )
                        : const Text(
                            'Save Profile',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Skip button
                  TextButton(
                    onPressed: _isUploading
                        ? null
                        : () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const HomeScreen(),
                              ),
                            );
                          },
                    child: const Text('Skip for now'),
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