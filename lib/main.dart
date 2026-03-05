import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gk_quiz_app/screens/home_screen.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/quiz_provider.dart';

import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => QuizProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Title eka methanin ain kala
      theme: AppTheme.darkTheme, 
      home: const AuthGate(), 
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F172A),
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        if (snapshot.hasData) {
          return  MainBackgroundWrapper(child: HomeScreen());
        }

        return  MainBackgroundWrapper(child: LoginScreen());
      },
    );
  }
}

class MainBackgroundWrapper extends StatelessWidget {
  final Widget child;
  const MainBackgroundWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A), 
            Color(0xFF020617), 
          ],
        ),
      ),
      child: child,
    );
  }
}