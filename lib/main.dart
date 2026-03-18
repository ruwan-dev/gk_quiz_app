import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart'; // Added for kIsWeb
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'providers/quiz_provider.dart';
import 'utils/gemini_loader.dart';

void main() async {
  // Ensure Flutter is ready
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase before running the app
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // If on web, handle potential persistence issues in Incognito
    if (kIsWeb) {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    }
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
    // We continue to runApp so the user might see an error UI instead of a hang
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => QuizProvider()),
      ],
      child: MaterialApp(
        title: 'SL Exam Guide',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthWrapper(),
      ),
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
            AppTheme.color1,
            AppTheme.color2,
            AppTheme.color3,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: child,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If connection is still waiting, show loader
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MainBackgroundWrapper(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: GeminiLoader(size: 80),
              ),
            ),
          );
        }
        
        // If logged in, go to Home
        if (snapshot.hasData && snapshot.data != null) {
          return const MainBackgroundWrapper(child: HomeScreen());
        }
        
        // Otherwise, show Login
        return const MainBackgroundWrapper(child: LoginScreen());
      },
    );
  }
}