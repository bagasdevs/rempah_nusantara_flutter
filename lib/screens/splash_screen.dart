import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    final session = Supabase.instance.client.auth.currentSession;
    if (mounted) {
      if (session != null) {
        // Jika ada sesi (sudah login), arahkan ke home
        context.go('/');
      } else {
        // Jika tidak ada sesi (belum login), arahkan ke login
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFBF9F4),
      body: Center(child: CircularProgressIndicator(color: Color(0xFF4D5D42))),
    );
  }
}
