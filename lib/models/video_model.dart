import 'package:cloud_firestore/cloud_firestore.dart';

class VideoModel {
  final String id;
  final String userId;
  final String username;
  final String userPhotoURL;
  final String videoURL;
  final String thumbnailURL;
  final String caption;
  final List<String> hashtags;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final List<String>? likedBy;
  final double? aspectRatio;
  final Duration duration;
  final DateTime createdAt;

  VideoModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.userPhotoURL,
    required this.videoURL,
    required this.thumbnailURL,
    required this.caption,
    required this.hashtags,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.likedBy,
    this.aspectRatio = 9/16, // Default TikTok aspect ratio
    required this.duration,
    required this.createdAt,
  });

  // Create video from firestore document
  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String,
      userPhotoURL: json['userPhotoURL'] as String,
      videoURL: json['videoURL'] as String,
      thumbnailURL: json['thumbnailURL'] as String,
      caption: json['caption'] as String,
      hashtags: (json['hashtags'] as List<dynamic>).map((e) => e as String).toList(),
      likesCount: json['likesCount'] as int,
      commentsCount: json['commentsCount'] as int,
      sharesCount: json['sharesCount'] as int,
      likedBy: (json['likedBy'] as List<dynamic>?)?.map((e) => e as String).toList(),
      aspectRatio: json['aspectRatio'] as double?,
      duration: Duration(milliseconds: json['durationMs'] as int),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert video to JSON for firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userPhotoURL': userPhotoURL,
      'videoURL': videoURL,
      'thumbnailURL': thumbnailURL,
      'caption': caption,
      'hashtags': hashtags,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'likedBy': likedBy,
      'aspectRatio': aspectRatio,
      'durationMs': duration.inMilliseconds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create a copy of video with updated fields
  VideoModel copyWith({
    String? caption,
    List<String>? hashtags,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    List<String>? likedBy,
  }) {
    return VideoModel(
      id: id,
      userId: userId,
      username: username,
      userPhotoURL: userPhotoURL,
      videoURL: videoURL,
      thumbnailURL: thumbnailURL,
      caption: caption ?? this.caption,
      hashtags: hashtags ?? this.hashtags,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      likedBy: likedBy ?? this.likedBy,
      aspectRatio: aspectRatio,
      duration: duration,
      createdAt: createdAt,
    );
  }
}