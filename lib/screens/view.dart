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
    // 1. BẮT BUỘC: Cho phép chạy Javascript (Game/Web app cần cái này để chạy)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)

    // 2. Màu nền đen (để lúc load không bị chớp trắng)
      ..setBackgroundColor(Colors.black)

    // 3. Cấu hình điều hướng
      ..setNavigationDelegate(
        NavigationDelegate(
          // Bắt đầu load -> Hiện vòng xoay
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoading = true);
          },

          // Load xong -> Tắt vòng xoay
          onPageFinished: (String url) {
            // ✅ ĐÃ XÓA SẠCH: Không còn dòng runJavaScript nào ở đây cả.
            // Web của bạn sẽ hiển thị nguyên gốc 100%.

            if (mounted) setState(() => _isLoading = false);
          },

          // Báo lỗi nếu web chết (để debug)
          onWebResourceError: (WebResourceError error) {
            // print("Web Error: ${error.description}");
          },

          // ✅ KHÔNG CHẶN GÌ CẢ: Cho phép chuyển trang thoải mái
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    // Xử lý nút Back trên điện thoại:
    // Nếu Web quay lại được thì quay lại trang trước.
    // Nếu hết trang để quay lại thì mới thoát App.
    return WillPopScope(
      onWillPop: () async {
        if (await _controller.canGoBack()) {
          _controller.goBack();
          return false; // Ở lại Webview
        }
        return true; // Thoát ra màn hình chính
      },
      child: Scaffold(
        backgroundColor: Colors.black, // Nền full đen
        body: SafeArea(
          child: Stack(
            children: [
              // 1. Nội dung Web
              WebViewWidget(controller: _controller),

              // 2. Loading (Chỉ hiện khi đang tải)
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
      ),
    );
  }
}