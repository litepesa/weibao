import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weibao/models/user_model.dart';

// Providers
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateChangesProvider).asData?.value;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref);
});

final userDataProvider = FutureProvider.autoDispose.family<UserModel?, String>((ref, uid) async {
  if (uid.isEmpty) return null;
  return await ref.watch(authServiceProvider).getUserDetails(uid);
});

final currentUserDataProvider = FutureProvider.autoDispose<UserModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return await ref.watch(authServiceProvider).getUserDetails(user.uid);
});

class AuthService {
  final ProviderRef ref;

  AuthService(this.ref);

  FirebaseAuth get _auth => ref.read(firebaseAuthProvider);
  FirebaseFirestore get _firestore => ref.read(firebaseFirestoreProvider);

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Phone number authentication steps
  
  // Step 1: Send verification code
  Future<void> sendPhoneVerification({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      timeout: const Duration(seconds: 60),
    );
  }
  
  // Step 2: Verify code and sign in
  Future<UserCredential> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // If this is a new user, create the user document
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await createUserDocument(
          userCredential.user!.uid,
          userCredential.user!.phoneNumber ?? '',
        );
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw getAuthErrorMessage(e.code);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Create user document in Firestore
  Future<void> createUserDocument(String uid, String phoneNumber) async {
    DateTime now = DateTime.now();
    
    // Generate a random username based on phone number
    // Remove all non-digit characters and take last 6 digits
    String username = 'user_${phoneNumber.replaceAll(RegExp(r'[^\d]'), '').substring(phoneNumber.length - 6)}';
    
    UserModel newUser = UserModel(
      id: uid,
      username: username,
      email: '',  // Empty for phone auth users
      phoneNumber: phoneNumber,
      photoURL: null,
      bio: null,
      followersCount: 0,
      followingCount: 0,
      likesCount: 0,
      followers: [],
      following: [],
      createdAt: now,
      updatedAt: now,
    );

    await _firestore.collection('users').doc(uid).set(newUser.toJson());
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? username,
    String? photoURL,
    String? bio,
  }) async {
    try {
      // Get current user data
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        UserModel userModel = UserModel.fromJson(userData);
        
        // Check if the username is already taken (if changing username)
        if (username != null && username != userModel.username) {
          QuerySnapshot usernameQuery = await _firestore
              .collection('users')
              .where('username', isEqualTo: username)
              .get();
              
          if (usernameQuery.docs.isNotEmpty) {
            throw 'Username already taken';
          }
        }
        
        // Update user data
        UserModel updatedUser = userModel.copyWith(
          username: username,
          photoURL: photoURL,
          bio: bio,
          updatedAt: DateTime.now(),
        );
        
        await _firestore
            .collection('users')
            .doc(uid)
            .update(updatedUser.toJson());
      }
    } catch (e) {
      throw 'Failed to update profile: $e';
    }
  }

  // Check if username is already taken
  Future<bool> isUsernameTaken(String username) async {
    try {
      QuerySnapshot usernameQuery = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();
          
      return usernameQuery.docs.isNotEmpty;
    } catch (e) {
      throw 'Failed to check username: $e';
    }
  }

  // Get user details from Firestore
  Future<UserModel?> getUserDetails(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return UserModel.fromJson(userData);
      }
      return null;
    } catch (e) {
      throw 'Failed to get user details: $e';
    }
  }
  
  // Email-password authentication for admin/superAdmin only
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Verify that this is an admin or superAdmin
      UserModel? user = await getUserDetails(userCredential.user!.uid);
      if (user == null || (user.role != 'admin' && user.role != 'superAdmin')) {
        await _auth.signOut();
        throw 'Unauthorized access. Email login is reserved for administrators only.';
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw getAuthErrorMessage(e.code);
    }
  }
  
  // Create admin user (only callable by superAdmin)
  Future<void> createAdminUser(String email, String password, String username, String role) async {
    try {
      // Check if current user is superAdmin
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw 'Authentication required';
      }
      
      UserModel? currentUserData = await getUserDetails(currentUser.uid);
      if (currentUserData?.role != 'superAdmin') {
        throw 'Only superAdmin can create admin accounts';
      }
      
      // Check if username is already taken
      bool usernameTaken = await isUsernameTaken(username);
      if (usernameTaken) {
        throw 'Username already taken';
      }
      
      // Create user with email and password
      UserCredential adminUserCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create user document with admin role
      DateTime now = DateTime.now();
      UserModel newAdmin = UserModel(
        id: adminUserCredential.user!.uid,
        username: username,
        email: email,
        phoneNumber: '',
        photoURL: null,
        bio: null,
        followersCount: 0,
        followingCount: 0,
        likesCount: 0,
        followers: [],
        following: [],
        role: role, // 'admin' or 'superAdmin'
        createdAt: now,
        updatedAt: now,
      );
      
      await _firestore
          .collection('users')
          .doc(adminUserCredential.user!.uid)
          .set(newAdmin.toJson());
      
      // Sign back in as the superAdmin
      await _auth.signInWithEmailAndPassword(
        email: currentUserData!.email,
        password: '', // We don't store passwords, so this is a placeholder
      );
    } on FirebaseAuthException catch (e) {
      throw getAuthErrorMessage(e.code);
    }
  }

  // Helper method to get user-friendly error messages
  String getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'The email address is already in use.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'invalid-verification-code':
        return 'The verification code is invalid.';
      case 'invalid-verification-id':
        return 'The verification ID is invalid.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}