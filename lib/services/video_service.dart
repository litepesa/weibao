import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:uuid/uuid.dart';
import 'package:weibao/models/user_model.dart';
import 'package:weibao/models/video_model.dart';
import 'package:weibao/models/comment_model.dart';
import 'package:weibao/services/auth_service.dart';

import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class VideoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService;
  final Uuid _uuid = Uuid();

  VideoService(this._authService);

  // Upload video to Firebase Storage
  Future<Map<String, dynamic>> uploadVideo(File videoFile, String caption, List<String> hashtags) async {
    User? user = _auth.currentUser;
    if (user == null) {
      throw 'User not signed in';
    }

    try {
      String videoId = _uuid.v4();
      String videoPath = 'videos/${user.uid}/$videoId.mp4';
      
      // Upload video file
      TaskSnapshot uploadTask = await _storage
          .ref(videoPath)
          .putFile(videoFile);
      
      String videoURL = await uploadTask.ref.getDownloadURL();
      
      // Generate thumbnail
      File thumbnailFile = await generateThumbnail(videoFile);
      String thumbnailPath = 'thumbnails/${user.uid}/$videoId.jpg';
      
      // Upload thumbnail
      TaskSnapshot thumbnailTask = await _storage
          .ref(thumbnailPath)
          .putFile(thumbnailFile);
      
      String thumbnailURL = await thumbnailTask.ref.getDownloadURL();
      
      // Get video duration
      Duration duration = await getVideoDuration(videoFile);
      
      // Get user data
      UserModel? userData = await _authService.getUserDetails(user.uid);
      
      if (userData == null) {
        throw 'User data not found';
      }
      
      // Create video document in Firestore
      VideoModel newVideo = VideoModel(
        id: videoId,
        userId: user.uid,
        username: userData.username,
        userPhotoURL: userData.photoURL ?? '',
        videoURL: videoURL,
        thumbnailURL: thumbnailURL,
        caption: caption,
        hashtags: hashtags,
        duration: duration,
        createdAt: DateTime.now(),
      );
      
      await _firestore
          .collection('videos')
          .doc(videoId)
          .set(newVideo.toJson());
      
      // Return necessary data
      return {
        'videoId': videoId,
        'videoURL': videoURL,
        'thumbnailURL': thumbnailURL,
      };
    } catch (e) {
      throw 'Failed to upload video: $e';
    }
  }
  
  // Generate thumbnail from video file
  Future<File> generateThumbnail(File videoFile) async {
    final tempDir = await getTemporaryDirectory();
    final thumbnailFilePath = await VideoThumbnail.thumbnailFile(
      video: videoFile.path,
      thumbnailPath: tempDir.path,
      imageFormat: ImageFormat.JPEG,
      quality: 80,
    );
    
    if (thumbnailFilePath == null) {
      throw 'Failed to generate thumbnail';
    }
    
    return File(thumbnailFilePath as String);
  }
  
  // Get video duration
  Future<Duration> getVideoDuration(File videoFile) async {
    final controller = VideoPlayerController.file(videoFile);
    await controller.initialize();
    Duration duration = controller.value.duration;
    await controller.dispose();
    return duration;
  }
  
  // Get videos for feed
  Future<List<VideoModel>> getVideosForFeed({int limit = 10, DocumentSnapshot? lastDocument}) async {
    try {
      Query query = _firestore
          .collection('videos')
          .orderBy('createdAt', descending: true)
          .limit(limit);
      
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      QuerySnapshot querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => VideoModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw 'Failed to get videos: $e';
    }
  }
  
  // Get videos by user
  Future<List<VideoModel>> getVideosByUser(String userId, {int limit = 10, DocumentSnapshot? lastDocument}) async {
    try {
      Query query = _firestore
          .collection('videos')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);
      
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      QuerySnapshot querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => VideoModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw 'Failed to get videos by user: $e';
    }
  }
  
  // Like/unlike video
  Future<void> toggleLikeVideo(String videoId) async {
    User? user = _auth.currentUser;
    if (user == null) {
      throw 'User not signed in';
    }
    
    try {
      DocumentReference videoRef = _firestore.collection('videos').doc(videoId);
      
      return _firestore.runTransaction((transaction) async {
        DocumentSnapshot videoSnapshot = await transaction.get(videoRef);
        
        if (!videoSnapshot.exists) {
          throw 'Video not found';
        }
        
        Map<String, dynamic> videoData = videoSnapshot.data() as Map<String, dynamic>;
        List<String> likedBy = List<String>.from(videoData['likedBy'] ?? []);
        
        if (likedBy.contains(user.uid)) {
          // Unlike
          likedBy.remove(user.uid);
          transaction.update(videoRef, {
            'likedBy': likedBy,
            'likesCount': FieldValue.increment(-1),
          });
          
          // Update user likesCount
          transaction.update(
            _firestore.collection('users').doc(user.uid),
            {'likesCount': FieldValue.increment(-1)},
          );
        } else {
          // Like
          likedBy.add(user.uid);
          transaction.update(videoRef, {
            'likedBy': likedBy,
            'likesCount': FieldValue.increment(1),
          });
          
          // Update user likesCount
          transaction.update(
            _firestore.collection('users').doc(user.uid),
            {'likesCount': FieldValue.increment(1)},
          );
        }
      });
    } catch (e) {
      throw 'Failed to toggle like: $e';
    }
  }
  
  // Add comment to video
  Future<CommentModel> addComment(String videoId, String text) async {
    User? user = _auth.currentUser;
    if (user == null) {
      throw 'User not signed in';
    }
    
    try {
      UserModel? userData = await _authService.getUserDetails(user.uid);
      
      if (userData == null) {
        throw 'User data not found';
      }
      
      String commentId = _uuid.v4();
      
      CommentModel newComment = CommentModel(
        id: commentId,
        videoId: videoId,
        userId: user.uid,
        username: userData.username,
        userPhotoURL: userData.photoURL ?? '',
        text: text,
        createdAt: DateTime.now(),
      );
      
      await _firestore
          .collection('videos')
          .doc(videoId)
          .collection('comments')
          .doc(commentId)
          .set(newComment.toJson());
      
      // Update video comments count
      await _firestore
          .collection('videos')
          .doc(videoId)
          .update({'commentsCount': FieldValue.increment(1)});
      
      return newComment;
    } catch (e) {
      throw 'Failed to add comment: $e';
    }
  }
  
  // Get comments for video
  Future<List<CommentModel>> getCommentsForVideo(String videoId, {int limit = 20, DocumentSnapshot? lastDocument}) async {
    try {
      Query query = _firestore
          .collection('videos')
          .doc(videoId)
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .limit(limit);
      
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      QuerySnapshot querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => CommentModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw 'Failed to get comments: $e';
    }
  }
  
  // Delete video
  Future<void> deleteVideo(String videoId) async {
    User? user = _auth.currentUser;
    if (user == null) {
      throw 'User not signed in';
    }
    
    try {
      // Check if video belongs to user
      DocumentSnapshot videoDoc = await _firestore
          .collection('videos')
          .doc(videoId)
          .get();
      
      if (!videoDoc.exists) {
        throw 'Video not found';
      }
      
      Map<String, dynamic> videoData = videoDoc.data() as Map<String, dynamic>;
      
      if (videoData['userId'] != user.uid) {
        throw 'You can only delete your own videos';
      }
      
      // Delete video file and thumbnail from storage
      await _storage.ref('videos/${user.uid}/$videoId.mp4').delete();
      await _storage.ref('thumbnails/${user.uid}/$videoId.jpg').delete();
      
      // Delete comments subcollection
      QuerySnapshot commentsSnapshot = await _firestore
          .collection('videos')
          .doc(videoId)
          .collection('comments')
          .get();
      
      WriteBatch batch = _firestore.batch();
      
      for (DocumentSnapshot doc in commentsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete video document
      batch.delete(_firestore.collection('videos').doc(videoId));
      
      await batch.commit();
    } catch (e) {
      throw 'Failed to delete video: $e';
    }
  }
}