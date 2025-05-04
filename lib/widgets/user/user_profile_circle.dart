import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:weibao/screens/home/profile_screen.dart';

class UserProfileCircle extends StatelessWidget {
  final String photoURL;
  final String userId;
  final double size;
  final bool showBorder;
  
  const UserProfileCircle({
    super.key,
    required this.photoURL,
    required this.userId,
    this.size = 40,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProfileScreen(userId: userId),
          ),
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: showBorder
              ? Border.all(
                  color: Colors.white,
                  width: 1,
                )
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: photoURL.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: photoURL,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => _buildDefaultAvatar(),
                )
              : _buildDefaultAvatar(),
        ),
      ),
    );
  }
  
  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.grey[300],
      child: Icon(
        Icons.person,
        size: size * 0.6,
        color: Colors.grey[600],
      ),
    );
  }
}