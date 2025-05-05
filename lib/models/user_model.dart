import 'package:weibao/constants.dart';

class UserModel {
  final String uid;
  final String name;
  final String phoneNumber;
  final String image;
  final String token;
  final String aboutMe;
  final String createdAt;
  final List<String> contactsUIDs;  
  final List<String> blockedUIDs;   

  UserModel({
    required this.uid,
    required this.name,
    required this.phoneNumber,
    required this.image,
    required this.token,
    required this.aboutMe,
    required this.createdAt,
    required this.contactsUIDs,
    required this.blockedUIDs,
  });

  // from map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map[Constants.uid] ?? '',
      name: map[Constants.name] ?? '',
      phoneNumber: map[Constants.phoneNumber] ?? '',
      image: map[Constants.image] ?? '',
      token: map[Constants.token] ?? '',
      aboutMe: map[Constants.aboutMe] ?? '',
      createdAt: map[Constants.createdAt] ?? '',
      contactsUIDs: List<String>.from(map[Constants.contactsUIDs] ?? []),
      blockedUIDs: List<String>.from(map[Constants.blockedUIDs] ?? []),
    );
  }

  // to map
  Map<String, dynamic> toMap() {
    return {
      Constants.uid: uid,
      Constants.name: name,
      Constants.phoneNumber: phoneNumber,
      Constants.image: image,
      Constants.token: token,
      Constants.aboutMe: aboutMe,
      Constants.createdAt: createdAt,
      Constants.contactsUIDs: contactsUIDs,
      Constants.blockedUIDs: blockedUIDs,
    };
  }

  // copyWith for immutability
  UserModel copyWith({
    String? uid,
    String? name,
    String? phoneNumber,
    String? image,
    String? token,
    String? aboutMe,
    String? createdAt,
    List<String>? contactsUIDs,
    List<String>? blockedUIDs,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      image: image ?? this.image,
      token: token ?? this.token,
      aboutMe: aboutMe ?? this.aboutMe,
      createdAt: createdAt ?? this.createdAt,
      contactsUIDs: contactsUIDs ?? this.contactsUIDs,
      blockedUIDs: blockedUIDs ?? this.blockedUIDs,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode {
    return uid.hashCode;
  }
}