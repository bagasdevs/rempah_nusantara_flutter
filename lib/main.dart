import 'package:flutter/material.dart';
import 'package:myapp/app_router.dart';
import 'package:myapp/services/api_service.dart';
import 'package:myapp/services/payment_service.dart';
import 'package:myapp/config/app_theme.dart';

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Rempah Nusantara',
      theme: AppTheme.lightTheme(),
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
