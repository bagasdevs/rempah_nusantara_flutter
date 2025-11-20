
import 'package:flutter/material.dart';
import 'package:myapp/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://aneqtzkrryanihrkonja.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFuZXF0emtycnlhbmlocmtvbmphIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM1MjkyNjUsImV4cCI6MjA3OTEwNTI2NX0._1zsjoF1veaxYW7VgTf-BfNxOMjJv9Yqb5vv-3KkT-A',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routerConfig: router,
    );
  }
}
