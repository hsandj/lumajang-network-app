import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../config/app_config.dart';
import 'webview_screen.dart';
import 'offline_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
      ),
    );

    _animController.forward();
    _checkConnectivityAndNavigate();
  }

  Future<void> _checkConnectivityAndNavigate() async {
    // Delay minimum 2 detik agar splash screen terlihat profesional
    await Future.delayed(const Duration(milliseconds: 2200));

    final connectivityResult = await Connectivity().checkConnectivity();
    final bool isConnected = !connectivityResult.contains(ConnectivityResult.none);

    if (!mounted) return;

    if (isConnected) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const WebViewScreen(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OfflineScreen(
            onRetry: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SplashScreen()),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.backgroundDark,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // Logo Container dengan Router Icon sesuai Web
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppConfig.primaryColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppConfig.primaryColor.withOpacity(0.35),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.router_rounded,
                      size: 54,
                      color: AppConfig.backgroundDark,
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  // App Title
                  const Text(
                    AppConfig.appName,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: AppConfig.textLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Subtitle
                  Text(
                    'ISP Billing & Operational Dashboard',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppConfig.textMuted,
                      letterSpacing: 0.2,
                    ),
                  ),

                  const Spacer(),

                  // Loading Indicator
                  const SpinKitThreeBounce(
                    color: AppConfig.primaryColor,
                    size: 26.0,
                  ),
                  const SizedBox(height: 20),
                  
                  // Copyright Footer
                  Text(
                    'PT. Reload Media Telematika',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppConfig.textMuted.withOpacity(0.6),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
