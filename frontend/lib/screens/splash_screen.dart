import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screen.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.linear,
    );
    _animController.forward();
    _progressController.forward();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    await Future.delayed(const Duration(seconds: 5));
    final prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('is_first_time') ?? true;

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (context, animation, secondaryAnimation) =>
            isFirstTime ? const OnboardingScreen() : const MainScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image with 85% opacity
          Positioned.fill(
            child: Opacity(
              opacity: 0.85,
              child: Transform.scale(
                scale: 1.05,
                child: Image.asset(
                  'assets/ui_background.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
          ),
          // Peach/Orange overlay at 85% opacity
          Positioned.fill(
            child: Container(color: const Color(0xFFF5E1C6).withAlpha(185)),
          ),
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Spacer(flex: 3),
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: SizedBox(
                    width: 190,
                    height: 190,
                    child: Image.asset(
                      'assets/logo_bgd.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Smart Ripeness & Health Detection",
                  style: TextStyle(
                    fontSize: 16,
                    color: Color.fromRGBO(0, 0, 0, 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(flex: 7),
                Padding(
                  padding: const EdgeInsets.fromLTRB(40.0, 0, 40.0, 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return LinearProgressIndicator(
                              minHeight: 8,
                              value: _progressAnimation.value,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFAD5607),
                              ),
                              backgroundColor: Colors.black12,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Loading...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
