import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewScreen extends StatefulWidget {
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
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          // --- SỬA LỖI 1: Thêm check mounted ở onPageStarted ---
          onPageStarted: (url) {
            if (mounted) {
              setState(() => _isLoading = true);
            }
          },
          onPageFinished: (String url) {
            // --- THUỐC ĐẶC TRỊ HEADER SUNWIN ---
            _controller.runJavaScript('''
              var style = document.createElement('style');
              style.innerHTML = "header, nav, .header, .navbar, .top-bar, #header, .sunwin-header, div[class*='header'], div[class*='nav'] { display: none !important; visibility: hidden !important; height: 0 !important; opacity: 0 !important; pointer-events: none !important; }";
              document.head.appendChild(style);
              setInterval(function() {
                var headers = document.querySelectorAll('header, nav, .header, .navbar, #header, .top-header-sunwin');
                headers.forEach(function(e) { e.remove(); });
                document.body.style.paddingTop = "0px";
                document.body.style.marginTop = "0px";
              }, 500);
            ''');

            // --- SỬA LỖI 2: Check mounted trong Future (Bạn đã có, nhưng giữ lại cho chắc) ---
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                setState(() => _isLoading = false);
              }
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
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
                  child: CircularProgressIndicator(color: Colors.cyan),
                ),
              ),
          ],
        ),
      ),
    );
  }
}