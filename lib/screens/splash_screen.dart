import 'package:flutter/material.dart';
import 'dart:async';
import 'login_screen.dart';
import '../services/storage_service.dart';
import '../models/user.dart';
import 'admin_dashboard.dart';
import 'sales_dashboard.dart';
import 'pengecer_dashboard.dart';
import 'manager_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimationTop;
  late Animation<Offset> _slideAnimationBottom;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkAutoLoginAndNavigate();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Animasi slide untuk teks atas
    _slideAnimationTop = Tween<Offset>(
      begin: const Offset(0, -0.8),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));

    // Animasi slide untuk teks bawah
    _slideAnimationBottom = Tween<Offset>(
      begin: const Offset(0, 0.8),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));

    // Animasi fade untuk semua elemen
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeIn),
      ),
    );

    // Animasi scale untuk logo (bounce effect)
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.elasticOut),
      ),
    );

    // Animasi progress bar
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();
  }

  Future<void> _checkAutoLoginAndNavigate() async {
    // Wait for animation to complete
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    try {
      // Check if user should be automatically logged in
      final isLoggedIn = await StorageService.isLoggedIn();
      final rememberMe = await StorageService.getRememberMe();
      
      if (isLoggedIn && rememberMe) {
        final savedUser = await StorageService.getSavedUserData();
        if (savedUser != null) {
          // Auto login user
          _navigateToUserDashboard(savedUser);
          return;
        }
      }
      
      // Navigate to login screen if no auto login
      _navigateToLogin();
    } catch (e) {
      print('Error checking auto login: $e');
      // Fallback to login screen
      _navigateToLogin();
    }
  }

  void _navigateToUserDashboard(User user) {
    Widget destination;
    switch (user.role) {
      case 'admin':
        destination = AdminDashboard(user: user);
        break;
      case 'sales':
        destination = SalesDashboard(user: user);
        break;
      case 'pengecer':
        destination = PengecerDashboard(user: user);
        break;
      case 'manager':
        destination = ManagerDashboard(user: user);
        break;
      default:
        destination = AdminDashboard(user: user);
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1e3c72), // Deep Blue
              Color(0xFF2a5298), // Royal Blue
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenHeight = constraints.maxHeight;
              final screenWidth = constraints.maxWidth;
              
              return Column(
                children: [
                  // Flexible spacer atas
                  Flexible(
                    flex: 2,
                    child: Container(),
                  ),
                  
                  // Teks "Usaha Distributor"
                  SlideTransition(
                    position: _slideAnimationTop,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Usaha Distributor',
                            style: TextStyle(
                              fontSize: screenWidth * 0.055,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withOpacity(0.9),
                              letterSpacing: 1.2,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Flexible spacer
                  Flexible(
                    flex: 1,
                    child: Container(),
                  ),

                  // Logo dengan animasi scale dan tanpa background
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: screenWidth * 0.4,
                          maxHeight: screenHeight * 0.25,
                        ),
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.contain,
                                color: Colors.transparent,
                                colorBlendMode: BlendMode.multiply,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Flexible spacer
                  Flexible(
                    flex: 1,
                    child: Container(),
                  ),

                  // Teks "KELUARGA SEHATI"
                  SlideTransition(
                    position: _slideAnimationBottom,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'KELUARGA SEHATI',
                            style: TextStyle(
                              fontSize: screenWidth * 0.065,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 2.5,
                              height: 1.1,
                              shadows: [
                                Shadow(
                                  blurRadius: 8.0,
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Flexible spacer yang mengisi sisa ruang
                  Flexible(
                    flex: 3,
                    child: Container(),
                  ),
                  
                  // Progress indicator dengan animasi
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                      child: Column(
                        children: [
                          FittedBox(
                            child: Text(
                              'Loading...',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: screenWidth * 0.035,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Container(
                            width: double.infinity,
                            height: 4,
                            constraints: BoxConstraints(
                              maxWidth: screenWidth * 0.6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, child) {
                                return FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: _progressAnimation.value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFffecd2),
                                          Color(0xFFfcb69f),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFfcb69f).withOpacity(0.5),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Bottom spacer
                  SizedBox(height: screenHeight * 0.05),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
    