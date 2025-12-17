import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/common_widgets.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  // Helper: Format Seconds -> MM:SS
  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return BeachBackground(
      showBlur: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
              'LEADERBOARD',
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontSize: 22,
                  letterSpacing: 1.5,
                  shadows: [Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4)]
              )
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
        body: StreamBuilder<QuerySnapshot>(
          // --- LOGIC: Query từ collection 'users' để đồng bộ với Auth ---
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('level', isGreaterThan: 0) // Chỉ lấy user đã chơi
              .orderBy('level', descending: true) // Ưu tiên Level cao
              .orderBy('totalTime', descending: false) // Cùng Level thì ai nhanh hơn (thời gian thấp hơn) xếp trên
              .limit(50)
              .snapshots(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }

            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.leaderboard_outlined, size: 60, color: Colors.white.withOpacity(0.5)),
                      const SizedBox(height: 10),
                      Text(
                          "No ranking data yet",
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.w600)
                      ),
                    ],
                  )
              );
            }

            final docs = snap.data!.docs;

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final data = docs[i].data() as Map<String, dynamic>;
                final int rank = i + 1;

                // Lấy dữ liệu an toàn (Dùng displayName thay vì playerName cho khớp Auth)
                final String name = data['displayName'] ?? data['email'] ?? 'Unknown';
                final int level = data['level'] ?? 1;
                final int time = data['totalTime'] ?? 0;

                return _buildModernRankCard(rank, name, level, time);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildModernRankCard(int rank, String name, int level, int time) {
    // Cấu hình màu sắc đặc biệt cho Top 3
    Color borderColor = Colors.white.withOpacity(0.5);
    Color bgColor = Colors.white.withOpacity(0.85); // Mặc định là kính trắng mờ
    Widget rankIcon;
    double scale = 1.0;
    List<BoxShadow> shadows = [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))];

    if (rank == 1) {
      borderColor = const Color(0xFFFFD700); // Gold
      bgColor = const Color(0xFFFFF9C4).withOpacity(0.9); // Vàng nhạt
      scale = 1.05;
      shadows = [BoxShadow(color: Colors.amber.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))];
      rankIcon = _buildTrophy(Icons.emoji_events_rounded, Colors.amber, "1ST");
    } else if (rank == 2) {
      borderColor = const Color(0xFFC0C0C0); // Silver
      bgColor = const Color(0xFFF5F5F5).withOpacity(0.9);
      rankIcon = _buildTrophy(Icons.military_tech_rounded, Colors.grey.shade700, "2ND");
    } else if (rank == 3) {
      borderColor = const Color(0xFFCD7F32); // Bronze
      bgColor = const Color(0xFFEFEBE9).withOpacity(0.9);
      rankIcon = _buildTrophy(Icons.military_tech_rounded, const Color(0xFFA1887F), "3RD");
    } else {
      // Top 4+
      rankIcon = Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: Colors.cyan.shade900,
          shape: BoxShape.circle,
        ),
        child: Center(
            child: Text(
                '$rank',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
            )
        ),
      );
    }

    return Transform.scale(
      scale: scale,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: rank <= 3 ? 2 : 1),
          boxShadow: shadows,
        ),
        child: Row(
          children: [
            // 1. Rank Icon
            SizedBox(width: 45, child: Center(child: rankIcon)),

            const SizedBox(width: 12),

            // 2. Name & Level info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Colors.cyan.shade900
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Colors.blue, Colors.blueAccent]),
                            borderRadius: BorderRadius.circular(6)
                        ),
                        child: Text("LV.$level", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
                ],
              ),
            ),

            // 3. Time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("TIME", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                Text(
                    _formatTime(time),
                    style: TextStyle(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        fontFeatures: const [FontFeature.tabularFigures()] // Căn số thẳng hàng
                    )
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTrophy(IconData icon, Color color, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        Text(label, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 9))
      ],
    );
  }
}