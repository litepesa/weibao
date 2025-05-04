import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:weibao/models/video_model.dart';
import 'package:weibao/services/video_service.dart';
import 'package:weibao/services/auth_service.dart';
import 'package:weibao/widgets/video/like_comment_share.dart';
import 'package:weibao/widgets/user/user_profile_circle.dart';
import 'package:weibao/widgets/common/loading_indicator.dart';

final singleVideoProvider = FutureProvider.family<VideoModel, String>((ref, videoId) async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('videos')
        .doc(videoId)
        .get();
    
    if (!snapshot.exists) {
      throw 'Video not found';
    }
    
    return VideoModel.fromJson(snapshot.data() as Map<String, dynamic>);
  } catch (e) {
    throw 'Failed to load video: $e';
  }
});

final relatedVideosProvider = FutureProvider.family<List<VideoModel>, VideoModel>((ref, video) async {
  try {
    // Get videos with similar hashtags
    final query = FirebaseFirestore.instance
        .collection('videos')
        .where('hashtags', arrayContainsAny: video.hashtags)
        .where('id', isNotEqualTo: video.id) // Exclude current video
        .limit(10);
    
    final snapshot = await query.get();
    
    // Convert to list of VideoModel
    return snapshot.docs
        .map((doc) => VideoModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  } catch (e) {
    throw 'Failed to load related videos: $e';
  }
});

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final String videoId;
  
  const VideoPlayerScreen({
    super.key,
    required this.videoId,
  });

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isLiked = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
  
  Future<void> _initializeVideo(String videoUrl) async {
    _controller = VideoPlayerController.network(videoUrl);
    
    _controller!.addListener(() {
      if (mounted) {
        setState(() {
          _position = _controller!.value.position;
        });
      }
    });
    
    await _controller!.initialize();
    await _controller!.setLooping(true);
    
    setState(() {
      _isInitialized = true;
      _duration = _controller!.value.duration;
    });
    
    _playVideo();
  }
  
  void _playVideo() {
    _controller?.play();
    setState(() {
      _isPlaying = true;
    });
  }
  
  void _pauseVideo() {
    _controller?.pause();
    setState(() {
      _isPlaying = false;
    });
  }
  
  void _togglePlay() {
    if (_isPlaying) {
      _pauseVideo();
    } else {
      _playVideo();
    }
  }
  
  void _checkIfLiked(VideoModel video) {
    final user = ref.read(currentUserProvider);
    if (user != null && video.likedBy != null) {
      setState(() {
        _isLiked = video.likedBy!.contains(user.uid);
      });
    }
  }
  
  void _handleLike() async {
    final videoService = VideoService(ref.read(authServiceProvider));
    
    try {
      await videoService.toggleLikeVideo(widget.videoId);
      
      setState(() {
        _isLiked = !_isLiked;
      });
      
      // Refresh video data
      ref.refresh(singleVideoProvider(widget.videoId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
  
  void _seekTo(Duration position) {
    _controller?.seekTo(position);
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
  
  @override
  Widget build(BuildContext context) {
    final videoAsync = ref.watch(singleVideoProvider(widget.videoId));
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: videoAsync.when(
        data: (video) {
          // Initialize video if not already initialized
          if (!_isInitialized) {
            _initializeVideo(video.videoURL);
            _checkIfLiked(video);
          }
          
          final relatedVideosAsync = ref.watch(relatedVideosProvider(video));
          
          return SafeArea(
            child: Column(
              children: [
                // App bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          // TODO: Show video options
                        },
                      ),
                    ],
                  ),
                ),
                
                // Video player
                AspectRatio(
                  aspectRatio: 9 / 16, // TikTok-like aspect ratio
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Video
                      _isInitialized
                          ? GestureDetector(
                              onTap: _togglePlay,
                              child: VideoPlayer(_controller!),
                            )
                          : const Center(
                              child: CircularProgressIndicator(),
                            ),
                      
                      // Play/pause indicator
                      if (!_isPlaying && _isInitialized)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      
                      // Bottom controls
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Column(
                          children: [
                            // Progress bar
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Text(
                                    _formatDuration(_position),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Expanded(
                                    child: Slider(
                                      value: _position.inSeconds.toDouble(),
                                      min: 0,
                                      max: _duration.inSeconds.toDouble(),
                                      onChanged: (value) {
                                        _seekTo(Duration(seconds: value.toInt()));
                                      },
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(_duration),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Video info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User info row
                      Row(
                        children: [
                          UserProfileCircle(
                            photoURL: video.userPhotoURL,
                            userId: video.userId,
                            size: 40,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '@${video.username}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                video.caption,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: () {
                              // TODO: Follow user functionality
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text('Follow'),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Caption and hashtags
                      Text(
                        video.caption,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (video.hashtags.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          children: video.hashtags
                              .map((tag) => Text(
                                    '#$tag',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ))
                              .toList(),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // Like, comment, share row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildActionButton(
                            icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                            label: _formatCount(video.likesCount),
                            color: _isLiked ? Colors.red : Colors.white,
                            onTap: _handleLike,
                          ),
                          _buildActionButton(
                            icon: Icons.comment,
                            label: _formatCount(video.commentsCount),
                            onTap: () {
                              // TODO: Open comments screen
                            },
                          ),
                          _buildActionButton(
                            icon: Icons.share,
                            label: _formatCount(video.sharesCount),
                            onTap: () {
                              // TODO: Implement share functionality
                            },
                          ),
                          _buildActionButton(
                            icon: Icons.bookmark_border,
                            label: 'Save',
                            onTap: () {
                              // TODO: Implement save functionality
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Related videos
                Expanded(
                  child: relatedVideosAsync.when(
                    data: (relatedVideos) {
                      if (relatedVideos.isEmpty) {
                        return const Center(
                          child: Text(
                            'No related videos found',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Related Videos',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: relatedVideos.length,
                              itemBuilder: (context, index) {
                                final relatedVideo = relatedVideos[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) => VideoPlayerScreen(
                                          videoId: relatedVideo.id,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 150,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: NetworkImage(relatedVideo.thumbnailURL),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        // Gradient overlay
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.transparent,
                                                Colors.black.withOpacity(0.7),
                                              ],
                                            ),
                                          ),
                                        ),
                                        
                                        // Info
                                        Positioned(
                                          left: 8,
                                          right: 8,
                                          bottom: 8,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '@${relatedVideo.username}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                relatedVideo.caption,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Play icon
                                        const Center(
                                          child: Icon(
                                            Icons.play_circle_outline,
                                            color: Colors.white,
                                            size: 40,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(
                      child: Text(
                        'Error loading related videos: $error',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color color = Colors.white,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
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