import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart'; // Ensure BeachBackground is here

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BeachBackground(
      showBlur: true, // Blur background for readability
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
            // 1. OBJECTIVE
            _buildGlassCard(
              title: "OBJECTIVE",
              icon: Icons.flag_rounded,
              iconColor: Colors.orange,
              content: const Text(
                "Fill the 9×9 grid with digits so that each column, each row, and each of the nine 3×3 subgrids that compose the grid contain all of the digits from 1 to 9 without repetition.",
                style: TextStyle(fontSize: 15, height: 1.5, color: Colors.black87, fontWeight: FontWeight.w500),
                textAlign: TextAlign.justify,
              ),
            ),
            const SizedBox(height: 20),

            // 2. RULES
            _buildGlassCard(
              title: "KEY RULES",
              icon: Icons.verified_user_rounded,
              iconColor: Colors.green,
              content: Column(
                children: [
                  _buildRuleRow(Icons.table_rows_rounded, "Rows", "Every row must contain numbers 1-9, no duplicates."),
                  const Divider(height: 25),
                  _buildRuleRow(Icons.view_column_rounded, "Columns", "Every column must contain numbers 1-9, no duplicates."),
                  const Divider(height: 25),
                  _buildRuleRow(Icons.grid_3x3_rounded, "3x3 Boxes", "Every 3x3 subgrid (thick border) must contain numbers 1-9."),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. CONTROLS
            _buildGlassCard(
              title: "CONTROLS",
              icon: Icons.gamepad_rounded,
              iconColor: Colors.blueAccent,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildControlRow(Icons.touch_app_rounded, "Select Cell", "Tap an empty cell on the grid to select it."),
                  const SizedBox(height: 15),
                  _buildControlRow(Icons.looks_one_rounded, "Input Number", "Tap numbers 1-9 on the bottom keypad to fill."),
                  const SizedBox(height: 15),
                  _buildControlRow(Icons.verified_rounded, "CHECK Button", "Verify your current progress. \n🔴 Red = Wrong (fades in 3s).\n🟢 Green = Correct."),
                  const SizedBox(height: 15),
                  _buildControlRow(Icons.backspace_rounded, "CLEAR Button", "Remove the number from the selected cell."),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Bottom Button
            _buildGradientButton("GOT IT, LET'S PLAY!", () => Navigator.pop(context)),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  // Modern Glassmorphism Card
  Widget _buildGlassCard({required String title, required IconData icon, required Color iconColor, required Widget content}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9), // Milky glass
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

  Widget _buildRuleRow(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 26),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black87)),
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(color: Colors.black54, height: 1.3, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlRow(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.cyan.shade50, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: Colors.cyan.shade800, size: 22),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.cyan.shade900)),
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