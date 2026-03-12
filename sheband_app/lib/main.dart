import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // TODO: Replace with your actual Supabase URL and Anon Key
  await Supabase.initialize(
    url: 'https://pcztfcefxqxnfginjsbb.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBjenRmY2VmeHF4bmZnaW5qc2JiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMzMTY0MjksImV4cCI6MjA4ODg5MjQyOX0.hJ73pSepoyLbdfKMAzpknh3Uix2CHTHeOTOYvV8XkkQ',
  );

  runApp(const SheBandApp());
}

class SheBandApp extends StatelessWidget {
  const SheBandApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SheBand',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1E1E1E)),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pinkAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}