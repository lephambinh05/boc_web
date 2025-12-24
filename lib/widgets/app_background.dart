import 'package:flutter/material.dart';
import 'dart:ui';

class BeachBackground extends StatelessWidget {
  final Widget child;
  final bool showBlur;
  const BeachBackground({super.key, required this.child, this.showBlur = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: Image.asset("assets/images/sudoku_bg.png", fit: BoxFit.cover)),
        if (showBlur)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.black.withOpacity(0.1)),
            ),
          ),
        child,
      ],
    );
  }
}