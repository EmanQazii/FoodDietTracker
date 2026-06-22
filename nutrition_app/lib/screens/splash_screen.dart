import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _buttonSlideAnimation;
  bool _isAutoLoggingIn = false;

  @override
  void initState() {
    super.initState();
    
    // Check auto login
    if (ApiService.token != null) {
      _isAutoLoggingIn = true;
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _buttonSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward().then((_) {
      if (_isAutoLoggingIn && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Warm cream to gold gradient — matches Figma exactly
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.gradientTop,
              AppColors.gradientMiddle,
              AppColors.gradientBottom,
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Logo Image (the food illustration)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Image.asset(
                      'assets/images/nut_logo.png',
                      width: 280,
                      height: 280,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // BiteBalance Brand Name
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'BiteBalance',
                    style: GoogleFonts.montserrat(
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandBrown,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const Spacer(flex: 1),

                // Buttons Section
                if (!_isAutoLoggingIn)
                  SlideTransition(
                    position: _buttonSlideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          // LOGIN Button
                          _buildButton(
                            label: 'LOGIN',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 18),

                          // SIGN UP Button
                          _buildButton(
                            label: 'SIGN UP',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignUpScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                if (_isAutoLoggingIn)
                  const CircularProgressIndicator(
                    color: AppColors.brandBrown,
                  ),

                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 160,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.sageGreen,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 3,
          shadowColor: AppColors.darkSage.withOpacity(0.4),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}