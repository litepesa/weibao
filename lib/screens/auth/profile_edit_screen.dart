import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:weibao/config/theme.dart';
import 'package:weibao/models/user_model.dart';
import 'package:weibao/services/auth_service.dart';
import 'package:weibao/widgets/common/loading_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Profile edit state
final profileEditStateProvider = StateNotifierProvider.autoDispose<ProfileEditNotifier, ProfileEditState>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw 'User not logged in';
  }
  
  return ProfileEditNotifier(ref as ProviderRef, user.uid);
});

// Username availability check
final usernameAvailableProvider = FutureProvider.family<bool, String>((ref, username) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return false;
  
  // Get current user data to compare with entered username
  final currentUserData = await ref.watch(userDataProvider(currentUser.uid).future);
  
  // If the username is the same as current username, it's available
  if (currentUserData != null && username == currentUserData.username) {
    return true;
  }
  
  // If the username is too short, it's not available
  if (username.length < 3) {
    return false;
  }
  
  // Check if username is taken
  final authService = ref.watch(authServiceProvider);
  return !(await authService.isUsernameTaken(username));
});

// Profile edit state class
class ProfileEditState {
  final bool isLoading;
  final UserModel? userData;
  final String? errorMessage;
  final File? imageFile;
  
  ProfileEditState({
    this.isLoading = false,
    this.userData,
    this.errorMessage,
    this.imageFile,
  });
  
  ProfileEditState copyWith({
    bool? isLoading,
    UserModel? userData,
    String? errorMessage,
    File? imageFile,
  }) {
    return ProfileEditState(
      isLoading: isLoading ?? this.isLoading,
      userData: userData ?? this.userData,
      errorMessage: errorMessage,
      imageFile: imageFile ?? this.imageFile,
    );
  }
}

// Profile edit notifier
class ProfileEditNotifier extends StateNotifier<ProfileEditState> {
  final ProviderRef ref;
  final String userId;
  
  ProfileEditNotifier(this.ref, this.userId) : super(ProfileEditState(isLoading: true)) {
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    try {
      final userData = await ref.read(userDataProvider(userId).future);
      
      if (userData == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'User data not found',
        );
        return;
      }
      
      state = state.copyWith(
        isLoading: false,
        userData: userData,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
  
  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );
    
    if (image != null) {
      state = state.copyWith(imageFile: File(image.path));
    }
  }
  
  Future<bool> saveProfile({
    required String username,
    required String bio,
  }) async {
    if (state.userData == null) return false;
    
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );
    
    try {
      String? photoURL = state.userData!.photoURL;
      
      // Upload new profile image if selected
      if (state.imageFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('$userId.jpg');
            
        final uploadTask = storageRef.putFile(state.imageFile!);
        final TaskSnapshot taskSnapshot = await uploadTask;
        photoURL = await taskSnapshot.ref.getDownloadURL();
      }
      
      // Update user profile
      await ref.read(authServiceProvider).updateUserProfile(
        uid: userId,
        username: username,
        photoURL: photoURL,
        bio: bio.isEmpty ? null : bio,
      );
      
      // Refresh user data cache
      ref.refresh(userDataProvider(userId));
      
      state = state.copyWith(
        isLoading: false,
        errorMessage: null,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    
    // Initialize controllers when user data is loaded
    ref.listenManual(profileEditStateProvider, (previous, next) {
      if (previous?.userData != next.userData && next.userData != null) {
        _usernameController.text = next.userData!.username;
        _bioController.text = next.userData!.bio ?? '';
      }
    });
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
  
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    final result = await ref.read(profileEditStateProvider.notifier).saveProfile(
      username: _usernameController.text,
      bio: _bioController.text,
    );
    
    if (result && mounted) {
      // Show success message and pop
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.of(context).pop();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final profileEditState = ref.watch(profileEditStateProvider);
    final isUsernameAvailableAsync = ref.watch(
      usernameAvailableProvider(_usernameController.text.trim())
    );
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: profileEditState.isLoading ? null : _saveProfile,
            child: const Text(
              'Save',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: profileEditState.isLoading && profileEditState.userData == null
          ? const Center(child: LoadingIndicator(message: 'Loading profile...'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile picture
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          ref.read(profileEditStateProvider.notifier).pickImage();
                        },
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: profileEditState.imageFile != null
                                  ? FileImage(profileEditState.imageFile!)
                                  : profileEditState.userData?.photoURL != null && 
                                    profileEditState.userData!.photoURL!.isNotEmpty
                                      ? CachedNetworkImageProvider(profileEditState.userData!.photoURL!)
                                      : null,
                              child: profileEditState.imageFile == null &&
                                      (profileEditState.userData?.photoURL == null || 
                                       profileEditState.userData!.photoURL!.isEmpty)
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
                        suffixIcon: _usernameController.text.isNotEmpty
                            ? isUsernameAvailableAsync.when(
                                data: (isAvailable) => isAvailable
                                    ? const Icon(Icons.check_circle, color: Colors.green)
                                    : const Icon(Icons.cancel, color: Colors.red),
                                loading: () => const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                error: (_, __) => const Icon(Icons.error, color: Colors.orange),
                              )
                            : null,
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
                        
                        final isAvailable = isUsernameAvailableAsync.valueOrNull;
                        if (isAvailable != null && !isAvailable) {
                          return 'Username is already taken';
                        }
                        
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Bio field
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        hintText: 'Tell others about yourself',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.info_outline),
                      ),
                      maxLines: 3,
                      maxLength: 150,
                    ),
                    
                    // Phone number display (non-editable)
                    if (profileEditState.userData?.phoneNumber != null && 
                        profileEditState.userData!.phoneNumber.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: profileEditState.userData!.phoneNumber,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        readOnly: true,
                        enabled: false,
                      ),
                    ],
                    
                    // Error message
                    if (profileEditState.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        profileEditState.errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    // Delete account section
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Account Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.delete, color: Colors.red),
                      title: const Text('Delete Account'),
                      subtitle: const Text('This action cannot be undone'),
                      onTap: () {
                        // Show confirmation dialog
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Account'),
                            content: const Text(
                              'Are you sure you want to delete your account? This action cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  // TODO: Implement actual account deletion
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Account deletion is not implemented yet'),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: profileEditState.isLoading && profileEditState.userData != null
          ? const SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: LoadingIndicator(message: 'Saving profile...'),
              ),
            )
          : null,
    );
  }
}