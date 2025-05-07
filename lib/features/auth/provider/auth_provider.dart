import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weibao/constants.dart';
import 'package:weibao/models/user_model.dart';
import 'package:weibao/shared/utils/global_methods.dart';

// Auth state class to hold authentication related states
class AuthState {
  final bool isLoading;
  final bool isSuccessful;
  final String? uid;
  final String? phoneNumber;
  final UserModel? userModel;

  AuthState({
    this.isLoading = false,
    this.isSuccessful = false,
    this.uid,
    this.phoneNumber,
    this.userModel,
  });

  // Copy with method for immutability
  AuthState copyWith({
    bool? isLoading,
    bool? isSuccessful,
    String? uid,
    String? phoneNumber,
    UserModel? userModel,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isSuccessful: isSuccessful ?? this.isSuccessful,
      uid: uid ?? this.uid,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userModel: userModel ?? this.userModel,
    );
  }
}

// Auth provider class to handle authentication logic
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState());

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Check authentication state
  Future<bool> checkAuthenticationState() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Add a small delay to show splash screen if needed
      await Future.delayed(const Duration(seconds: 1));

      if (_auth.currentUser != null) {
        state = state.copyWith(uid: _auth.currentUser!.uid);
        
        // Check if user exists in Firestore
        bool userExists = await checkUserExists();
        if (!userExists) {
          // User doesn't exist in Firestore even though they're authenticated in Firebase Auth
          await _auth.signOut(); // Sign out the user since they don't have a profile
          state = state.copyWith(isLoading: false, isSuccessful: false);
          return false;
        }
        
        // Get user data from firestore
        await getUserDataFromFireStore();
        
        // Verify we have user data
        if (state.userModel == null) {
          debugPrint('User exists in Firestore but could not fetch user data');
          state = state.copyWith(isLoading: false, isSuccessful: false);
          return false;
        }
        
        // Save user data to shared preferences
        await saveUserDataToSharedPreferences();

        state = state.copyWith(isLoading: false, isSuccessful: true);
        return true;
      } else {
        state = state.copyWith(isLoading: false, isSuccessful: false);
        return false;
      }
    } catch (e) {
      debugPrint('Error checking auth state: $e');
      state = state.copyWith(isLoading: false, isSuccessful: false);
      return false;
    }
  }

  // Check if user exists in Firestore
  Future<bool> checkUserExists() async {
    try {
      DocumentSnapshot documentSnapshot =
          await _firestore.collection(Constants.users).doc(state.uid).get();
      return documentSnapshot.exists;
    } catch (e) {
      debugPrint('Error checking if user exists: $e');
      return false;
    }
  }

  // Get user data from Firestore
  Future<void> getUserDataFromFireStore() async {
    try {
      DocumentSnapshot documentSnapshot =
          await _firestore.collection(Constants.users).doc(state.uid).get();
      
      if (documentSnapshot.exists) {
        final userData = UserModel.fromMap(documentSnapshot.data() as Map<String, dynamic>);
        state = state.copyWith(userModel: userData);
        debugPrint('Successfully fetched user data from Firestore');
      } else {
        debugPrint('User document does not exist in Firestore');
      }
    } catch (e) {
      debugPrint('Error getting user data from Firestore: $e');
    }
  }

  // Save user data to SharedPreferences
  Future<void> saveUserDataToSharedPreferences() async {
    try {
      if (state.userModel != null) {
        SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
        await sharedPreferences.setString(
            Constants.userModel, jsonEncode(state.userModel!.toMap()));
        debugPrint('Successfully saved user data to SharedPreferences');
      } else {
        debugPrint('Cannot save null user data to SharedPreferences');
      }
    } catch (e) {
      debugPrint('Error saving user data to SharedPreferences: $e');
    }
  }

  // Get user data from SharedPreferences
  Future<void> getUserDataFromSharedPreferences() async {
    try {
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      String userModelString = sharedPreferences.getString(Constants.userModel) ?? '';
      
      if (userModelString.isNotEmpty) {
        UserModel userModel = UserModel.fromMap(jsonDecode(userModelString));
        state = state.copyWith(
          userModel: userModel,
          uid: userModel.uid,
        );
        debugPrint('Successfully retrieved user data from SharedPreferences');
      } else {
        debugPrint('No user data found in SharedPreferences');
      }
    } catch (e) {
      debugPrint('Error getting user data from SharedPreferences: $e');
    }
  }

  // Sign in with phone number
  Future<void> signInWithPhoneNumber({
    required String phoneNumber,
    required BuildContext context,
    required Function(String) onCodeSent,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential).then((value) async {
            state = state.copyWith(
              uid: value.user!.uid,
              phoneNumber: value.user!.phoneNumber,
              isSuccessful: true,
              isLoading: false,
            );
          });
        },
        verificationFailed: (FirebaseAuthException e) {
          state = state.copyWith(isSuccessful: false, isLoading: false);
          showSnackBar(context, e.toString());
        },
        codeSent: (String verificationId, int? resendToken) async {
          state = state.copyWith(isLoading: false);
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      showSnackBar(context, 'Error: $e');
    }
  }

  // Verify OTP code
  Future<void> verifyOTPCode({
    required String verificationId,
    required String otpCode,
    required BuildContext context,
    required Function onSuccess,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      state = state.copyWith(
        uid: userCredential.user!.uid,
        phoneNumber: userCredential.user!.phoneNumber,
        isSuccessful: true,
        isLoading: false,
      );
      onSuccess();
    } catch (e) {
      state = state.copyWith(isSuccessful: false, isLoading: false);
      showSnackBar(context, 'Verification failed: $e');
    }
  }

  // Save user data to Firestore
  Future<void> saveUserDataToFireStore({
    required UserModel userModel,
    required File? profileImage,
    required Function onSuccess,
    required Function(String) onFail,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      String imageUrl = '';
      if (profileImage != null) {
        // Upload image to storage
        imageUrl = await storeFileToStorage(
          file: profileImage,
          reference: '${Constants.userImages}/${userModel.uid}',
        );
      }

      // Update model with image URL and timestamps
      final updatedUser = userModel.copyWith(
        image: imageUrl,
        createdAt: DateTime.now().millisecondsSinceEpoch.toString(),
      );

      // Save to Firestore
      await _firestore
          .collection(Constants.users)
          .doc(updatedUser.uid)
          .set(updatedUser.toMap());

      // Update state
      state = state.copyWith(
        userModel: updatedUser,
        uid: updatedUser.uid,
        isLoading: false,
      );

      // Save to SharedPreferences
      await saveUserDataToSharedPreferences();
      
      onSuccess();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      onFail(e.toString());
    }
  }

  // Update user status (online/offline)
  Future<void> updateUserStatus({required bool isOnline}) async {
    try {
      if (_auth.currentUser != null) {
        await _firestore
          .collection(Constants.users)
          .doc(_auth.currentUser!.uid)
          .update({'isOnline': isOnline});
      }
    } catch (e) {
      debugPrint('Error updating user status: $e');
    }
  }

  // Get user stream
  Stream<DocumentSnapshot> userStream({required String userID}) {
    return _firestore.collection(Constants.users).doc(userID).snapshots();
  }

  // Add contact to user's contacts
  Future<void> addContact({required String contactID}) async {
    try {
      // Add contact to user's contacts list in Firestore
      await _firestore.collection(Constants.users).doc(state.uid).update({
        Constants.contactsUIDs: FieldValue.arrayUnion([contactID]),
      });
      
      // Update local user model
      final updatedContacts = [...state.userModel!.contactsUIDs, contactID];
      state = state.copyWith(
        userModel: state.userModel!.copyWith(contactsUIDs: updatedContacts),
      );
      
      // Update SharedPreferences
      await saveUserDataToSharedPreferences();
    } catch (e) {
      debugPrint('Error adding contact: $e');
    }
  }

  // Block a contact
  Future<void> blockContact({required String contactID}) async {
    try {
      // Add contact to blocked list in Firestore
      await _firestore.collection(Constants.users).doc(state.uid).update({
        Constants.blockedUIDs: FieldValue.arrayUnion([contactID]),
      });
      
      // Update local user model
      final updatedBlocked = [...state.userModel!.blockedUIDs, contactID];
      state = state.copyWith(
        userModel: state.userModel!.copyWith(blockedUIDs: updatedBlocked),
      );
      
      // Update SharedPreferences
      await saveUserDataToSharedPreferences();
    } catch (e) {
      debugPrint('Error blocking contact: $e');
    }
  }

  // Unblock a contact
  Future<void> unblockContact({required String contactID}) async {
    try {
      // Remove contact from blocked list in Firestore
      await _firestore.collection(Constants.users).doc(state.uid).update({
        Constants.blockedUIDs: FieldValue.arrayRemove([contactID]),
      });
      
      // Update local user model
      final updatedBlocked = state.userModel!.blockedUIDs
          .where((uid) => uid != contactID)
          .toList();
      
      state = state.copyWith(
        userModel: state.userModel!.copyWith(blockedUIDs: updatedBlocked),
      );
      
      // Update SharedPreferences
      await saveUserDataToSharedPreferences();
    } catch (e) {
      debugPrint('Error unblocking contact: $e');
    }
  }

  // Search for users by phone number
  Future<UserModel?> searchUserByPhoneNumber({
    required String phoneNumber,
  }) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(Constants.users)
          .where(Constants.phoneNumber, isEqualTo: phoneNumber)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return null;
      }
      
      return UserModel.fromMap(
          querySnapshot.docs.first.data() as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error searching user: $e');
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await updateUserStatus(isOnline: false);
      await _auth.signOut();
      
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.clear();
      
      state = AuthState(); // Reset state
    } catch (e) {
      debugPrint('Error during logout: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required UserModel updatedUser,
    required File? newProfileImage,
    required Function onSuccess,
    required Function(String) onFail,
  }) async {
    state = state.copyWith(isLoading: true);
    
    try {
      String imageUrl = updatedUser.image;
      
      // If there's a new profile image, upload it
      if (newProfileImage != null) {
        imageUrl = await storeFileToStorage(
          file: newProfileImage,
          reference: '${Constants.userImages}/${updatedUser.uid}',
        );
      }
      
      // Update user with new image
      final userToUpdate = updatedUser.copyWith(image: imageUrl);
      
      // Update in Firestore
      await _firestore
          .collection(Constants.users)
          .doc(userToUpdate.uid)
          .update(userToUpdate.toMap());
      
      // Update state
      state = state.copyWith(
        userModel: userToUpdate,
        isLoading: false,
      );
      
      // Update SharedPreferences
      await saveUserDataToSharedPreferences();
      
      onSuccess();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      onFail(e.toString());
    }
  }

  // Setup persistent auth state listener
void setupAuthStateListener() {
  _auth.authStateChanges().listen((User? user) async {
    if (user == null) {
      // User is not authenticated
      state = AuthState();
      debugPrint('Auth state listener: User is not authenticated');
    } else {
      // User is authenticated, get UID
      state = state.copyWith(uid: user.uid, phoneNumber: user.phoneNumber);
      debugPrint('Auth state listener: User is authenticated with UID: ${user.uid}');
      
      // Check if user exists in Firestore
      bool userExists = await checkUserExists();
      if (userExists) {
        // Get user data from Firestore and save to SharedPreferences
        await getUserDataFromFireStore();
        if (state.userModel != null) {
          await saveUserDataToSharedPreferences();
          state = state.copyWith(isSuccessful: true);
        }
      }
    }
  });
}
}

// Create the provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});