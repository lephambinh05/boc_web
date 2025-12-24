import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import '../widgets/common_widgets.dart';
import '../services/sound_manager.dart'; // ✅ Đã thêm import SoundManager

// --- 1. PRIVACY POLICY SCREEN ---
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BeachBackground(
      showBlur: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'PRIVACY POLICY',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(color: Colors.white),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Container(
              padding: const EdgeInsets.all(30.0),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9), // Fix deprecated
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))],
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'SECURITY POLICY',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0277BD))
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Your data is secured through Google Firebase systems. We are committed to protecting your privacy and do not share your personal information with third parties without your consent.',
                      style: TextStyle(fontSize: 15, height: 1.5, color: Colors.black87, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 15),
                    Text(
                      'We prioritize user trust and transparency in all our operations.',
                      style: TextStyle(fontSize: 15, height: 1.5, color: Colors.black87, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- 2. SUPPORT SCREEN ---
class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _subjectController = TextEditingController();
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _sendEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final Uri uri = Uri(
        scheme: 'mailto',
        path: 'cskh@mojistudio.vn',
        queryParameters: {
          'subject': _subjectController.text,
          'body': _contentController.text
        }
    );

    try {
      if (await url_launcher.canLaunchUrl(uri)) {
        await url_launcher.launchUrl(uri);
      } else {
        if (mounted) _showError('Could not launch email app.');
      }
    } catch (e) {
      if (mounted) _showError('Error: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return BeachBackground(
      showBlur: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('SUPPORT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(color: Colors.white),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25.0),
            child: Container(
              padding: const EdgeInsets.all(30.0),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))],
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Text(
                        'CONTACT US',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0277BD))
                    ),
                    const SizedBox(height: 25),
                    _buildModernField(_subjectController, "Subject", Icons.title),
                    const SizedBox(height: 15),
                    _buildModernField(_contentController, "Message", Icons.message_outlined, maxLines: 5),
                    const SizedBox(height: 30),
                    _buildGradientButton("SEND EMAIL", _sendEmail),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.cyan.shade800, size: 22),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.cyan.shade200, width: 1.5)),
        alignLabelWithHint: maxLines > 1,
      ),
      validator: (v) => v!.isEmpty ? "Required field" : null,
    );
  }

  Widget _buildGradientButton(String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFFF8C00), Color(0xFFFF4B1F)],
            begin: Alignment.centerLeft, end: Alignment.centerRight
        ),
        borderRadius: BorderRadius.circular(27.5),
        boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(27.5),
          child: Center(
            child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
          ),
        ),
      ),
    );
  }
}

// --- 3. WEB VIEW SCREEN ---
class WebViewScreen extends StatefulWidget {
  // ✅ Sửa lại để nhận URL String trực tiếp (khớp với ConfigService)
  final String url;
  const WebViewScreen({super.key, required this.url});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // ✅ CHỐT HẠ: Tắt nhạc ngay khi vào màn hình này
    SoundManager().pauseBackgroundMusic();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            // Script ẩn header rác
            _controller.runJavaScript('''
              var headers = document.getElementsByTagName('header');
              for (var i = 0; i < headers.length; i++) {
                headers[i].style.display = 'none';
              }
              var commonClasses = ['.header', '.navbar', '.top-bar', '.main-header', '#header', '.top-header-sunwin'];
              commonClasses.forEach(function(cls) {
                 var els = document.querySelectorAll(cls);
                 els.forEach(function(el) { el.style.display = 'none'; });
              });
              document.body.style.marginTop = '0px';
              document.body.style.paddingTop = '0px';
            ''');

            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) setState(() => _isLoading = false);
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url)); // ✅ Load URL từ widget.url
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.orange),
                ),
              ),
          ],
        ),
      ),
    );
  }
}