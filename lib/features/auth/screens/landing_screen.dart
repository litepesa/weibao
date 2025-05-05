import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

// Constants
class AppConstants {
  static const String homeScreen = '/home';
  static const String loginScreen = '/login';
}

// Authentication Provider using Riverpod
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// Auth State
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;

  AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState(isLoading: true));

  Future<void> checkAuthenticationState() async {
    // Simulate authentication check
    await Future.delayed(const Duration(seconds: 2));
    
    // Set authentication status (this would be your actual auth check logic)
    state = state.copyWith(isAuthenticated: false, isLoading: false);
  }
}

class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _logoScaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeInOut),
      ),
    );
    
    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );
    
    _animationController.forward();
    
    // Check authentication status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).checkAuthenticationState();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void navigateToLogin() {
    Navigator.pushReplacementNamed(context, AppConstants.loginScreen);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authState = ref.watch(authProvider);
    
    // App color scheme
    const wechatGreen = Color(0xFF07C160);
    const darkBackground = Color(0xFF0F0F0F);
    
    if (authState.isLoading) {
      return Scaffold(
        backgroundColor: darkBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Code-generated Logo while loading
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: const AppLogo(size: 80),
                  );
                },
              ),
              const SizedBox(height: 30),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(wechatGreen),
              ),
            ],
          ),
        ),
      );
    }
    
    // Redirect if already authenticated
    if (authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AppConstants.homeScreen);
      });
    }

    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const Spacer(flex: 2),
                
                // Code-generated App Logo
                ScaleTransition(
                  scale: _logoScaleAnimation,
                  child: const AppLogo(size: 100),
                ),
                
                const SizedBox(height: 24),
                
                // App Name with elegant styling
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Subtle green accent line
                    Positioned(
                      bottom: 0,
                      child: Container(
                        height: 3,
                        width: 40,
                        decoration: BoxDecoration(
                          color: wechatGreen,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    
                    // Clean, minimalist logo text
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Wei',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                              letterSpacing: -1.0,
                            ),
                          ),
                          TextSpan(
                            text: 'Bao',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                              color: wechatGreen,
                              letterSpacing: -1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Tagline
                Text(
                  'Connect globally with ease',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                
                const Spacer(flex: 1),
                
                // Animated Chat Bubbles (replacing Lottie)
                const AnimatedChatBubbles(),
                
                const Spacer(flex: 1),
                
                // Features list
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFeatureItem(Icons.message_outlined, "Chat"),
                    const SizedBox(width: 32),
                    _buildFeatureItem(Icons.groups_outlined, "Groups"),
                    const SizedBox(width: 32),
                    _buildFeatureItem(Icons.video_call_outlined, "Video"),
                  ],
                ),
                
                const Spacer(flex: 1),
                
                // Get Started Button
                ElevatedButton(
                  onPressed: navigateToLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: wechatGreen,
                    foregroundColor: Colors.white,
                    minimumSize: Size(size.width, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Terms & Privacy text
                Text(
                  'By continuing, you accept our Terms & Privacy Policy',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeatureItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF07C160).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF07C160),
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// Code-generated Logo Widget
class AppLogo extends StatelessWidget {
  final double size;
  
  const AppLogo({
    Key? key,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      child: CustomPaint(
        size: Size(size * 0.8, size * 0.8),
        painter: LogoPainter(),
      ),
    );
  }
}

// Custom Painter for WeiBao Logo
class LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2.2;
    
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    
    // Top left quadrant - Green
    paint.color = const Color(0xFF07C160);
    canvas.drawCircle(
      Offset(center.dx - radius / 2, center.dy - radius / 2),
      radius / 2,
      paint,
    );
    
    // Top right quadrant - Red
    paint.color = const Color(0xFFE74C3C);
    canvas.drawCircle(
      Offset(center.dx + radius / 2, center.dy - radius / 2),
      radius / 2,
      paint,
    );
    
    // Bottom left quadrant - Yellow
    paint.color = const Color(0xFFF1C40F);
    canvas.drawCircle(
      Offset(center.dx - radius / 2, center.dy + radius / 2),
      radius / 2,
      paint,
    );
    
    // Bottom right quadrant - Blue
    paint.color = const Color(0xFF3498DB);
    canvas.drawCircle(
      Offset(center.dx + radius / 2, center.dy + radius / 2),
      radius / 2,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Animated Chat Bubbles Widget to replace Lottie animation
class AnimatedChatBubbles extends StatefulWidget {
  const AnimatedChatBubbles({Key? key}) : super(key: key);

  @override
  State<AnimatedChatBubbles> createState() => _AnimatedChatBubblesState();
}

class _AnimatedChatBubblesState extends State<AnimatedChatBubbles>
    with TickerProviderStateMixin {
  late final AnimationController _controller1;
  late final AnimationController _controller2;
  late final AnimationController _controller3;

  late final Animation<double> _animation1;
  late final Animation<double> _animation2;
  late final Animation<double> _animation3;

  @override
  void initState() {
    super.initState();

    // First bubble animation
    _controller1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _animation1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller1, curve: Curves.easeInOut),
    );

    // Second bubble animation (with delay)
    _controller2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    _animation2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller2, curve: Curves.easeInOut),
    );
    
    Future.delayed(const Duration(milliseconds: 400), () {
      _controller2.repeat(reverse: true);
    });

    // Third bubble animation (with longer delay)
    _controller3 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    
    _animation3 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller3, curve: Curves.easeInOut),
    );
    
    Future.delayed(const Duration(milliseconds: 800), () {
      _controller3.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return SizedBox(
      height: size.height * 0.35,
      width: size.width,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Left bubble
          Positioned(
            left: size.width * 0.05,
            child: AnimatedBuilder(
              animation: _animation1,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -10 * _animation1.value),
                  child: Opacity(
                    opacity: 0.7 + (0.3 * _animation1.value),
                    child: child,
                  ),
                );
              },
              child: _buildChatBubble(
                size.width * 0.35,
                alignment: Alignment.centerLeft,
                color: const Color(0xFF07C160).withOpacity(0.9),
              ),
            ),
          ),
          
          // Right bubble
          Positioned(
            right: size.width * 0.05,
            bottom: size.height * 0.05,
            child: AnimatedBuilder(
              animation: _animation2,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -8 * _animation2.value),
                  child: Opacity(
                    opacity: 0.7 + (0.3 * _animation2.value),
                    child: child,
                  ),
                );
              },
              child: _buildChatBubble(
                size.width * 0.45,
                alignment: Alignment.centerRight,
                color: Colors.white.withOpacity(0.15),
              ),
            ),
          ),
          
          // Center bubble
          Positioned(
            top: size.height * 0.03,
            child: AnimatedBuilder(
              animation: _animation3,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -12 * _animation3.value),
                  child: Opacity(
                    opacity: 0.7 + (0.3 * _animation3.value),
                    child: child,
                  ),
                );
              },
              child: _buildChatBubble(
                size.width * 0.4,
                alignment: Alignment.topCenter, 
                color: const Color(0xFF3498DB).withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildChatBubble(double width, {
    required Alignment alignment,
    required Color color,
  }) {
    final bool isLeftAligned = alignment == Alignment.centerLeft;
    
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20).copyWith(
          bottomLeft: isLeftAligned ? const Radius.circular(0) : null,
          bottomRight: !isLeftAligned ? const Radius.circular(0) : null,
        ),
      ),
      child: Column(
        crossAxisAlignment: isLeftAligned 
            ? CrossAxisAlignment.start 
            : CrossAxisAlignment.end,
        children: [
          Container(
            height: 10,
            width: width * 0.7,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 10,
            width: width * 0.9,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 10,
            width: width * 0.5,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }
}