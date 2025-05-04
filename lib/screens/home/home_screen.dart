import 'package:flutter/material.dart';
import 'package:weibao/screens/home/feed_screen.dart';
import 'package:weibao/screens/home/discover_screen.dart';
import 'package:weibao/screens/video/video_recording_screen.dart';
import 'package:weibao/screens/home/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const FeedScreen(),
    const DiscoverScreen(),
    const SizedBox(), // Placeholder for the create button
    const SizedBox(), // Placeholder for notifications (can be implemented later)
    const ProfileScreen(),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentIndex == 2 
          ? const VideoRecordingScreen() // Show the recording screen when the create button is pressed
          : _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // If the create button is tapped, navigate to the recording screen
          if (index == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const VideoRecordingScreen(),
              ),
            );
            return;
          }
          
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: _buildCreateButton(),
            label: 'Create',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.inbox),
            label: 'Inbox',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
  
  Widget _buildCreateButton() {
    return Container(
      width: 48,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF0050), Color(0xFF00F2EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(
        Icons.add,
        color: Colors.black,
        size: 20,
      ),
    );
  }
}