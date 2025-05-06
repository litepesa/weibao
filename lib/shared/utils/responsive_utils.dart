import 'package:flutter/material.dart';

enum DeviceType {
  mobile,
  tablet,
  desktop,
}

class ResponsiveUtils {
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 600) {
      return DeviceType.mobile;
    } else if (width < 1200) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }
  
  static double getResponsiveValue({
    required BuildContext context,
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile * 1.25;
      case DeviceType.desktop:
        return desktop ?? mobile * 1.5;
    }
  }
  
  static double getResponsiveFontSize(
    BuildContext context,
    double size, {
    double min = 12.0,
    double max = 30.0,
  }) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    
    // Using smaller of width/height to ensure text is readable on all devices
    final scaleValue = (width < height ? width : height) / 375; // Base on iPhone 8 size
    final scaledSize = size * scaleValue;
    
    return scaledSize.clamp(min, max);
  }
  
  static EdgeInsets getResponsiveScreenPadding(BuildContext context) {
    final deviceType = getDeviceType(context);
    final width = MediaQuery.of(context).size.width;
    
    switch (deviceType) {
      case DeviceType.mobile:
        return EdgeInsets.symmetric(horizontal: width * 0.05); // 5% padding
      case DeviceType.tablet:
        return EdgeInsets.symmetric(horizontal: width * 0.1); // 10% padding
      case DeviceType.desktop:
        // Fixed-width centered content area
        return EdgeInsets.symmetric(horizontal: (width - 1000) / 2);
    }
  }
  
  static double getResponsiveHeight(
    BuildContext context,
    double height, {
    double min = 0.0,
    double? max,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final percentage = height / 812; // Based on iPhone 13 height
    final responsive = screenHeight * percentage;
    
    if (max != null) {
      return responsive.clamp(min, max);
    }
    
    return responsive >= min ? responsive : min;
  }
  
  static double getResponsiveWidth(
    BuildContext context,
    double width, {
    double min = 0.0,
    double? max,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final percentage = width / 375; // Based on iPhone 8 width
    final responsive = screenWidth * percentage;
    
    if (max != null) {
      return responsive.clamp(min, max);
    }
    
    return responsive >= min ? responsive : min;
  }
}

/// A widget that builds different layouts based on screen size
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext, DeviceType) builder;

  const ResponsiveBuilder({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveUtils.getDeviceType(context);
    return builder(context, deviceType);
  }
}

/// Extension methods for BuildContext to access responsive utilities
extension ResponsiveContext on BuildContext {
  DeviceType get deviceType => ResponsiveUtils.getDeviceType(this);
  
  bool get isMobile => deviceType == DeviceType.mobile;
  bool get isTablet => deviceType == DeviceType.tablet;
  bool get isDesktop => deviceType == DeviceType.desktop;
  
  double responsiveValue({
    required double mobile,
    double? tablet,
    double? desktop,
  }) => ResponsiveUtils.getResponsiveValue(
    context: this,
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
  );
  
  double responsiveFontSize(
    double size, {
    double min = 12.0,
    double max = 30.0,
  }) => ResponsiveUtils.getResponsiveFontSize(this, size, min: min, max: max);
  
  EdgeInsets get screenPadding => ResponsiveUtils.getResponsiveScreenPadding(this);
  
  double responsiveHeight(
    double height, {
    double min = 0.0,
    double? max,
  }) => ResponsiveUtils.getResponsiveHeight(this, height, min: min, max: max);
  
  double responsiveWidth(
    double width, {
    double min = 0.0,
    double? max,
  }) => ResponsiveUtils.getResponsiveWidth(this, width, min: min, max: max);
}