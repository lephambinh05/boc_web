import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BeachBackground(
      showBlur: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'HOW TO PLAY',
            style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontSize: 22,
                letterSpacing: 1.5,
                shadows: [Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4)]
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Container(
            margin: const EdgeInsets.only(left: 10),
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.2)),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(25),
          children: [
            _buildGlassCard(
              title: "OBJECTIVE",
              icon: Icons.flag_rounded,
              iconColor: Colors.orange,
              content: const Text(
                "Arrange the tiles in ascending order (1, 2, 3...) by sliding them into the empty space. The puzzle is solved when all tiles are in their correct numerical positions.",
                style: TextStyle(fontSize: 15, height: 1.5, color: Colors.black87, fontWeight: FontWeight.w500),
                textAlign: TextAlign.justify,
              ),
            ),
            const SizedBox(height: 20),
            _buildGlassCard(
              title: "CONTROLS",
              icon: Icons.touch_app_rounded,
              iconColor: Colors.blueAccent,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildControlRow(Icons.swipe_rounded, "Slide Tiles", "Tap a tile adjacent to the empty space to move it into that space."),
                  const SizedBox(height: 15),
                  _buildControlRow(Icons.timer_rounded, "Time & Moves", "Try to solve the puzzle in the shortest time and with the fewest moves possible."),
                  const SizedBox(height: 15),
                  _buildControlRow(Icons.refresh_rounded, "Reset", "Use the RESET button to shuffle the tiles and start a new game."),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildGradientButton("GOT IT, LET'S PLAY!", () => Navigator.pop(context)),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({required String title, required IconData icon, required Color iconColor, required Widget content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 8))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 15),
                Text(
                    title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: iconColor, letterSpacing: 1.0)
                ),
              ],
            ),
            const Divider(thickness: 1.5, height: 30, color: Colors.black12),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildControlRow(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.cyan.shade800, size: 24),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.cyan.shade900)),
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(color: Colors.black87, height: 1.4, fontSize: 14)),
            ],
          ),
        ),
      ],
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
        boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(27.5),
          child: Center(
            child: Text(
                text,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)
            ),
          ),
        ),
      ),
    );
  }
}