import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:weibao/models/user_model.dart';
import 'package:weibao/models/video_model.dart';
import 'package:weibao/services/auth_service.dart';
import 'package:weibao/services/video_service.dart';
import 'package:weibao/screens/auth/profile_edit_screen.dart';
import 'package:weibao/screens/auth/phone_auth_screen.dart';
import 'package:weibao/widgets/video/video_thumbnail_card.dart';
import 'package:weibao/widgets/common/loading_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';

final userVideosProvider = FutureProvider.family<List<VideoModel>, String>((ref, userId) async {
  final videoService = VideoService(ref.watch(authServiceProvider));
  return await videoService.getVideosByUser(userId);
});

class ProfileScreen extends ConsumerStatefulWidget {
  final String? userId;
  
  const ProfileScreen({
    super.key,
    this.userId,
  });

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _signOut() async {
    try {
      await ref.read(authServiceProvider).signOut();
      
      if (!mounted) return;
      
      // Navigate to login screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const PhoneAuthScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final String profileUserId = widget.userId ?? currentUser?.uid ?? '';
    final bool isCurrentUser = widget.userId == null || widget.userId == currentUser?.uid;
    
    if (profileUserId.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('User not logged in'),
        ),
      );
    }
    
    final userDataAsync = ref.watch(userDataProvider(profileUserId));
    
    return Scaffold(
      appBar: AppBar(
        title: userDataAsync.maybeWhen(
          data: (user) => Text('@${user?.username ?? ""}'),
          orElse: () => const Text('Profile'),
        ),
        actions: [
          if (isCurrentUser)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ProfileEditScreen(),
                    ),
                  );
                } else if (value == 'settings') {
                  // TODO: Navigate to settings screen
                } else if (value == 'logout') {
                  _signOut();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit Profile'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings),
                      SizedBox(width: 8),
                      Text('Settings'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 8),
                      Text('Log Out'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: userDataAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('User not found'),
            );
          }
          
          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: _buildProfileHeader(user, isCurrentUser),
                ),
                SliverToBoxAdapter(
                  child: TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(icon: Icon(Icons.grid_view)),
                      Tab(icon: Icon(Icons.favorite_border)),
                      Tab(icon: Icon(Icons.bookmark_border)),
                    ],
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildVideosGrid(profileUserId),
                _buildLikedVideosGrid(profileUserId),
                _buildSavedVideosGrid(profileUserId),
              ],
            ),
          );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, _) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
  
  Widget _buildProfileHeader(UserModel user, bool isCurrentUser) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile image
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[300],
            backgroundImage: user.photoURL != null && user.photoURL!.isNotEmpty
                ? CachedNetworkImageProvider(user.photoURL!)
                : null,
            child: user.photoURL == null || user.photoURL!.isEmpty
                ? const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.grey,
                  )
                : null,
          ),
          const SizedBox(height: 16),
          
          // Username
          Text(
            '@${user.username}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // Bio
          if (user.bio != null && user.bio!.isNotEmpty)
            Text(
              user.bio!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          const SizedBox(height: 16),
          
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatColumn(user.followingCount.toString(), 'Following'),
              Container(
                height: 30,
                width: 1,
                color: Colors.grey[300],
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              _buildStatColumn(user.followersCount.toString(), 'Followers'),
              Container(
                height: 30,
                width: 1,
                color: Colors.grey[300],
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              _buildStatColumn(user.likesCount.toString(), 'Likes'),
            ],
          ),
          const SizedBox(height: 16),
          
          // Action button (Edit profile or Follow)
          SizedBox(
            width: 200,
            child: ElevatedButton(
              onPressed: isCurrentUser
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProfileEditScreen(),
                        ),
                      );
                    }
                  : () {
                      // TODO: Implement follow functionality
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrentUser
                    ? Colors.grey[200]
                    : Theme.of(context).primaryColor,
                foregroundColor: isCurrentUser
                    ? Colors.black
                    : Colors.white,
              ),
              child: Text(isCurrentUser ? 'Edit Profile' : 'Follow'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
  
  Widget _buildVideosGrid(String userId) {
    final userVideosAsync = ref.watch(userVideosProvider(userId));
    
    return userVideosAsync.when(
      data: (videos) {
        if (videos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam_off,
                  size: 72,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  'No videos yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Videos you create will appear here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }
        
        return GridView.builder(
          padding: const EdgeInsets.all(4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2 / 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: videos.length,
          itemBuilder: (context, index) {
            return VideoThumbnailCard(video: videos[index]);
          },
        );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error: (error, _) => Center(
        child: Text('Error: $error'),
      ),
    );
  }
  
  Widget _buildLikedVideosGrid(String userId) {
    // TODO: Implement liked videos tab
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite,
            size: 72,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Liked videos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Videos you like will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSavedVideosGrid(String userId) {
    // TODO: Implement saved videos tab
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark,
            size: 72,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Saved videos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Videos you save will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}