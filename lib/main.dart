import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'providers/quiz_provider.dart';
import 'utils/gemini_loader.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: Colors.transparent,
              body: MainBackgroundWrapper(
                child: Center(
                  child: GeminiLoader(size: 80),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: Colors.transparent,
              body: MainBackgroundWrapper(
                child: Center(
                  child: Text("Error initializing app: ${snapshot.error}", style: const TextStyle(color: Colors.white)),
                ),
              ),
            ),
          );
        }

        return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => QuizProvider()),
      ],
      child: MaterialApp(
        title: 'SL Exam Guide',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
            // Wraps every screen with the consistent gradient background
            home: const AuthWrapper(),
          ),
        );
      },
    );
  }
}

// The background gradient container used across the app
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

// Wrapper to check if user is logged in
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
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
        
        if (snapshot.hasData && snapshot.data != null) {
          return const MainBackgroundWrapper(child: HomeScreen());
        }
        
        return const MainBackgroundWrapper(child: LoginScreen());
      },
    );
  }
}