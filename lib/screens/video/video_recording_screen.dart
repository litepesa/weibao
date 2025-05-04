import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:weibao/config/theme.dart';
import 'package:weibao/screens/video/video_edit_screen.dart';
import 'package:permission_handler/permission_handler.dart';

// Camera controller provider
final cameraControllerProvider = FutureProvider.autoDispose<CameraController?>((ref) async {
  final cameras = await availableCameras();
  if (cameras.isEmpty) return null;
  
  // Start with the back camera
  final controller = CameraController(
    cameras.first,
    ResolutionPreset.high,
    enableAudio: true,
  );
  
  await controller.initialize();
  ref.onDispose(() {
    controller.dispose();
  });
  
  return controller;
});

// Recording state
final recordingStateProvider = StateProvider<RecordingState>((ref) {
  return RecordingState.ready;
});

enum RecordingState {
  ready,
  recording,
  paused,
}

class VideoRecordingScreen extends ConsumerStatefulWidget {
  const VideoRecordingScreen({super.key});

  @override
  ConsumerState<VideoRecordingScreen> createState() => _VideoRecordingScreenState();
}

class _VideoRecordingScreenState extends ConsumerState<VideoRecordingScreen> {
  bool _isFrontCamera = false;
  bool _isFlashOn = false;
  double _currentZoom = 1.0;
  double _maxZoom = 1.0;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;
  String? _videoPath;
  bool _permissionDenied = false;
  
  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }
  
  @override
  void dispose() {
    _recordingTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _checkPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final microphoneStatus = await Permission.microphone.request();
    
    if (cameraStatus.isDenied || microphoneStatus.isDenied) {
      setState(() {
        _permissionDenied = true;
      });
    }
  }
  
  void _startRecordingTimer() {
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration = Duration(seconds: timer.tick);
      });
      
      // Auto-stop recording after 60 seconds (TikTok-like behavior)
      if (timer.tick >= 60) {
        _stopRecording();
      }
    });
  }
  
  Future<void> _toggleRecording() async {
    final controller = ref.read(cameraControllerProvider).value;
    if (controller == null) return;
    
    final currentState = ref.read(recordingStateProvider);
    
    if (currentState == RecordingState.ready) {
      // Start recording
      try {
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';
        
        await controller.startVideoRecording();
        
        ref.read(recordingStateProvider.notifier).state = RecordingState.recording;
        
        setState(() {
          _recordingDuration = Duration.zero;
          _videoPath = path;
        });
        
        _startRecordingTimer();
      } catch (e) {
        print('Error starting video recording: $e');
      }
    } else if (currentState == RecordingState.recording) {
      // Stop recording
      _stopRecording();
    }
  }
  
  Future<void> _stopRecording() async {
    final controller = ref.read(cameraControllerProvider).value;
    if (controller == null) return;
    
    try {
      _recordingTimer?.cancel();
      
      final file = await controller.stopVideoRecording();
      
      ref.read(recordingStateProvider.notifier).state = RecordingState.ready;
      
      setState(() {
        _videoPath = file.path;
      });
      
      // Navigate to edit screen
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => VideoEditScreen(videoFile: File(file.path)),
          ),
        );
      }
    } catch (e) {
      print('Error stopping video recording: $e');
      ref.read(recordingStateProvider.notifier).state = RecordingState.ready;
    }
  }
  
  Future<void> _toggleCamera() async {
    final controller = ref.read(cameraControllerProvider).value;
    if (controller == null) return;
    
    final cameras = await availableCameras();
    if (cameras.length < 2) return;
    
    final newCameraDescription = _isFrontCamera ? cameras.first : cameras[1];
    
    // Dispose the old controller
    await controller.dispose();
    
    // Create a new controller with the opposite camera
    final newController = CameraController(
      newCameraDescription,
      ResolutionPreset.high,
      enableAudio: true,
    );
    
    await newController.initialize();
    
    // Update the provider
    ref.invalidate(cameraControllerProvider);
    
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
  }
  
  Future<void> _toggleFlash() async {
    final controller = ref.read(cameraControllerProvider).value;
    if (controller == null) return;
    
    try {
      if (_isFlashOn) {
        await controller.setFlashMode(FlashMode.off);
      } else {
        await controller.setFlashMode(FlashMode.torch);
      }
      
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      print('Error toggling flash: $e');
    }
  }
  
  Future<void> _handleZoom(DragUpdateDetails details) async {
    final controller = ref.read(cameraControllerProvider).value;
    if (controller == null) return;
    
    // Determine if we're zooming in or out based on drag direction
    final verticalDrag = details.delta.dy;
    
    // Adjust the zoom level based on drag distance
    // Negative vertical drag (up) for zoom in, positive (down) for zoom out
    double newZoom = _currentZoom + (verticalDrag * -0.01);
    
    // Ensure zoom is within valid range
    newZoom = newZoom.clamp(1.0, _maxZoom);
    
    // Set the new zoom level
    await controller.setZoomLevel(newZoom);
    
    setState(() {
      _currentZoom = newZoom;
    });
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
  
  @override
  Widget build(BuildContext context) {
    final cameraAsync = ref.watch(cameraControllerProvider);
    final recordingState = ref.watch(recordingStateProvider);
    
    if (_permissionDenied) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Camera Access Required'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.camera_alt,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 24),
              const Text(
                'Camera and microphone access is required to record videos',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final result = await openAppSettings();
                  if (result) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: cameraAsync.when(
        data: (controller) {
          if (controller == null) {
            return const Center(
              child: Text(
                'No camera found',
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          
          // Get the maximum zoom level
          if (_maxZoom == 1.0) {
            controller.getMaxZoomLevel().then((value) {
              setState(() {
                _maxZoom = value;
              });
            });
          }
          
          return Stack(
            fit: StackFit.expand,
            children: [
              // Camera preview
              GestureDetector(
                onVerticalDragUpdate: _handleZoom,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: CameraPreview(controller),
                  ),
                ),
              ),
              
              // Top controls
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top row with close button and settings
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 30,
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  _isFlashOn ? Icons.flash_on : Icons.flash_off,
                                  color: Colors.white,
                                  size: 30,
                                ),
                                onPressed: _toggleFlash,
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.music_note,
                                  color: Colors.white,
                                  size: 30,
                                ),
                                onPressed: () {
                                  // TODO: Implement music selector
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      // Recording timer
                      if (recordingState == RecordingState.recording)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDuration(_recordingDuration),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      const Spacer(),
                      
                      // Zoom indicator
                      if (_currentZoom > 1.0)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${_currentZoom.toStringAsFixed(1)}x',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Bottom controls
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Effects and filters row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildEffectButton('Effects', Icons.auto_fix_high),
                            _buildEffectButton('Speed', Icons.speed),
                            _buildEffectButton('Filters', Icons.filter),
                            _buildEffectButton('Timer', Icons.timer),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Recording buttons row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Upload button
                            IconButton(
                              icon: const Icon(
                                Icons.photo_library,
                                color: Colors.white,
                                size: 30,
                              ),
                              onPressed: () {
                                // TODO: Implement gallery picker
                              },
                            ),
                            
                            // Record button
                            GestureDetector(
                              onTap: _toggleRecording,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 65,
                                    height: 65,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: recordingState == RecordingState.recording
                                          ? Colors.red
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            // Flip camera button
                            IconButton(
                              icon: const Icon(
                                Icons.flip_camera_ios,
                                color: Colors.white,
                                size: 30,
                              ),
                              onPressed: _toggleCamera,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Text(
            'Error initializing camera: $error',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
  
  Widget _buildEffectButton(String label, IconData icon) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}