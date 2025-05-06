import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weibao/models/user_model.dart';
import 'package:weibao/shared/utils/global_methods.dart';
import 'package:weibao/constants.dart';

// Provider for the AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    storage: FirebaseStorage.instance,
  );
});

// Abstract class for Repository
abstract class BaseAuthRepository {
  Future<bool> checkAuthState();
  Future<bool> checkUserExists(String uid);
  Future<UserModel?> getUserData(String uid);
  Future<void> saveUserData(UserModel user, {File? profileImage});
  Future<void> signInWithPhone(String phoneNumber, void Function(String) onError, void Function(String, String) onCodeSent);
  Future<UserCredential> verifyOTP(String verificationId, String otp);
  Future<void> logout();
  Stream<DocumentSnapshot> userStream(String uid);
  Stream<QuerySnapshot> getAllUsers(String exceptUid);
  Future<void> addContact(String uid, String contactId);
  Future<void> removeContact(String uid, String contactId);
  Future<void> blockContact(String uid, String contactId);
  Future<void> unblockContact(String uid, String contactId);
  Future<List<UserModel>> getContactsList(String uid, List<String> excludeIds);
  Future<List<UserModel>> getBlockedContactsList(String uid);
  Future<UserModel?> searchUserByPhoneNumber(String phoneNumber);
  Future<void> updateUserProfile(UserModel user);
}

class AuthRepository implements BaseAuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  
  AuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  }) : _auth = auth,
       _firestore = firestore,
       _storage = storage;

  @override
  Future<bool> checkAuthState() async {
    // Wait for a moment to initialize Firebase
    await Future.delayed(const Duration(seconds: 1));
    
    // Check if user is logged in
    if (_auth.currentUser != null) {
      debugPrint("User is already logged in: ${_auth.currentUser!.uid}");
      return true;
    }
    
    // Check if cached user exists
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(Constants.userModel);
      
      if (userJson != null && userJson.isNotEmpty) {
        final userData = jsonDecode(userJson);
        final user = UserModel.fromMap(userData);
        
        // If we have cached user data but auth is null, try restoring session
        if (user.uid.isNotEmpty) {
          debugPrint("Found cached user: ${user.uid}");
          return true;
        }
      }
    } catch (e) {
      debugPrint('Error checking cached auth state: $e');
    }
    
    debugPrint("No authenticated user found");
    return false;
  }

  @override
  Future<bool> checkUserExists(String uid) async {
    try {
      debugPrint("Checking if user exists: $uid");
      final doc = await _firestore.collection(Constants.users).doc(uid).get();
      return doc.exists;
    } catch (e) {
      debugPrint("Error checking if user exists: $e");
      return false;
    }
  }

  @override
  Future<UserModel?> getUserData(String uid) async {
    try {
      debugPrint("Getting user data for: $uid");
      final doc = await _firestore.collection(Constants.users).doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      debugPrint("No user found with ID: $uid");
      return null;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  @override
  Future<void> saveUserData(UserModel user, {File? profileImage}) async {
    try {
      debugPrint("Saving user data for: ${user.uid}");
      if (profileImage != null) {
        // Upload image to storage
        debugPrint("Uploading profile image");
        final imageUrl = await storeFileToStorage(
          file: profileImage,
          reference: '${Constants.userImages}/${user.uid}',
        );
        user = user.copyWith(image: imageUrl);
      }

      // Set creation timestamp only
      user = user.copyWith(
        createdAt: DateTime.now().millisecondsSinceEpoch.toString(),
      );

      // Save to Firestore
      debugPrint("Saving user to Firestore");
      await _firestore.collection(Constants.users).doc(user.uid).set(user.toMap());
      
      // Cache user data
      await _saveUserToPrefs(user);
      debugPrint("User data saved successfully");
    } catch (e) {
      debugPrint('Error saving user data: $e');
      throw Exception('Failed to save user data: $e');
    }
  }

  Future<void> _saveUserToPrefs(UserModel user) async {
    try {
      debugPrint("Saving user to SharedPreferences");
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(Constants.userModel, jsonEncode(user.toMap()));
    } catch (e) {
      debugPrint('Error saving user to prefs: $e');
    }
  }

  @override
  Future<void> signInWithPhone(
    String phoneNumber, 
    void Function(String) onError, 
    void Function(String, String) onCodeSent
  ) async {
    try {
      debugPrint("Starting phone verification for: $phoneNumber");
      
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed (Android only)
          debugPrint("Auto verification completed");
          try {
            await _auth.signInWithCredential(credential);
          } catch (e) {
            debugPrint("Error in auto verification: $e");
            onError(e.toString());
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint("Verification failed: ${e.message}");
          onError(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint("Code sent successfully to $phoneNumber, verification ID: $verificationId");
          onCodeSent(verificationId, phoneNumber);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint("Code auto retrieval timeout");
        },
      );
    } catch (e) {
      debugPrint("Exception in signInWithPhone: $e");
      onError(e.toString());
    }
  }

  @override
  Future<UserCredential> verifyOTP(String verificationId, String otp) async {
    try {
      debugPrint("Verifying OTP for verification ID: $verificationId");
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      throw Exception('Failed to verify OTP: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      debugPrint("Logging out user");
      await _auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint("User logged out successfully");
    } catch (e) {
      debugPrint('Error logging out: $e');
      throw Exception('Failed to logout: $e');
    }
  }

  @override
  Stream<DocumentSnapshot> userStream(String uid) {
    debugPrint("Getting user stream for: $uid");
    return _firestore.collection(Constants.users).doc(uid).snapshots();
  }

  @override
  Stream<QuerySnapshot> getAllUsers(String exceptUid) {
    debugPrint("Getting all users except: $exceptUid");
    return _firestore
        .collection(Constants.users)
        .where(Constants.uid, isNotEqualTo: exceptUid)
        .snapshots();
  }

  @override
  Future<void> addContact(String uid, String contactId) async {
    try {
      debugPrint("Adding contact $contactId for user: $uid");
      await _firestore.collection(Constants.users).doc(uid).update({
        Constants.contactsUIDs: FieldValue.arrayUnion([contactId]),
      });
    } catch (e) {
      debugPrint('Error adding contact: $e');
      throw Exception('Failed to add contact: $e');
    }
  }

  @override
  Future<void> removeContact(String uid, String contactId) async {
    try {
      debugPrint("Removing contact $contactId for user: $uid");
      await _firestore.collection(Constants.users).doc(uid).update({
        Constants.contactsUIDs: FieldValue.arrayRemove([contactId]),
      });
    } catch (e) {
      debugPrint('Error removing contact: $e');
      throw Exception('Failed to remove contact: $e');
    }
  }

  @override
  Future<void> blockContact(String uid, String contactId) async {
    try {
      debugPrint("Blocking contact $contactId for user: $uid");
      await _firestore.collection(Constants.users).doc(uid).update({
        Constants.blockedUIDs: FieldValue.arrayUnion([contactId]),
      });
    } catch (e) {
      debugPrint('Error blocking contact: $e');
      throw Exception('Failed to block contact: $e');
    }
  }

  @override
  Future<void> unblockContact(String uid, String contactId) async {
    try {
      debugPrint("Unblocking contact $contactId for user: $uid");
      await _firestore.collection(Constants.users).doc(uid).update({
        Constants.blockedUIDs: FieldValue.arrayRemove([contactId]),
      });
    } catch (e) {
      debugPrint('Error unblocking contact: $e');
      throw Exception('Failed to unblock contact: $e');
    }
  }

  @override
  Future<List<UserModel>> getContactsList(String uid, List<String> excludeIds) async {
    try {
      debugPrint("Getting contacts list for user: $uid");
      final doc = await _firestore.collection(Constants.users).doc(uid).get();
      final List<dynamic> contactsUIDs = doc.get(Constants.contactsUIDs);
      
      List<UserModel> contacts = [];
      for (String contactUid in contactsUIDs) {
        if (excludeIds.contains(contactUid)) continue;
        
        final contactDoc = await _firestore.collection(Constants.users).doc(contactUid).get();
        if (contactDoc.exists) {
          contacts.add(UserModel.fromMap(contactDoc.data() as Map<String, dynamic>));
        }
      }
      
      return contacts;
    } catch (e) {
      debugPrint('Error getting contacts list: $e');
      return [];
    }
  }

  @override
  Future<List<UserModel>> getBlockedContactsList(String uid) async {
    try {
      debugPrint("Getting blocked contacts for user: $uid");
      final doc = await _firestore.collection(Constants.users).doc(uid).get();
      final List<dynamic> blockedUIDs = doc.get(Constants.blockedUIDs);
      
      List<UserModel> blockedContacts = [];
      for (String blockedUid in blockedUIDs) {
        final contactDoc = await _firestore.collection(Constants.users).doc(blockedUid).get();
        if (contactDoc.exists) {
          blockedContacts.add(UserModel.fromMap(contactDoc.data() as Map<String, dynamic>));
        }
      }
      
      return blockedContacts;
    } catch (e) {
      debugPrint('Error getting blocked contacts list: $e');
      return [];
    }
  }

  @override
  Future<UserModel?> searchUserByPhoneNumber(String phoneNumber) async {
    try {
      debugPrint("Searching for user with phone number: $phoneNumber");
      final query = await _firestore
          .collection(Constants.users)
          .where(Constants.phoneNumber, isEqualTo: phoneNumber)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        return UserModel.fromMap(query.docs.first.data());
      }
      
      debugPrint("No user found with phone number: $phoneNumber");
      return null;
    } catch (e) {
      debugPrint('Error searching user by phone number: $e');
      return null;
    }
  }

  @override
  Future<void> updateUserProfile(UserModel user) async {
    try {
      debugPrint("Updating user profile for: ${user.uid}");
      await _firestore
          .collection(Constants.users)
          .doc(user.uid)
          .update(user.toMap());
      
      // Update cached user data
      await _saveUserToPrefs(user);
      debugPrint("User profile updated successfully");
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      throw Exception('Failed to update user profile: $e');
    }
  }
}