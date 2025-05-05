import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weibao/shared/theme/theme_constants.dart';
import 'package:weibao/shared/components/modern_bottom_nav.dart';
import 'package:weibao/shared/components/custom_post_button.dart';

final selectedTabProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const List<String> _tabTitles = [
    'Home',
    'Chats',
    'Post',
    'Cart',
    'Profile',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedTabProvider);
    
    // Determine if app bar should be shown (hidden for home and cart tabs)
    final bool showAppBar = selectedIndex != 0 && selectedIndex != 3;
    
    // Determine background color based on selected tab
    Color backgroundColor = Theme.of(context).scaffoldBackgroundColor; // default color
    if (selectedIndex == 0) {
      backgroundColor = Colors.black;
    } else if (selectedIndex == 3) {
      backgroundColor = Colors.white;
    }

    return Scaffold(
      appBar: showAppBar ? AppBar(
        title: Text(
          _tabTitles[selectedIndex],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              _showDevelopmentMessage(context, 'Notifications feature');
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showDevelopmentMessage(context, 'Search feature');
            },
          ),
        ],
      ) : null,
      
      backgroundColor: backgroundColor,
      
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForIndex(selectedIndex),
              size: 80,
              color: selectedIndex == 0 ? Colors.white : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              _tabTitles[selectedIndex],
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: selectedIndex == 0 ? Colors.white : null,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'This section is under development',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: selectedIndex == 0 
                    ? Colors.white70 
                    : Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
      
      bottomNavigationBar: ModernBottomNavBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          ref.read(selectedTabProvider.notifier).state = index;
          _showDevelopmentMessage(context, '${_tabTitles[index]} tab');
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: CustomPostButton(isActive: false),
            activeIcon: CustomPostButton(isActive: true),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
  
  void _showDevelopmentMessage(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is under development'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0: return Icons.home;
      case 1: return Icons.chat_bubble;
      case 2: return Icons.add_box;
      case 3: return Icons.shopping_cart;
      case 4: return Icons.person;
      default: return Icons.home;
    }
  }
}