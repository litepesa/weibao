import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:weibao/models/comment_model.dart';
import 'package:weibao/services/video_service.dart';
import 'package:weibao/services/auth_service.dart';
import 'package:weibao/widgets/user/user_profile_circle.dart';
import 'package:timeago/timeago.dart' as timeago;

final videoServiceProvider = Provider<VideoService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return VideoService(authService);
});

final commentsProvider = FutureProvider.family<List<CommentModel>, String>((ref, videoId) async {
  final videoService = ref.watch(videoServiceProvider);
  return await videoService.getCommentsForVideo(videoId);
});

class CommentsScreen extends ConsumerStatefulWidget {
  final String videoId;
  
  const CommentsScreen({
    super.key,
    required this.videoId,
  });

  @override
  ConsumerState<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends ConsumerState<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
  
  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      final videoService = ref.read(videoServiceProvider);
      await videoService.addComment(widget.videoId, _commentController.text.trim());
      
      // Clear the text field
      _commentController.clear();
      
      // Refresh comments
      ref.refresh(commentsProvider(widget.videoId));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add comment: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentsProvider(widget.videoId));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Comments list
          Expanded(
            child: commentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('Error loading comments: $error'),
              ),
              data: (comments) {
                if (comments.isEmpty) {
                  return const Center(
                    child: Text('No comments yet. Be the first to comment!'),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return CommentTile(comment: comment);
                  },
                );
              },
            ),
          ),
          
          // Comment input field
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // User avatar
                UserProfileCircle(
                  photoURL: FirebaseAuth.instance.currentUser?.photoURL ?? '',
                  userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                  size: 40,
                  showBorder: false,
                ),
                const SizedBox(width: 12),
                
                // Text field
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submitComment(),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Send button
                InkWell(
                  onTap: _isSubmitting ? null : _submitComment,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFF0050),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 24,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CommentTile extends StatelessWidget {
  final CommentModel comment;
  
  const CommentTile({
    super.key,
    required this.comment,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User avatar
          UserProfileCircle(
            photoURL: comment.userPhotoURL,
            userId: comment.userId,
            size: 40,
            showBorder: false,
          ),
          const SizedBox(width: 12),
          
          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username
                Text(
                  '@${comment.username}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                
                // Comment text
                Text(
                  comment.text,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                
                // Timestamp and likes
                Row(
                  children: [
                    Text(
                      timeago.format(comment.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${comment.likesCount} likes',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Like button
          IconButton(
            icon: const Icon(Icons.favorite_border, size: 16),
            onPressed: () {
              // TODO: Implement like functionality
            },
          ),
        ],
      ),
    );
  }
}