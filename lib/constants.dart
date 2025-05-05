import 'package:flutter/material.dart';

class Constants {
  // screens routes
  static const String landingScreen = '/landingScreen';
  static const String loginScreen = '/loginScreen';
  static const String otpScreen = '/otpScreen';
  static const String userInformationScreen = '/userInformationScreen';
  static const String homeScreen = '/homeScreen';
  static const String chatScreen = '/chatScreen';
  static const String contactProfileScreen = '/contactProfileScreen';
  static const String myProfileScreen = '/myProfileScreen'; 
  static const String editProfileScreen = '/editProfileScreen';
  static const String searchScreen = '/searchScreen';
  static const String contactsScreen = '/contactsScreen';
  static const String addContactScreen = '/addContactScreen';
  static const String settingsScreen = '/settingsScreen';
  static const String aboutScreen = '/aboutScreen';
  static const String privacyPolicyScreen = '/privacyPolicyScreen';
  static const String termsAndConditionsScreen = '/termsAndConditionsScreen';
  static const String groupSettingsScreen = '/groupSettingsScreen';
  static const String groupInformationScreen = '/groupInformationScreen';
  static const String groupsScreen = '/groupsScreen';
  static const String createGroupScreen = '/createGroupScreen';
  static const String blockedContactsScreen = '/blockedContactsScreen';
  
  // Status feature routes
  static const String statusOverviewScreen = '/statusOverviewScreen';
  static const String createStatusScreen = '/createStatusScreen';
  static const String myStatusesScreen = '/myStatusesScreen';
  static const String statusViewerScreen = '/statusViewerScreen';
  static const String mediaViewScreen = '/mediaViewScreen';
  static const String statusDetailScreen = '/statusDetailScreen';
  
  // Collection names for Status
  static const String statuses = 'statuses';
  static const String statusPosts = 'status_posts';
  static const String statusComments = 'status_comments';
  static const String statusReactions = 'status_reactions';
  static const String statusFiles = 'statusFiles';
  static const String statusId = 'statusId';
  static const String statusType = 'statusType';
  static const String statusViewCount = 'viewCount';
  
  // User-related constants
  static const String uid = 'uid';
  static const String name = 'name';
  static const String phoneNumber = 'phoneNumber';
  static const String image = 'image';
  static const String token = 'token';
  static const String aboutMe = 'aboutMe';
  static const String createdAt = 'createdAt';
  static const String contactsUIDs = 'contactsUIDs';
  static const String blockedUIDs = 'blockedUIDs';

  static const String verificationId = 'verificationId';

  static const String users = 'users';
  static const String userImages = 'userImages';
  static const String userModel = 'userModel';
  
  static const String contactName = 'contactName';
  static const String contactImage = 'contactImage';
  static const String groupId = 'groupId';

  static const String senderUID = 'senderUID';
  static const String senderName = 'senderName';
  static const String senderImage = 'senderImage';
  static const String contactUID = 'contactUID';
  static const String message = 'message';
  static const String messageType = 'messageType';
  static const String timeSent = 'timeSent';
  static const String messageId = 'messageId';
  static const String repliedMessage = 'repliedMessage';
  static const String repliedTo = 'repliedTo';
  static const String repliedMessageType = 'repliedMessageType';
  static const String isMe = 'isMe';
  static const String reactions = 'reactions';
  static const String deletedBy = 'deletedBy';

  static const String lastMessage = 'lastMessage';
  static const String chats = 'chats';
  static const String messages = 'messages';
  static const String groups = 'groups';
  static const String chatFiles = 'chatFiles';

  static const String private = 'private';
  static const String public = 'public';

  // App theme/branding
  static const Color primaryColor = Color(0xFF07C160); // WeiBao green
  static const Color secondaryColor = Color(0xFF1A73E8); // Accent blue
  static const Color backgroundLight = Color(0xFFF7F7F7);
  static const Color backgroundDark = Color(0xFF0F0F0F);
  static const Color textDark = Color(0xFF181818);
  static const Color textMedium = Color(0xFF888888);
  static const Color textLight = Color(0xFFB2B2B2);
  
  // Privacy messages
  static const String privacyManifesto = 'WeiBao is built with privacy at its core. Your conversations, status, and behavior are never tracked.';
  static const String privacyFeatures = 'No read receipts, no typing indicators, no online status tracking - your privacy is our priority.';
  static const String securityInfo = 'End-to-end encryption for all messages. Your data belongs to you alone.';
}