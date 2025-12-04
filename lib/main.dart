import 'package:flutter/material.dart';
import 'package:myapp/app_router.dart';
import 'package:myapp/services/api_service.dart';
import 'package:myapp/services/payment_service.dart';
import 'package:myapp/config/app_theme.dart';
import 'package:myapp/utils/image_utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize API Service
  await ApiService.init();

  // Initialize Payment Service (Midtrans)
  await PaymentService.init(
    clientKey: 'SB-Mid-client-Y7EOICoq4eYEVyxz', // Sandbox client key
    isProduction: false,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Preload images for faster loading
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      await ImageUtils.preloadImages(context);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: AppColors.primary,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/images/Logo_Rempah_Nusantara.png',
                  width: 120,
                  height: 120,
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  'Memuat Rempah Nusantara...',
                  style: AppTextStyles.body1.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp.router(
      title: 'Rempah Nusantara',
      theme: AppTheme.lightTheme(),
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
