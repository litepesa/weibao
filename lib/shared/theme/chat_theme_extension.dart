import 'package:flutter/material.dart';

/// Chat-specific theme extension for customizing the chat UI
class ChatThemeExtension extends ThemeExtension<ChatThemeExtension> {
  final Color chatBackgroundColor;
  final Color senderBubbleColor;
  final Color receiverBubbleColor;
  final Color senderTextColor;
  final Color receiverTextColor;
  final Color systemMessageColor;
  final Color systemMessageTextColor;
  final Color timestampColor;
  final Color inputBackgroundColor;
  final BorderRadius senderBubbleRadius;
  final BorderRadius receiverBubbleRadius;

  const ChatThemeExtension({
    required this.chatBackgroundColor,
    required this.senderBubbleColor,
    required this.receiverBubbleColor,
    required this.senderTextColor,
    required this.receiverTextColor,
    required this.systemMessageColor,
    required this.systemMessageTextColor,
    required this.timestampColor,
    required this.inputBackgroundColor,
    required this.senderBubbleRadius,
    required this.receiverBubbleRadius,
  });

  // Default chat theme based on dark theme
  static ChatThemeExtension defaultTheme = const ChatThemeExtension(
    chatBackgroundColor: Color(0xFF30302E),      // Dark background
    senderBubbleColor: Color(0xFF066C38),        // Dark green sender bubble
    receiverBubbleColor: Color(0xFF262624),      // Dark receiver bubble
    senderTextColor: Colors.white,               // White text
    receiverTextColor: Colors.white,             // White text
    systemMessageColor: Color(0xFF3A3A38),       // Dark system message background
    systemMessageTextColor: Color(0xFFBBBBBB),   // Secondary text color
    timestampColor: Color(0xFF999999),           // Tertiary text color
    inputBackgroundColor: Color(0xFF3A3A38),     // Input background color
    senderBubbleRadius: BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
      bottomLeft: Radius.circular(16),
      bottomRight: Radius.circular(4),
    ),
    receiverBubbleRadius: BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
      bottomLeft: Radius.circular(4),
      bottomRight: Radius.circular(16),
    ),
  );

  @override
  ThemeExtension<ChatThemeExtension> copyWith({
    Color? chatBackgroundColor,
    Color? senderBubbleColor,
    Color? receiverBubbleColor,
    Color? senderTextColor,
    Color? receiverTextColor,
    Color? systemMessageColor,
    Color? systemMessageTextColor,
    Color? timestampColor,
    Color? inputBackgroundColor,
    BorderRadius? senderBubbleRadius,
    BorderRadius? receiverBubbleRadius,
  }) {
    return ChatThemeExtension(
      chatBackgroundColor: chatBackgroundColor ?? this.chatBackgroundColor,
      senderBubbleColor: senderBubbleColor ?? this.senderBubbleColor,
      receiverBubbleColor: receiverBubbleColor ?? this.receiverBubbleColor,
      senderTextColor: senderTextColor ?? this.senderTextColor,
      receiverTextColor: receiverTextColor ?? this.receiverTextColor,
      systemMessageColor: systemMessageColor ?? this.systemMessageColor,
      systemMessageTextColor: systemMessageTextColor ?? this.systemMessageTextColor,
      timestampColor: timestampColor ?? this.timestampColor,
      inputBackgroundColor: inputBackgroundColor ?? this.inputBackgroundColor,
      senderBubbleRadius: senderBubbleRadius ?? this.senderBubbleRadius,
      receiverBubbleRadius: receiverBubbleRadius ?? this.receiverBubbleRadius,
    );
  }

  @override
  ThemeExtension<ChatThemeExtension> lerp(
      covariant ThemeExtension<ChatThemeExtension>? other, double t) {
    if (other is! ChatThemeExtension) return this;
    
    return ChatThemeExtension(
      chatBackgroundColor: Color.lerp(chatBackgroundColor, other.chatBackgroundColor, t)!,
      senderBubbleColor: Color.lerp(senderBubbleColor, other.senderBubbleColor, t)!,
      receiverBubbleColor: Color.lerp(receiverBubbleColor, other.receiverBubbleColor, t)!,
      senderTextColor: Color.lerp(senderTextColor, other.senderTextColor, t)!,
      receiverTextColor: Color.lerp(receiverTextColor, other.receiverTextColor, t)!,
      systemMessageColor: Color.lerp(systemMessageColor, other.systemMessageColor, t)!,
      systemMessageTextColor: Color.lerp(systemMessageTextColor, other.systemMessageTextColor, t)!,
      timestampColor: Color.lerp(timestampColor, other.timestampColor, t)!,
      inputBackgroundColor: Color.lerp(inputBackgroundColor, other.inputBackgroundColor, t)!,
      senderBubbleRadius: BorderRadius.lerp(senderBubbleRadius, other.senderBubbleRadius, t)!,
      receiverBubbleRadius: BorderRadius.lerp(receiverBubbleRadius, other.receiverBubbleRadius, t)!,
    );
  }
}

/// Extension method to easily access the chat theme from BuildContext
extension ChatThemeContext on BuildContext {
  ChatThemeExtension get chatTheme {
    return Theme.of(this).extension<ChatThemeExtension>() ?? 
           ChatThemeExtension.defaultTheme;
  }
}