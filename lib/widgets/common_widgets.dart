import 'package:flutter/material.dart';
import 'dart:ui';

// --- 1. BEACH BACKGROUND (NỀN BIỂN) ---
class BeachBackground extends StatelessWidget {
  final Widget child;
  final bool showBlur;
  const BeachBackground({super.key, required this.child, this.showBlur = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Ảnh nền
        Positioned.fill(
          child: Image.asset(
            "assets/images/sudoku_bg.png",
            fit: BoxFit.cover,
          ),
        ),
        // Lớp phủ mờ (Blur) nếu cần
        if (showBlur)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Tăng độ mờ chút cho mịn
              child: Container(color: Colors.black.withOpacity(0.2)), // Tăng độ tối nhẹ để chữ trắng nổi hơn
            ),
          ),
        // Nội dung chính
        child,
      ],
    );
  }
}

// --- 2. SUDOKU LOGO (MODERN GLASS STYLE) ---
class SudokuLogo extends StatelessWidget {
  final double size;
  final bool showText; // Tùy chọn hiển thị chữ SUDOKU hay không

  const SudokuLogo({super.key, this.size = 100, this.showText = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Khối Icon Kính
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2), // Kính trong suốt
            borderRadius: BorderRadius.circular(size * 0.25), // Bo góc tỉ lệ theo size
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10)
              )
            ],
          ),
          child: Center(
              child: Icon(
                  Icons.apps_rounded, // Icon bo tròn hiện đại hơn grid_on_sharp
                  size: size * 0.6,
                  color: Colors.white
              )
          ),
        ),

        // Chữ SUDOKU (Nếu bật)
        if (showText) ...[
          SizedBox(height: size * 0.15),
          Text(
              'SUDOKU',
              style: TextStyle(
                  fontSize: size * 0.35, // Font size tỉ lệ theo Logo
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 4,
                  shadows: const [
                    Shadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 4))
                  ]
              )
          ),
        ]
      ],
    );
  }
}

// --- 3. HEADER ICON (NUT TRÒN TRONG SUỐT) ---
class ProminentHeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const ProminentHeaderIcon({super.key, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2), // Nền trắng mờ thay vì đen
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1), // Viền nhẹ
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22),
        onPressed: onPressed,
        splashColor: Colors.white24,
      ),
    );
  }
}

// --- 4. LOADING SCREEN (MÀN HÌNH CHỜ) ---
class LoadingScreen extends StatelessWidget {
  final String? message;
  const LoadingScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return BeachBackground(
      showBlur: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo hiện đại
              const SudokuLogo(size: 80, showText: true),

              const SizedBox(height: 50),

              // Loading Spinner
              const SizedBox(
                width: 30, height: 30,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),

              // Thông báo (Tiếng Anh)
              if (message != null) ...[
                const SizedBox(height: 20),
                Text(
                  message!, // Ví dụ: "Loading..."
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      decoration: TextDecoration.none,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black45, offset: Offset(0, 2))]
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}