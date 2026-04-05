import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = false;
  bool isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- AUTHENTICATION LOGIC ---

  Future<void> _submitEmailPasswordAuth() async {
    setState(() => isLoading = true);
    try {
      if (isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        if (_passwordController.text != _confirmPasswordController.text) {
          throw Exception("Passwords do not match");
        }
        await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
      // Navigate to dashboard on success
      if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => isLoading = false);
        return; // User canceled the sign-in
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign in with Google: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF16161E), // Added to match dark theme
      body: SafeArea(
        child: SingleChildScrollView( // Prevents overflow when keyboard appears
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFF1E1E28),
                child: Text('R', style: TextStyle(fontSize: 32, color: Color(0xFF7B52FF))),
              ),
              const SizedBox(height: 24),
              const Text('SyncRise', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              const Text('Build alarms that are impossible to sleep through.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),

              // Custom Toggle Bar
              Container(
                height: 50,
                decoration: BoxDecoration(color: const Color(0xFF1E1E28), borderRadius: BorderRadius.circular(30)),
                child: Row(
                  children: [
                    Expanded(
                        child: ElevatedButton(
                            onPressed: () => setState(() => isLogin = false),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: !isLogin ? const Color(0xFF7B52FF) : Colors.transparent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                            ),
                            child: Text('Sign Up', style: TextStyle(color: !isLogin ? Colors.white : Colors.grey, fontWeight: FontWeight.bold))
                        )
                    ),
                    Expanded(
                        child: ElevatedButton(
                            onPressed: () => setState(() => isLogin = true),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: isLogin ? const Color(0xFF7B52FF) : Colors.transparent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                            ),
                            child: Text('Log In', style: TextStyle(color: isLogin ? Colors.white : Colors.grey, fontWeight: FontWeight.bold))
                        )
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Input Fields
              _buildTextField('Email', 'name@email.com', _emailController),
              const SizedBox(height: 16),
              _buildTextField('Password', '************', _passwordController, obscure: true),

              // Only show Confirm Password if user is signing up
              if (!isLogin) ...[
                const SizedBox(height: 16),
                _buildTextField('Confirm Password', '************', _confirmPasswordController, obscure: true),
              ],

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submitEmailPasswordAuth,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B52FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(isLogin ? 'Log In' : 'Sign Up', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),

              // Google Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: isLoading ? null : _signInWithGoogle,
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Continue with Google', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFF1E1E28), // Adjusted slightly to stand out from the #16161E background
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}