import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../main.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true; 
  bool _isLoading = false;

  void _submit() async {
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

    if (mounted) setState(() => _isLoading = false);

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Authentication Failed. Please check your credentials."), backgroundColor: Colors.redAccent)
      );
    } else {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainBackgroundWrapper(child: const HomeScreen())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Background wrapper එක පේන්න
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05), // 🚀 Glassy Effect
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo or Icon
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.quiz_rounded, size: 50, color: Color(0xFF38BDF8)),
                ),
                const SizedBox(height: 20),
                Text(
                  _isLogin ? "Welcome Back" : "Create Account",
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? "Sign in to continue your progress" : "Join with us to start your journey",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.white38),
                ),
                const SizedBox(height: 30),

                // 📧 Email Field
                _buildTextField(
                  controller: _emailController,
                  label: "Email",
                  icon: Icons.email_outlined,
                  type: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),

                // 🔑 Password Field
                _buildTextField(
                  controller: _passwordController,
                  label: "Password",
                  icon: Icons.lock_outline,
                  isObscure: true,
                ),
                
                // 💡 Forgot Password
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

                // 🚀 Submit Button
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
                    child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : Text(_isLogin ? "Sign In" : "Register", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 15),

                // 🔄 Toggle Login/Register
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
        ),
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
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8)),
                  onPressed: isResetting 
                    ? null 
                    : () async {
                        final email = resetEmailController.text.trim();
                        if (email.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please enter your email."), backgroundColor: Colors.redAccent)
                          );
                          return;
                        }
                        
                        setState(() => isResetting = true);
                        // Returns null on success, or an error message string
                        String? errorMsg = await _auth.resetPassword(email);
                        setState(() => isResetting = false);
                        
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(errorMsg == null ? "Password reset link sent to $email. Check your inbox (and spam folder)." : errorMsg),
                              backgroundColor: errorMsg == null ? Colors.green : Colors.redAccent,
                              duration: const Duration(seconds: 5),
                            )
                          );
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

  // 🛠️ Reusable Text Field (අකුරු පේන විදියට හදලා තියෙන්නේ)
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isObscure = false,
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      keyboardType: type,
      style: const TextStyle(color: Colors.white), // 🚀 ලියන අකුරු සුදු පාටින් පේනවා
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