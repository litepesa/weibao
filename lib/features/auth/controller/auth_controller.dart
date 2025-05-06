import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weibao/features/auth/repository/auth_repository.dart';
import 'package:weibao/features/auth/state/auth_state.dart';
import 'package:weibao/models/user_model.dart';

// Provider for the AuthController
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthController(repository: repository);
});

// Provider for current user data
final userDataProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authControllerProvider);
  
  if (authState.uid != null) {
    final repository = ref.watch(authRepositoryProvider);
    return repository.getUserData(authState.uid!);
  }
  
  return null;
});

// Provider to get a specific user's data by ID
final userProvider = FutureProvider.family<UserModel?, String>((ref, uid) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.getUserData(uid);
});

// Provider to stream a specific user's data
final userStreamProvider = StreamProvider.family<DocumentSnapshot, String>((ref, uid) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.userStream(uid);
});

// Provider for all users
final allUsersProvider = StreamProvider.family<QuerySnapshot, String>((ref, exceptUid) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.getAllUsers(exceptUid);
});

// Provider for user's contacts
final contactsProvider = FutureProvider.family<List<UserModel>, String>((ref, uid) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.getContactsList(uid, []); // Empty list for no exclusions
});

// Provider for user's blocked contacts
final blockedContactsProvider = FutureProvider.family<List<UserModel>, String>((ref, uid) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.getBlockedContactsList(uid);
});

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  
  AuthController({required AuthRepository repository})
      : _repository = repository,
        super(AuthState.initial());
  
  // Check if the user is authenticated
  Future<bool> checkAuth() async {
    state = state.copyWith(isLoading: true);
    
    try {
      debugPrint("Checking authentication state");
      final isAuthenticated = await _repository.checkAuthState();
      
      if (isAuthenticated) {
        debugPrint("User is authenticated");
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          debugPrint("Current user: ${user.uid}");
          final userData = await _repository.getUserData(user.uid);
          
          state = state.copyWith(
            isLoading: false,
            isAuthenticated: true,
            uid: user.uid,
            phoneNumber: user.phoneNumber,
            userModel: userData,
          );
        } else {
          debugPrint("Firebase user is null despite authenticated state");
          state = state.copyWith(
            isLoading: false,
            isAuthenticated: false,
          );
        }
      } else {
        debugPrint("User is not authenticated");
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: false,
        );
      }
      
      return isAuthenticated;
    } catch (e) {
      debugPrint("Error checking authentication: $e");
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: e.toString(),
      );
      return false;
    }
  }
  
  // Sign in with phone number
  Future<void> signInWithPhone({
    required String phoneNumber,
    required void Function(String) onError,
    required void Function(String, String) onCodeSent,
  }) async {
    state = state.copyWith(isLoading: true);
    
    try {
      debugPrint("Initiating phone sign-in for: $phoneNumber");
      await _repository.signInWithPhone(
        phoneNumber,
        (error) {
          debugPrint("Phone sign-in error: $error");
          state = state.copyWith(
            isLoading: false,
            error: error,
          );
          onError(error);
        },
        (verificationId, phone) {
          debugPrint("Code sent successfully to: $phone");
          state = state.copyWith(
            isLoading: false,
            phoneNumber: phone,
          );
          onCodeSent(verificationId, phone);
        },
      );
    } catch (e) {
      debugPrint("Exception in signInWithPhone: $e");
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      onError(e.toString());
    }
  }
  
  // Verify OTP
  Future<void> verifyOTP({
    required String verificationId,
    required String otp,
    required Function(bool) onComplete,
  }) async {
    state = state.copyWith(isLoading: true);
    
    try {
      debugPrint("Verifying OTP for verificationId: $verificationId");
      final credential = await _repository.verifyOTP(verificationId, otp);
      final user = credential.user;
      
      if (user != null) {
        debugPrint("OTP verification successful for user: ${user.uid}");
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          uid: user.uid,
          phoneNumber: user.phoneNumber,
        );
        
        // Check if user exists in database
        final userExists = await _repository.checkUserExists(user.uid);
        debugPrint("User exists in database: $userExists");
        
        if (userExists) {
          final userData = await _repository.getUserData(user.uid);
          state = state.copyWith(userModel: userData);
        }
        
        onComplete(userExists);
      } else {
        debugPrint("Verification failed: user is null");
        state = state.copyWith(
          isLoading: false,
          error: 'Verification failed',
        );
        onComplete(false);
      }
    } catch (e) {
      debugPrint("Error verifying OTP: $e");
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      onComplete(false);
    }
  }
  
  // Save user data (for new users)
  Future<void> saveUserData({
    required String name,
    required String aboutMe,
    required File? profileImage,
    required Function() onSuccess,
    required Function(String) onError,
  }) async {
    state = state.copyWith(isLoading: true);
    
    try {
      debugPrint("Saving user data");
      if (state.uid == null || state.phoneNumber == null) {
        debugPrint("Cannot save user data: User not authenticated");
        throw Exception('User not authenticated');
      }
      
      // Create new user model
      final userModel = UserModel(
        uid: state.uid!,
        name: name,
        phoneNumber: state.phoneNumber!,
        image: '',
        token: '',
        aboutMe: aboutMe,
        createdAt: DateTime.now().millisecondsSinceEpoch.toString(),
        contactsUIDs: [],
        blockedUIDs: [],
      );
      
      debugPrint("Created user model, saving to database");
      // Save to database
      await _repository.saveUserData(userModel, profileImage: profileImage);
      
      // Update state
      state = state.copyWith(
        isLoading: false,
        userModel: userModel,
      );
      
      debugPrint("User data saved successfully");
      onSuccess();
    } catch (e) {
      debugPrint("Error saving user data: $e");
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      onError(e.toString());
    }
  }
  
  // Update user profile
  Future<void> updateUserProfile({
    required UserModel updatedUser,
    required Function() onSuccess,
    required Function(String) onError,
  }) async {
    state = state.copyWith(isLoading: true);
    
    try {
      debugPrint("Updating user profile for: ${updatedUser.uid}");
      await _repository.updateUserProfile(updatedUser);
      
      state = state.copyWith(
        isLoading: false,
        userModel: updatedUser,
      );
      
      debugPrint("User profile updated successfully");
      onSuccess();
    } catch (e) {
      debugPrint("Error updating user profile: $e");
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      onError(e.toString());
    }
  }
  
  // Contact management functions
  Future<void> addContact(String contactId) async {
    try {
      if (state.uid == null) {
        debugPrint("Cannot add contact: User not authenticated");
        return;
      }
      
      debugPrint("Adding contact $contactId for user ${state.uid}");
      await _repository.addContact(state.uid!, contactId);
      
      // Update state if userModel exists
      if (state.userModel != null) {
        final updatedContacts = [...state.userModel!.contactsUIDs, contactId];
        state = state.copyWith(
          userModel: state.userModel!.copyWith(contactsUIDs: updatedContacts),
        );
        debugPrint("Contact added successfully");
      }
    } catch (e) {
      debugPrint('Error adding contact: $e');
    }
  }
  
  Future<void> removeContact(String contactId) async {
    try {
      if (state.uid == null) {
        debugPrint("Cannot remove contact: User not authenticated");
        return;
      }
      
      debugPrint("Removing contact $contactId for user ${state.uid}");
      await _repository.removeContact(state.uid!, contactId);
      
      // Update state if userModel exists
      if (state.userModel != null) {
        final updatedContacts = state.userModel!.contactsUIDs
            .where((id) => id != contactId)
            .toList();
        state = state.copyWith(
          userModel: state.userModel!.copyWith(contactsUIDs: updatedContacts),
        );
        debugPrint("Contact removed successfully");
      }
    } catch (e) {
      debugPrint('Error removing contact: $e');
    }
  }
  
  Future<void> blockContact(String contactId) async {
    try {
      if (state.uid == null) {
        debugPrint("Cannot block contact: User not authenticated");
        return;
      }
      
      debugPrint("Blocking contact $contactId for user ${state.uid}");
      await _repository.blockContact(state.uid!, contactId);
      
      // Update state if userModel exists
      if (state.userModel != null) {
        final updatedBlocked = [...state.userModel!.blockedUIDs, contactId];
        state = state.copyWith(
          userModel: state.userModel!.copyWith(blockedUIDs: updatedBlocked),
        );
        debugPrint("Contact blocked successfully");
      }
    } catch (e) {
      debugPrint('Error blocking contact: $e');
    }
  }
  
  Future<void> unblockContact(String contactId) async {
    try {
      if (state.uid == null) {
        debugPrint("Cannot unblock contact: User not authenticated");
        return;
      }
      
      debugPrint("Unblocking contact $contactId for user ${state.uid}");
      await _repository.unblockContact(state.uid!, contactId);
      
      // Update state if userModel exists
      if (state.userModel != null) {
        final updatedBlocked = state.userModel!.blockedUIDs
            .where((id) => id != contactId)
            .toList();
        state = state.copyWith(
          userModel: state.userModel!.copyWith(blockedUIDs: updatedBlocked),
        );
        debugPrint("Contact unblocked successfully");
      }
    } catch (e) {
      debugPrint('Error unblocking contact: $e');
    }
  }
  
  // Search for a user by phone number
  Future<UserModel?> searchUserByPhone(String phoneNumber) async {
    try {
      debugPrint("Searching for user with phone number: $phoneNumber");
      return await _repository.searchUserByPhoneNumber(phoneNumber);
    } catch (e) {
      debugPrint('Error searching user: $e');
      return null;
    }
  }
  
  // Logout
  Future<void> logout() async {
    try {
      debugPrint("Logging out user");
      await _repository.logout();
      state = AuthState.initial();
      debugPrint("Logout successful");
    } catch (e) {
      debugPrint('Error logging out: $e');
    }
  }
}