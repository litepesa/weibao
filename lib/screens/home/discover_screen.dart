import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:weibao/models/video_model.dart';
import 'package:weibao/services/video_service.dart';
import 'package:weibao/services/auth_service.dart';
import 'package:weibao/widgets/video/video_thumbnail_card.dart';
import 'package:weibao/widgets/common/loading_indicator.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider.autoDispose<List<VideoModel>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  
  try {
    final firestore = FirebaseFirestore.instance;
    
    // Search by caption
    QuerySnapshot captionResults = await firestore
        .collection('videos')
        .where('caption', isGreaterThanOrEqualTo: query)
        .where('caption', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(10)
        .get();
    
    // Search by hashtags
    QuerySnapshot hashtagResults = await firestore
        .collection('videos')
        .where('hashtags', arrayContains: query.startsWith('#') ? query.substring(1) : query)
        .limit(10)
        .get();
    
    // Search by username
    QuerySnapshot usernameResults = await firestore
        .collection('videos')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(10)
        .get();
    
    // Combine and deduplicate results
    Set<String> documentIds = {};
    List<VideoModel> videos = [];
    
    for (var doc in [...captionResults.docs, ...hashtagResults.docs, ...usernameResults.docs]) {
      if (!documentIds.contains(doc.id)) {
        documentIds.add(doc.id);
        videos.add(VideoModel.fromJson(doc.data() as Map<String, dynamic>));
      }
    }
    
    return videos;
  } catch (e) {
    throw 'Search failed: $e';
  }
});

final trendingVideosProvider = FutureProvider.autoDispose<List<VideoModel>>((ref) async {
  try {
    final firestore = FirebaseFirestore.instance;
    
    // Get videos with most likes in the past week
    final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
    final snapshot = await firestore
        .collection('videos')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(oneWeekAgo))
        .orderBy('createdAt', descending: true)
        .orderBy('likesCount', descending: true)
        .limit(20)
        .get();
    
    return snapshot.docs
        .map((doc) => VideoModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  } catch (e) {
    throw 'Failed to load trending videos: $e';
  }
});

final trendingHashtagsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  try {
    final firestore = FirebaseFirestore.instance;
    
    // Aggregate hashtags from recent videos
    final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
    final snapshot = await firestore
        .collection('videos')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(oneWeekAgo))
        .get();
    
    // Count occurrences of each hashtag
    Map<String, int> hashtagCounts = {};
    for (var doc in snapshot.docs) {
      final videoData = doc.data() as Map<String, dynamic>;
      final hashtags = List<String>.from(videoData['hashtags'] ?? []);
      
      for (var hashtag in hashtags) {
        hashtagCounts[hashtag] = (hashtagCounts[hashtag] ?? 0) + 1;
      }
    }
    
    // Convert to list and sort by count
    List<Map<String, dynamic>> trendingHashtags = hashtagCounts.entries
        .map((entry) => {
              'tag': entry.key,
              'count': entry.value,
            })
        .toList();
    
    trendingHashtags.sort((a, b) => b['count'].compareTo(a['count']));
    
    // Return top 10
    return trendingHashtags.take(10).toList();
  } catch (e) {
    throw 'Failed to load trending hashtags: $e';
  }
});

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchFocusNode.addListener(_onSearchFocusChange);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChange);
    _searchFocusNode.dispose();
    super.dispose();
  }
  
  void _onSearchFocusChange() {
    setState(() {
      _isSearching = _searchFocusNode.hasFocus;
    });
  }
  
  void _performSearch(String query) {
    if (query.isNotEmpty) {
      ref.read(searchQueryProvider.notifier).state = query;
    }
  }
  
  void _clearSearch() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    _searchFocusNode.unfocus();
  }
  
  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: _isSearching || searchQuery.isNotEmpty
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Search for videos, users, hashtags',
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
                  ),
                ),
                onSubmitted: _performSearch,
              )
            : const Text('Discover'),
        actions: [
          if (!_isSearching && searchQuery.isEmpty)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
                _searchFocusNode.requestFocus();
              },
            ),
        ],
        bottom: searchQuery.isEmpty
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Trending'),
                  Tab(text: 'Hashtags'),
                  Tab(text: 'Sounds'),
                  Tab(text: 'Live'),
                ],
              )
            : null,
      ),
      body: searchQuery.isNotEmpty
          ? _buildSearchResults()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTrendingTab(),
                _buildHashtagsTab(),
                _buildSoundsTab(),
                _buildLiveTab(),
              ],
            ),
    );
  }
  
  Widget _buildSearchResults() {
    final searchResultsAsync = ref.watch(searchResultsProvider);
    
    return searchResultsAsync.when(
      data: (videos) {
        if (videos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.search_off,
                  size: 72,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'No results found for "${ref.read(searchQueryProvider)}"',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }
        
        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2 / 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
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
  
  Widget _buildTrendingTab() {
    final trendingVideosAsync = ref.watch(trendingVideosProvider);
    
    return trendingVideosAsync.when(
      data: (videos) {
        if (videos.isEmpty) {
          return const Center(
            child: Text('No trending videos found'),
          );
        }
        
        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2 / 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
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
  
  Widget _buildHashtagsTab() {
    final trendingHashtagsAsync = ref.watch(trendingHashtagsProvider);
    
    return trendingHashtagsAsync.when(
      data: (hashtags) {
        if (hashtags.isEmpty) {
          return const Center(
            child: Text('No trending hashtags found'),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: hashtags.length,
          itemBuilder: (context, index) {
            final hashtag = hashtags[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () {
                  // Search for this hashtag
                  ref.read(searchQueryProvider.notifier).state = hashtag['tag'];
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '#',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '#${hashtag['tag']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${hashtag['count']} videos',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error: (error, _) => Center(
        child: Text('Error: $error'),
      ),
    );
  }
  
  Widget _buildSoundsTab() {
    // Placeholder for sounds tab
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note,
            size: 72,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Sounds feature coming soon',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLiveTab() {
    // Placeholder for live tab
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.live_tv,
            size: 72,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Live streaming feature coming soon',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}