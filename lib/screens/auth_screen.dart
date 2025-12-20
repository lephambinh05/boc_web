import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/common_widgets.dart'; // Đảm bảo đường dẫn đúng tới BeachBackground, SudokuLogo
import 'home_screen.dart'; // Import HomeScreen mới

// --- 1. AUTH WRAPPER (Điều hướng) ---
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Nếu đã đăng nhập -> Vào HomeScreen
        if (snapshot.hasData) return const HomeScreen();
        // Nếu chưa -> Ở lại màn hình Login
        return const AuthScreen();
      },
    );
  }
}

// --- 2. AUTH SCREEN (Màn hình đăng nhập) ---
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  bool _isLoading = false;
  bool _isLogin = true; // true = Login, false = Sign Up
  final _formKey = GlobalKey<FormState>();

  // --- LOGIC 1: Đăng nhập Khách (Guest) ---
  Future<void> _signInAnonymously() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInAnonymously();
      // AuthWrapper sẽ tự động chuyển trang
    } on FirebaseAuthException catch (e) {
      if (mounted) _showError(e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIC 2: Đăng nhập / Đăng ký Email ---
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        // LOGIN
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // SIGN UP
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Cập nhật tên
        await userCredential.user?.updateDisplayName(_usernameController.text.trim());

        // Tạo dữ liệu User trên Firestore
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'displayName': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'xp': 0, 'level': 1, 'totalTime': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) _showError(e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String? message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message ?? 'Error'),
      backgroundColor: Colors.red.shade700,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BeachBackground(
      showBlur: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                // Logo
                const SudokuLogo(size: 80),
                const SizedBox(height: 30),

                // Container Form
                Container(
                  padding: const EdgeInsets.all(25.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))],
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Tabs
                        Row(
                          children: [
                            _buildTab("LOGIN", _isLogin, () => setState(() => _isLogin = true)),
                            _buildTab("SIGN UP", !_isLogin, () => setState(() => _isLogin = false)),
                          ],
                        ),
                        const SizedBox(height: 25),

                        // Username Field (Chỉ hiện khi Sign Up)
                        if (!_isLogin) ...[
                          _buildField(_usernameController, "Username", Icons.person_outline),
                          const SizedBox(height: 15),
                        ],

                        // Email & Password Fields
                        _buildField(_emailController, "Email", Icons.email_outlined, type: TextInputType.emailAddress),
                        const SizedBox(height: 15),
                        _buildField(_passwordController, "Password", Icons.lock_outline, isPass: true),

                        const SizedBox(height: 30),

                        // Buttons Area
                        if (_isLoading)
                          const CircularProgressIndicator(color: Colors.orange)
                        else
                          Column(
                            children: [
                              // Nút Login/Register chính
                              _buildGradientButton(
                                text: _isLogin ? "LOG IN" : "CREATE ACCOUNT",
                                onPressed: _submit,
                              ),

                              const SizedBox(height: 15),

                              // Nút Guest Mode
                              TextButton.icon(
                                onPressed: _signInAnonymously,
                                icon: Icon(Icons.person_pin_circle_outlined, color: Colors.cyan.shade800),
                                label: Text(
                                  "Play as Guest",
                                  style: TextStyle(
                                      color: Colors.cyan.shade900,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                                    backgroundColor: Colors.cyan.shade50,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 10),

                        // Chuyển đổi Mode Text
                        TextButton(
                          onPressed: () => setState(() => _isLogin = !_isLogin),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                              children: [
                                TextSpan(text: _isLogin ? "New player? " : "Already have account? "),
                                TextSpan(
                                  text: _isLogin ? "Sign Up" : "Log In",
                                  style: TextStyle(color: Colors.cyan.shade800, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- CÁC WIDGET CON (HELPER) ---

  Widget _buildTab(String title, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isActive ? const Color(0xFFFF8C00) : Colors.transparent, width: 3)),
          ),
          child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isActive ? Colors.black87 : Colors.grey.shade400,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              )
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool isPass = false, TextInputType? type}) {
    return TextFormField(
      controller: controller, obscureText: isPass, keyboardType: type,
      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon, color: Colors.cyan.shade800),
        filled: true, fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.cyan.shade200)),
      ),
      validator: (v) => v!.isEmpty ? "Required" : null,
    );
  }

  Widget _buildGradientButton({required String text, required VoidCallback onPressed}) {
    return Container(
      width: double.infinity, height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFF8C00), Color(0xFFFF4B1F)]),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed, borderRadius: BorderRadius.circular(25),
          child: Center(child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
        ),
      ),
    );
  }
}