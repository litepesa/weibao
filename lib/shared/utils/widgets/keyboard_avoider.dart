import 'package:flutter/material.dart';

/// A widget that helps avoid the keyboard when it appears
class KeyboardAvoider extends StatelessWidget {
  final Widget child;
  final double? minHeight;
  final double focusOffset;
  final ScrollPhysics? physics;
  final EdgeInsets? padding;
  final bool autoScroll;

  const KeyboardAvoider({
    Key? key,
    required this.child,
    this.minHeight,
    this.focusOffset = 24.0,
    this.physics,
    this.padding,
    this.autoScroll = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final viewInsets = mediaQuery.viewInsets;
    final viewPadding = mediaQuery.viewPadding;
    final screenHeight = mediaQuery.size.height;
    
    // Determine content height
    final contentHeight = minHeight != null 
        ? (screenHeight > minHeight! ? screenHeight : minHeight!)
        : screenHeight;
    
    // Calculate bottom padding to avoid keyboard
    final bottomPadding = viewInsets.bottom > 0 
        ? viewInsets.bottom + focusOffset
        : viewPadding.bottom;
    
    final effectivePadding = padding?.copyWith(
      bottom: padding!.bottom + bottomPadding,
    ) ?? EdgeInsets.only(bottom: bottomPadding);
    
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Optional: Add scroll position tracking here
        return false;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: physics ?? const ClampingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: contentHeight - viewInsets.bottom,
              ),
              child: Padding(
                padding: effectivePadding,
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}