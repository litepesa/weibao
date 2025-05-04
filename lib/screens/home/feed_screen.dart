import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:weibao/models/video_model.dart';
import 'package:weibao/services/video_service.dart';
import 'package:weibao/services/auth_service.dart';
import 'package:weibao/widgets/video/video_player_widget.dart';
import 'package:weibao/widgets/video/like_comment_share.dart';
import 'package:weibao/widgets/user/user_profile_circle.dart';

// Video service provider
final videoServiceProvider = Provider<VideoService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return VideoService(authService);
});

// Define providers for feed videos
final feedVideosProvider = StateNotifierProvider<FeedVideosNotifier, FeedVideosState>((ref) {
  final videoService = ref.watch(videoServiceProvider);
  return FeedVideosNotifier(videoService);
});

// State class for feed videos
class FeedVideosState {
  final List<VideoModel> videos;
  final bool isLoading;
  final bool hasMore;
  final String? errorMessage;
  final DocumentSnapshot? lastDocument;

  FeedVideosState({
    required this.videos,
    required this.isLoading,
    required this.hasMore,
    this.errorMessage,
    this.lastDocument,
  });

  FeedVideosState copyWith({
    List<VideoModel>? videos,
    bool? isLoading,
    bool? hasMore,
    String? errorMessage,
    DocumentSnapshot? lastDocument,
  }) {
    return FeedVideosState(
      videos: videos ?? this.videos,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
      lastDocument: lastDocument ?? this.lastDocument,
    );
  }
}

// Notifier class for feed videos
class FeedVideosNotifier extends StateNotifier<FeedVideosState> {
  final VideoService _videoService;

  FeedVideosNotifier(this._videoService)
      : super(FeedVideosState(
          videos: [],
          isLoading: false,
          hasMore: true,
        ));

  Future<void> loadVideos() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final videos = await _videoService.getVideosForFeed(
        lastDocument: state.lastDocument,
      );

      if (videos.isEmpty) {
        state = state.copyWith(
          hasMore: false,
          isLoading: false,
        );
        return;
      }

      state = state.copyWith(
        videos: [...state.videos, ...videos],
        lastDocument: FirebaseFirestore.instance
            .collection('videos')
            .doc(videos.last.id) as DocumentSnapshot<Object?>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error loading videos: $e',
      );
    }
  }

  void resetFeed() {
    state = FeedVideosState(
      videos: [],
      isLoading: false,
      hasMore: true,
    );
    loadVideos();
  }
}

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final PageController _pageController = PageController();
  
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(feedVideosProvider.notifier).loadVideos());
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  void _onPageChanged(int page) {
    // Load more videos when reaching the end
    final feedState = ref.read(feedVideosProvider);
    if (page >= feedState.videos.length - 2 && 
        !feedState.isLoading && 
        feedState.hasMore) {
      ref.read(feedVideosProvider.notifier).loadVideos();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedVideosProvider);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Following',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: Colors.white70,
              ),
            ),
            SizedBox(width: 20),
            Text(
              'For You',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: feedState.videos.isEmpty && feedState.isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : feedState.videos.isEmpty && feedState.errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(feedState.errorMessage!),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(feedVideosProvider.notifier).resetFeed();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : feedState.videos.isEmpty
          ? const Center(
              child: Text('No videos found'),
            )
          : Stack(
              children: [
                PageView.builder(
                  scrollDirection: Axis.vertical,
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: feedState.videos.length,
                  itemBuilder: (context, index) {
                    final video = feedState.videos[index];
                    return VideoPost(video: video);
                  },
                ),
                if (feedState.isLoading)
                  const Positioned(
                    bottom: 50,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
    );
  }
}

class VideoPost extends ConsumerStatefulWidget {
  final VideoModel video;
  
  const VideoPost({
    super.key,
    required this.video,
  });

  @override
  ConsumerState<VideoPost> createState() => _VideoPostState();
}

// Provider for liked status
final videoLikedStatusProvider = StateProvider.family<bool, String>((ref, videoId) {
  final currentUser = ref.read(currentUserProvider);
  if (currentUser == null) return false;
  
  return false; // Default state before we check
});

class _VideoPostState extends ConsumerState<VideoPost> with AutomaticKeepAliveClientMixin {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _checkIfLiked();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.network(widget.video.videoURL);
    await _controller.initialize();
    _controller.setLooping(true);
    
    setState(() {
      _isInitialized = true;
    });
    
    _playVideo();
  }
  
  void _playVideo() {
    _controller.play();
    setState(() {
      _isPlaying = true;
    });
  }
  
  void _pauseVideo() {
    _controller.pause();
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
  
  void _checkIfLiked() {
    final user = ref.read(currentUserProvider);
    if (user != null && widget.video.likedBy != null) {
      ref.read(videoLikedStatusProvider(widget.video.id).notifier).state = 
          widget.video.likedBy!.contains(user.uid);
    }
  }
  
  void _handleLike() async {
    final videoService = ref.read(videoServiceProvider);
    
    try {
      await videoService.toggleLikeVideo(widget.video.id);
      
      // Toggle the liked state
      ref.read(videoLikedStatusProvider(widget.video.id).notifier).update((state) => !state);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error liking video: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final isLiked = ref.watch(videoLikedStatusProvider(widget.video.id));
    
    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video Player
          _isInitialized
              ? VideoPlayerWidget(controller: _controller)
              : const Center(child: CircularProgressIndicator()),
          
          // Gradient overlay at the bottom for better text visibility
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          // Video info overlay (username, caption, etc.)
          Positioned(
            left: 16,
            right: 80, // Leave space for the action buttons
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@${widget.video.username}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.video.caption,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                if (widget.video.hashtags.isNotEmpty)
                  Text(
                    widget.video.hashtags.map((tag) => '#$tag').join(' '),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
          
          // Action buttons (like, comment, share)
          Positioned(
            right: 16,
            bottom: 80,
            child: LikeCommentShare(
              videoId: widget.video.id,
              likesCount: widget.video.likesCount,
              commentsCount: widget.video.commentsCount,
              sharesCount: widget.video.sharesCount,
              isLiked: isLiked,
              onLike: _handleLike,
            ),
          ),
          
          // User profile circle
          Positioned(
            right: 16,
            bottom: 20,
            child: UserProfileCircle(
              photoURL: widget.video.userPhotoURL,
              userId: widget.video.userId,
              size: 48,
            ),
          ),
          
          // Play/Pause indicator
          if (!_isPlaying)
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
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
            ),
        ],
      ),
    );
  }
}