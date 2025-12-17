import 'package:flutter/material.dart';

class CustomDialog extends StatefulWidget {
  final String title;
  final String content;
  final String buttonText;
  final VoidCallback onPressed;
  final IconData icon;
  final Color iconColor;

  const CustomDialog({
    super.key,
    required this.title,
    required this.content,
    required this.buttonText,
    required this.onPressed,
    required this.icon,
    required this.iconColor,
  });

  @override
  State<CustomDialog> createState() => _CustomDialogState();
}

class _CustomDialogState extends State<CustomDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // Chậm lại chút cho mượt
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut, // Nảy ra nhẹ nhàng
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: contentBox(context),
      ),
    );
  }

  Widget contentBox(BuildContext context) {
    return Stack(
      children: <Widget>[
        // --- PHẦN HỘP THOẠI CHÍNH ---
        Container(
          padding: const EdgeInsets.only(
            left: 25,
            top: 65 + 10, // Dành không gian cho icon + padding
            right: 25,
            bottom: 25,
          ),
          margin: const EdgeInsets.only(top: 55), // Đẩy xuống để lộ icon
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: Colors.white.withOpacity(0.95), // Hiệu ứng kính đục
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 2), // Viền kính
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                offset: Offset(0, 10),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Tiêu đề
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900, // Đậm hơn
                  color: widget.iconColor, // Màu tiêu đề theo màu icon
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),

              // Nội dung
              Text(
                widget.content,
                style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.4,
                    fontWeight: FontWeight.w500
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Nút bấm Gradient
              _buildGradientButton(),
            ],
          ),
        ),

        // --- PHẦN ICON NỔI ---
        Positioned(
          left: 20,
          right: 20,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(4), // Viền trắng bao quanh
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))
                ],
              ),
              child: CircleAvatar(
                backgroundColor: widget.iconColor,
                radius: 45,
                child: Icon(widget.icon, size: 45, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Widget Nút Gradient (Đồng bộ với Home/Auth Screen)
  Widget _buildGradientButton() {
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
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(25),
          child: Center(
            child: Text(
              widget.buttonText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}