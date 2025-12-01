import 'package:flutter/material.dart';
import 'package:myapp/app_router.dart';
import 'package:myapp/services/api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize API Service
  await ApiService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Rempah Nusantara',
      theme: ThemeData(primarySwatch: Colors.blue),
      routerConfig: router,
    );
  }
}
