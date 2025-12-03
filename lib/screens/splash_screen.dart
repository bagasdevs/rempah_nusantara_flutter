import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/services/api_service.dart';
import 'package:myapp/config/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Tunggu sebentar untuk menampilkan splash, lalu redirect
    Future.delayed(const Duration(seconds: 2), _redirect);
  }

  void _redirect() {
    // Cek apakah ada sesi pengguna yang aktif
    if (mounted) {
      if (ApiService.isAuthenticated) {
        // Jika ada sesi (sudah login), arahkan ke home
        context.go('/');
      } else {
        // Jika tidak ada sesi (belum login), arahkan ke onboarding
        context.go('/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Image.asset(
                    'assets/images/Logo_Rempah_Nusantara.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.paddingXL),

            // App Name
            const Text(
              'Rempah Nusantara',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textWhite,
              ),
            ),
            const SizedBox(height: AppSizes.paddingSM),

            // Tagline
            const Text(
              'Rasa Tradisi, Kualitas Terjaga',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textWhite,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSizes.paddingXL),

            // Loading Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
            ),
          ],
        ),
      ),
    );
  }
}
