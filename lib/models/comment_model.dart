import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String videoId;
  final String userId;
  final String username;
  final String userPhotoURL;
  final String text;
  final int likesCount;
  final List<String>? likedBy;
  final DateTime createdAt;
  final List<CommentModel>? replies;

  CommentModel({
    required this.id,
    required this.videoId,
    required this.userId,
    required this.username,
    required this.userPhotoURL,
    required this.text,
    this.likesCount = 0,
    this.likedBy,
    required this.createdAt,
    this.replies,
  });

  // Create comment from firestore document
  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String,
      videoId: json['videoId'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String,
      userPhotoURL: json['userPhotoURL'] as String,
      text: json['text'] as String,
      likesCount: json['likesCount'] as int,
      likedBy: (json['likedBy'] as List<dynamic>?)?.map((e) => e as String).toList(),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      replies: (json['replies'] as List<dynamic>?)
          ?.map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  // Convert comment to JSON for firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'videoId': videoId,
      'userId': userId,
      'username': username,
      'userPhotoURL': userPhotoURL,
      'text': text,
      'likesCount': likesCount,
      'likedBy': likedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'replies': replies?.map((e) => e.toJson()).toList(),
    };
  }

  // Create a copy of comment with updated fields
  CommentModel copyWith({
    String? text,
    int? likesCount,
    List<String>? likedBy,
    List<CommentModel>? replies,
  }) {
    return CommentModel(
      id: id,
      videoId: videoId,
      userId: userId,
      username: username,
      userPhotoURL: userPhotoURL,
      text: text ?? this.text,
      likesCount: likesCount ?? this.likesCount,
      likedBy: likedBy ?? this.likedBy,
      createdAt: createdAt,
      replies: replies ?? this.replies,
    );
  }
}