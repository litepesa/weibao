import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String username;
  final String email;
  final String phoneNumber;
  final String? photoURL;
  final String? bio;
  final int followersCount;
  final int followingCount;
  final int likesCount;
  final List<String>? followers;
  final List<String>? following;
  final String? role; // null, 'admin', or 'superAdmin'
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.phoneNumber,
    this.photoURL,
    this.bio,
    this.followersCount = 0,
    this.followingCount = 0,
    this.likesCount = 0,
    this.followers,
    this.following,
    this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create user from firestore document
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      photoURL: json['photoURL'] as String?,
      bio: json['bio'] as String?,
      followersCount: json['followersCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
      likesCount: json['likesCount'] as int? ?? 0,
      followers: (json['followers'] as List<dynamic>?)?.map((e) => e as String).toList(),
      following: (json['following'] as List<dynamic>?)?.map((e) => e as String).toList(),
      role: json['role'] as String?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert user to JSON for firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'bio': bio,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'likesCount': likesCount,
      'followers': followers,
      'following': following,
      'role': role,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Create a copy of user with updated fields
  UserModel copyWith({
    String? username,
    String? email,
    String? phoneNumber,
    String? photoURL,
    String? bio,
    int? followersCount,
    int? followingCount,
    int? likesCount,
    List<String>? followers,
    List<String>? following,
    String? role,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoURL: photoURL ?? this.photoURL,
      bio: bio ?? this.bio,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      likesCount: likesCount ?? this.likesCount,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      role: role ?? this.role,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  // Check if user is admin
  bool get isAdmin => role == 'admin' || role == 'superAdmin';
  
  // Check if user is superAdmin
  bool get isSuperAdmin => role == 'superAdmin';
}