// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/firebase_options.dart';
import 'config/app_theme.dart';
import 'screens/admin_page.dart';
import 'screens/assign_report.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization error: $e');
  }
  
  try {
    await dotenv.load(fileName: "assets/.env");
    print('✅ Environment variables loaded');
  } catch (e) {
    print('⚠️  No .env file found (this is optional)');
  }
  
  runApp(const VociferApp());
}

class VociferApp extends StatelessWidget {
  const VociferApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vocifer - Emergency Response System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      
      home: const SplashScreen(),
      
      routes: {
        '/admin': (context) => const AdminPage(),
        '/assign': (context) => const AssignReportScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  void _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/admin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shield_outlined,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'VOCIFER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            
            const SizedBox(height: 8),
            
            const Text(
              'Emergency Response System',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
            
            const SizedBox(height: 48),
            
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
