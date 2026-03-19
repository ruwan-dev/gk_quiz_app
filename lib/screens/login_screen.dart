import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:url_launcher/url_launcher.dart'; 
import '../services/auth_service.dart';
import 'home_screen.dart'; 
import '../utils/gemini_loader.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final AuthService _auth = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true; 
  bool _isLoading = false;
  late AnimationController _brandingController;

  @override
  void initState() {
    super.initState();
    _brandingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60), 
    )..repeat();
  }

  @override
  void dispose() {
    _brandingController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) _showError("Could not open the link.");
    }
  }

  void _submit() async {
    FocusScope.of(context).unfocus(); 
    setState(() => _isLoading = true);
    
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Please fill all fields");
      setState(() => _isLoading = false);
      return;
    }

    try {
      if (_isLogin) {
        final user = await _auth.signInWithEmail(email, password);
        if (user != null && mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
        }
      } else {
        final user = await _auth.registerWithEmail(email, password);
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'email': email, 'name': email.split('@')[0], 'totalScore': 0, 'isPremium': false,
            'avatarUrl': '', 'isDeactivated': false, 'createdAt': FieldValue.serverTimestamp(),
          });
          if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
        }
      }
    } on FirebaseAuthException catch (e) {
      String userMessage = "Invalid Email or Password. Please try again.";
      if (e.code == 'email-already-in-use') {
        userMessage = "This email is already registered. Please Sign In.";
      }
      _showError(userMessage);
    } catch (e) {
      _showError("Something went wrong. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _signInWithGoogle() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      final user = await _auth.signInWithGoogle();
      if (user != null && mounted) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'email': user.email ?? '', 'name': user.displayName ?? (user.email != null ? user.email!.split('@')[0] : 'User'),
            'totalScore': 0, 'isPremium': false, 'avatarUrl': user.photoURL ?? '', 'isDeactivated': false, 'createdAt': FieldValue.serverTimestamp(),
          });
        }
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(), 
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          children: [
                            const Spacer(flex: 2), 
                            
                            // 💎 AstroQuiz Card
                            Container(
                              padding: const EdgeInsets.all(24.0),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 💎 Circular Logo
                                  Center(
                                    child: Container(
                                      width: 85, height: 85,
                                      padding: const EdgeInsets.all(3), 
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.4), width: 2),
                                        boxShadow: [BoxShadow(color: const Color(0xFF38BDF8).withOpacity(0.1), blurRadius: 15, spreadRadius: 2)]
                                      ),
                                      child: ClipOval(
                                        child: Image.asset('assets/logo.png', fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.rocket_launch_rounded, size: 50, color: Color(0xFF38BDF8))),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(_isLogin ? "Hello Future Leader !" : "Join to the Game !", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                                  const SizedBox(height: 8),
                                  Text(_isLogin ? "Welcome back to AstroQuiz !" : "Start your journey to the stars", textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.white38)),
                                  const SizedBox(height: 30),
                                  
                                  _buildTextField(controller: _emailController, label: "Email", icon: Icons.email_outlined),
                                  const SizedBox(height: 20),
                                  _buildTextField(controller: _passwordController, label: "Password", icon: Icons.lock_outline, isObscure: true),
                                  
                                  if (_isLogin)
                                    Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => _showForgotPasswordDialog(context), child: const Text("Forgot Password?", style: TextStyle(color: Colors.white70))))
                                  else
                                    const SizedBox(height: 15),
                                  
                                  const SizedBox(height: 15),
                                  SizedBox(
                                    width: double.infinity, height: 55,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _submit,
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                                      child: Text(_isLogin ? "Sign In" : "Register", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  
                                  Row(
                                    children: [
                                      Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
                                      const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("OR", style: TextStyle(color: Colors.white54, fontSize: 12))),
                                      Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
                                    ],
                                  ),
                                  const SizedBox(height: 15),

                                  // 🚀 Google Login with Badge
                                  SizedBox(
                                    width: double.infinity, height: 55,
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withOpacity(0.1)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                                      onPressed: _isLoading ? null : _signInWithGoogle,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(7),
                                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(10)),
                                            child: Image.asset('assets/google_logo.png', height: 18, fit: BoxFit.contain),
                                          ),
                                          const SizedBox(width: 15),
                                          const Text("Continue with Google", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextButton(
                                    onPressed: () => setState(() => _isLogin = !_isLogin),
                                    child: Text(_isLogin ? "Don't have an account? Register" : "Already have an account? Sign In", style: const TextStyle(color: Color(0xFF38BDF8))),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(flex: 3), 
                            if (!isKeyboardVisible) _buildFooter(),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) Positioned.fill(child: Container(color: Colors.black.withOpacity(0.7), child: const Center(child: GeminiLoader(size: 80)))),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => _launchURL("https://slxamguide.online/privacy.html"),
              child: const Text("Privacy Policy", style: TextStyle(color: Colors.white54, fontSize: 12, decoration: TextDecoration.underline)),
            ),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text("•", style: TextStyle(color: Colors.white54))),
            GestureDetector(
              onTap: () => _launchURL("https://slxamguide.online/terms.html"),
              child: const Text("Terms of Service", style: TextStyle(color: Colors.white54, fontSize: 12, decoration: TextDecoration.underline)),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text("POWERED BY", style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4), 
        AnimatedBuilder(
          animation: _brandingController,
          builder: (context, child) => ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: const [Color(0xFF9C27B0), Color(0xFF00ACC1), Color(0xFF38BDF8), Color(0xFFE040FB), Color(0xFF9C27B0)],
              stops: [0.0, (_brandingController.value - 0.2).clamp(0.0, 1.0), _brandingController.value, (_brandingController.value + 0.2).clamp(0.0, 1.0), 1.0],
            ).createShader(bounds),
            child: const Text("OrbitView Innovations", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 3)),
          ),
        ),
        const SizedBox(height: 4), 
        Text("© 2026 ALL RIGHTS RESERVED", style: TextStyle(color: Colors.white.withOpacity(0.1), fontSize: 8, letterSpacing: 1.2)),
      ],
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, bool isObscure = false}) {
    return TextField(
      controller: controller, obscureText: isObscure, style: const TextStyle(color: Colors.white), 
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: Colors.white38), floatingLabelStyle: const TextStyle(color: Color(0xFF38BDF8)),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.white10)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF38BDF8))),
        filled: true, fillColor: Colors.white.withOpacity(0.03),
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final TextEditingController resetEmailController = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (context) {
        bool isResetting = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: const Text("Reset Password", style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Enter your email to receive a password reset link.", style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 20),
                  TextField(controller: resetEmailController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: "Email", labelStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF38BDF8))))),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.white70))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8)),
                  onPressed: isResetting ? null : () async {
                    final email = resetEmailController.text.trim();
                    if (email.isEmpty) return;
                    setState(() => isResetting = true);
                    try {
                      await _auth.resetPassword(email);
                      if (context.mounted) { 
                        Navigator.pop(context); 
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reset link sent! Please check your email."), backgroundColor: Colors.green)); 
                      }
                    } catch (e) {
                      setState(() => isResetting = false);
                      _showError("Failed to send reset link.");
                    }
                  },
                  child: isResetting ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Text("Send Link", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      }
    );
  }
}