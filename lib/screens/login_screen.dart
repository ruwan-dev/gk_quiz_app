import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../main.dart';
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

  // 🚀 Space Gradient Animation එක සඳහා Controller එක
  late AnimationController _brandingController;

  @override
  void initState() {
    super.initState();
    _brandingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60), // වර්ණ හෙමින් ගලාගෙන යන්න කාලය වැඩි කළා
    )..repeat();
  }

  @override
  void dispose() {
    _brandingController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    FocusScope.of(context).unfocus(); 
    setState(() => _isLoading = true);
    
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields"), backgroundColor: Colors.redAccent)
      );
      setState(() => _isLoading = false);
      return;
    }

    dynamic result;
    if (_isLogin) {
      result = await _auth.signInWithEmail(email, password);
    } else {
      result = await _auth.registerWithEmail(email, password);
    }

    if (mounted) {
      if (result == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Authentication Failed. Please check your credentials."), backgroundColor: Colors.redAccent)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true, 
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
                            
                            // 💎 Glassy Login Card
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
                                  // 🚀 Logo Area
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.2)),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(50),
                                      child: Image.asset(
                                        'assets/logo.png', 
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => 
                                            const Icon(Icons.rocket_launch_rounded, size: 50, color: Color(0xFF38BDF8)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  // ✨ ඔයාගේ අලුත් Welcome Message එක
                                  Text(
                                    _isLogin ? "Hello Future Leader!" : "Join to the Game of Knowledge!",
                                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _isLogin ? "Ready to conquer today's quiz?" : "Start your journey to the stars",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 14, color: Colors.white38),
                                  ),
                                  const SizedBox(height: 30),
                                  _buildTextField(
                                    controller: _emailController,
                                    label: "Email",
                                    icon: Icons.email_outlined,
                                    type: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildTextField(
                                    controller: _passwordController,
                                    label: "Password",
                                    icon: Icons.lock_outline,
                                    isObscure: true,
                                  ),
                                  if (_isLogin)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () => _showForgotPasswordDialog(context),
                                        child: const Text("Forgot Password?", style: TextStyle(color: Colors.white70)),
                                      ),
                                    )
                                  else
                                    const SizedBox(height: 15),
                                  const SizedBox(height: 15),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 55,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _submit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF38BDF8),
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                        elevation: 0,
                                      ),
                                      child: Text(_isLogin ? "Sign In" : "Register", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  TextButton(
                                    onPressed: () => setState(() => _isLogin = !_isLogin),
                                    child: Text(
                                      _isLogin ? "Don't have an account? Register" : "Already have an account? Sign In",
                                      style: const TextStyle(color: Color(0xFF38BDF8)),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Spacer(flex: 3), 

                            // 🚀 Branding Section (Footer with Space Gradient)
                            if (!isKeyboardVisible)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 20.0),
                                child: Column(
                                  children: [
                                    Text(
                                      "POWERED BY",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.2),
                                        fontSize: 9,
                                        letterSpacing: 2,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4), 
                                    
                                    // ✨ Space Object Inspired Gradient Animation
                                    AnimatedBuilder(
                                      animation: _brandingController,
                                      builder: (context, child) {
                                        return ShaderMask(
                                          shaderCallback: (bounds) {
                                            return LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                const Color(0xFF9C27B0), // Cosmic Purple
                                                const Color(0xFF00ACC1), // Nebula Teal
                                                const Color(0xFF38BDF8), // Star Blue
                                                const Color(0xFFE040FB), // Supernova Magenta
                                                const Color(0xFF9C27B0), // Loop back to Purple
                                              ],
                                              stops: [
                                                0.0,
                                                (_brandingController.value - 0.2).clamp(0.0, 1.0),
                                                _brandingController.value,
                                                (_brandingController.value + 0.2).clamp(0.0, 1.0),
                                                1.0,
                                              ],
                                            ).createShader(bounds);
                                          },
                                          child: const Text(
                                            "OrbitView Innovations", // 👈 කම්පැනි නම මෙතනට දැම්මා
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 3,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    
                                    const SizedBox(height: 4), 
                                    Text(
                                      "© 2026 ALL RIGHTS RESERVED",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.1),
                                        fontSize: 8,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: const Center(
                  child: GeminiLoader(size: 80), 
                ),
              ),
            ),
        ],
      ),
    );
  }

  // (Textfield & Dialog logic remains same)
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
                  TextField(
                    controller: resetEmailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Email",
                      labelStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF38BDF8))),
                    ),
                  ),
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
                        await _auth.resetPassword(email);
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reset link sent!"), backgroundColor: Colors.green));
                        }
                      },
                  child: isResetting 
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text("Send Link", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, bool isObscure = false, TextInputType type = TextInputType.text}) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      keyboardType: type,
      style: const TextStyle(color: Colors.white), 
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        floatingLabelStyle: const TextStyle(color: Color(0xFF38BDF8)),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.white10)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF38BDF8))),
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
      ),
    );
  }
}