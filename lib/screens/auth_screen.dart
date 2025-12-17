import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/common_widgets.dart';
import 'home_screen.dart'; // Đảm bảo import đúng file Home mới

// AuthWrapper: Kiểm tra trạng thái đăng nhập
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Nếu đã đăng nhập -> Vào HomeScreen (Menu chính)
        if (snapshot.hasData) return const HomeScreen();
        // Nếu chưa -> Ở lại màn hình Login
        return const AuthScreen();
      },
    );
  }
}

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
  bool _isLogin = true; // true = Login mode, false = Register mode
  final _formKey = GlobalKey<FormState>();

  // Xử lý Submit
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        // ĐĂNG NHẬP
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // ĐĂNG KÝ
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Cập nhật tên hiển thị
        await userCredential.user?.updateDisplayName(_usernameController.text.trim());

        // Lưu data khởi tạo vào Firestore
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'displayName': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'xp': 0,
          'level': 1,
          'totalTime': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'An error occurred'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BeachBackground(
      showBlur: true, // Làm mờ nền biển
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                // Logo phía trên
                const SudokuLogo(size: 80),
                const SizedBox(height: 30),

                // KHUNG LOGIN/REGISTER (Glassmorphism)
                Container(
                  padding: const EdgeInsets.all(25.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9), // Nền trắng mờ
                    borderRadius: BorderRadius.circular(24), // Bo góc mềm
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))
                    ],
                    border: Border.all(color: Colors.white, width: 2), // Viền trắng tinh tế
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Tabs chuyển đổi (Login / Sign Up)
                        Row(
                          children: [
                            _buildTab("LOGIN", _isLogin, () => setState(() => _isLogin = true)),
                            _buildTab("SIGN UP", !_isLogin, () => setState(() => _isLogin = false)),
                          ],
                        ),
                        const SizedBox(height: 25),

                        // Form Fields
                        if (!_isLogin) ...[
                          _buildField(_usernameController, "Username", Icons.person_outline),
                          const SizedBox(height: 15),
                        ],

                        _buildField(_emailController, "Email Address", Icons.email_outlined, type: TextInputType.emailAddress),
                        const SizedBox(height: 15),
                        _buildField(_passwordController, "Password", Icons.lock_outline, isPass: true),

                        const SizedBox(height: 30),

                        // Nút Submit (Gradient)
                        if (_isLoading)
                          const CircularProgressIndicator(color: Colors.orange)
                        else
                          _buildGradientButton(
                            text: _isLogin ? "LOG IN" : "CREATE ACCOUNT",
                            onPressed: _submit,
                          ),

                        const SizedBox(height: 15),

                        // Nút chuyển đổi chế độ nhỏ phía dưới
                        TextButton(
                          onPressed: () => setState(() => _isLogin = !_isLogin),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                          ),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                              children: [
                                TextSpan(text: _isLogin ? "New player? " : "Already have account? "),
                                TextSpan(
                                  text: _isLogin ? "Sign Up" : "Log In",
                                  style: TextStyle(
                                    color: Colors.cyan.shade800,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget Tab chuyển đổi (Login/Sign Up)
  Widget _buildTab(String title, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? const Color(0xFFFF8C00) : Colors.transparent, // Cam hoặc ẩn
                width: 3,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.black87 : Colors.grey.shade400,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  // Widget Input Field (Hiện đại, sạch sẽ)
  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool isPass = false, TextInputType? type}) {
    return TextFormField(
      controller: controller,
      obscureText: isPass,
      keyboardType: type,
      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.cyan.shade800, size: 22),
        filled: true,
        fillColor: Colors.grey.shade100, // Nền xám rất nhạt
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none, // Không viền đen
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.cyan.shade200, width: 1.5),
        ),
      ),
      validator: (v) => v!.isEmpty ? "Required field" : null,
    );
  }

  // Widget Button Gradient (Giống màn hình Home)
  Widget _buildGradientButton({required String text, required VoidCallback onPressed}) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8C00), Color(0xFFFF4B1F)], // Cam -> Đỏ cam
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(25), // Bo tròn Pill shape
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(25),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}