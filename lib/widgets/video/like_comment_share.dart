import 'package:flutter/material.dart';
import 'package:weibao/screens/video/comments_screen.dart';
import 'package:share_plus/share_plus.dart';

class LikeCommentShare extends StatelessWidget {
  final String videoId;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final bool isLiked;
  final VoidCallback onLike;
  
  const LikeCommentShare({
    super.key,
    required this.videoId,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.isLiked,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Like button
        _buildActionButton(
          icon: isLiked ? Icons.favorite : Icons.favorite_border,
          iconColor: isLiked ? Colors.red : Colors.white,
          count: likesCount,
          onTap: onLike,
        ),
        const SizedBox(height: 16),
        
        // Comment button
        _buildActionButton(
          icon: Icons.chat_bubble_outline,
          iconColor: Colors.white,
          count: commentsCount,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CommentsScreen(videoId: videoId),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        
        // Share button
        _buildActionButton(
          icon: Icons.reply,
          iconColor: Colors.white,
          count: sharesCount,
          onTap: () {
            Share.share('Check out this cool video on Weibao!');
          },
        ),
      ],
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required Color iconColor,
    required int count,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Icon(
            icon,
            color: iconColor,
            size: 30,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatCount(count),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }
}