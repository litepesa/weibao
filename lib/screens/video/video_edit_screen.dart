import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:weibao/config/theme.dart';
import 'package:weibao/services/video_service.dart';
import 'package:weibao/services/auth_service.dart';
import 'package:weibao/screens/home/home_screen.dart';
import 'package:weibao/widgets/common/loading_indicator.dart';

final videoServiceProvider = Provider<VideoService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return VideoService(authService);
});

class VideoEditScreen extends ConsumerStatefulWidget {
  final File videoFile;
  
  const VideoEditScreen({
    super.key,
    required this.videoFile,
  });

  @override
  ConsumerState<VideoEditScreen> createState() => _VideoEditScreenState();
}

class _VideoEditScreenState extends ConsumerState<VideoEditScreen> {
  late VideoPlayerController _controller;
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _hashtagController = TextEditingController();
  final List<String> _hashtags = [];
  bool _isUploading = false;
  bool _isVideoInitialized = false;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _captionController.dispose();
    _hashtagController.dispose();
    super.dispose();
  }
  
  Future<void> _initializeVideoPlayer() async {
    _controller = VideoPlayerController.file(widget.videoFile);
    await _controller.initialize();
    await _controller.setLooping(true);
    await _controller.play();
    
    setState(() {
      _isVideoInitialized = true;
    });
  }
  
  void _addHashtag() {
    final hashtag = _hashtagController.text.trim();
    if (hashtag.isEmpty) return;
    
    if (!hashtag.startsWith('#')) {
      _hashtagController.text = '#$hashtag';
    }
    
    // Remove any spaces and special characters
    final cleanedHashtag = hashtag.replaceAll(RegExp(r'[^\w#]'), '');
    
    if (cleanedHashtag.length > 1 && !_hashtags.contains(cleanedHashtag)) {
      setState(() {
        _hashtags.add(cleanedHashtag.substring(1)); // Remove # prefix for storage
        _hashtagController.clear();
      });
    }
  }
  
  void _removeHashtag(int index) {
    setState(() {
      _hashtags.removeAt(index);
    });
  }
  
  Future<void> _uploadVideo() async {
    if (_captionController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please add a caption to your video';
      });
      return;
    }
    
    setState(() {
      _isUploading = true;
      _errorMessage = '';
    });
    
    try {
      final videoService = ref.read(videoServiceProvider);
      
      await videoService.uploadVideo(
        widget.videoFile,
        _captionController.text.trim(),
        _hashtags,
      );
      
      if (mounted) {
        // Navigate back to home screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to upload video: $e';
        _isUploading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Video'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _uploadVideo,
            child: const Text(
              'Post',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: _isUploading
          ? const Center(
              child: LoadingIndicator(
                message: 'Uploading your video...',
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Video preview
                  AspectRatio(
                    aspectRatio: 9 / 16, // TikTok-like aspect ratio
                    child: _isVideoInitialized
                        ? VideoPlayer(_controller)
                        : const Center(
                            child: CircularProgressIndicator(),
                          ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Caption input
                        TextField(
                          controller: _captionController,
                          decoration: const InputDecoration(
                            labelText: 'Write a caption...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                          maxLength: 150,
                        ),
                        const SizedBox(height: 16),
                        
                        // Hashtags section
                        const Text(
                          'Add Hashtags',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Hashtag input
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _hashtagController,
                                decoration: const InputDecoration(
                                  hintText: 'Add a hashtag...',
                                  prefixText: '#',
                                  border: OutlineInputBorder(),
                                ),
                                onSubmitted: (_) => _addHashtag(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _addHashtag,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Hashtags display
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(
                            _hashtags.length,
                            (index) => Chip(
                              label: Text('#${_hashtags[index]}'),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () => _removeHashtag(index),
                            ),
                          ),
                        ),
                        
                        // Error message
                        if (_errorMessage.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 24),
                        
                        // Advanced options
                        const ExpansionTile(
                          title: Text('Advanced Options'),
                          children: [
                            ListTile(
                              title: Text('Save to Device'),
                              trailing: Switch(
                                value: false,
                                onChanged: null,
                              ),
                            ),
                            ListTile(
                              title: Text('Allow Comments'),
                              trailing: Switch(
                                value: true,
                                onChanged: null,
                              ),
                            ),
                            ListTile(
                              title: Text('Allow Duets'),
                              trailing: Switch(
                                value: true,
                                onChanged: null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}