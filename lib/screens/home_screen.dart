import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/common_widgets.dart';
import '../widgets/custom_dialog.dart';

// Import các màn hình game
import 'game_screen.dart';
import 'ranking_screen.dart';
import 'extra_screens.dart'; // Giữ lại để dùng cho PrivacyPolicy và Support (Không dùng Webview ở đây nữa)
import 'tutorial_screen.dart';
import 'about_screen.dart';

class HomeScreen extends StatefulWidget {
  final User? user;
  const HomeScreen({super.key, this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  User? _currentUser;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user ?? FirebaseAuth.instance.currentUser;
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadData();
  }

  Future<void> _loadData() async {
    if (_currentUser == null) return;
    try {
      // CHỈ LOAD DATA USER THÔI
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
      if (userDoc.exists) {
        if (mounted) setState(() => _userData = userDoc.data());
      }

      // ❌ ĐÃ XÓA: Đoạn code tự check settings_admin và mở WebViewScreen.
      // Việc mở Web giờ đây do ConfigService chạy ngầm quyết định.

    } catch (e) {
      print("Lỗi load user data: $e");
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const BeachBackground(
          child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(child: CircularProgressIndicator(color: Colors.white))
          )
      );
    }

    // --- LOGIC TÊN HIỂN THỊ ---
    final isGuest = _currentUser?.isAnonymous ?? false;
    final name = _userData?['displayName'] ?? (_currentUser?.displayName ?? (isGuest ? "Guest Player" : "Player"));

    return BeachBackground(
      showBlur: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Builder(
              builder: (ctx) => Container(
                margin: const EdgeInsets.only(left: 10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: IconButton(
                    icon: const Icon(Icons.menu_rounded, color: Colors.white),
                    onPressed: () => Scaffold.of(ctx).openDrawer()
                ),
              )
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: () => FirebaseAuth.instance.signOut(),
              ),
            ),
          ],
        ),
        drawer: UserDrawer(user: _currentUser!, userData: _userData),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // --- LOGO ---
                  const SudokuLogo(size: 90),

                  const Spacer(flex: 1),

                  // --- WELCOME TEXT ---
                  Text(
                      'WELCOME BACK,',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: 1.5,
                          shadows: const [Shadow(blurRadius: 4, color: Colors.black26, offset: Offset(0, 2))]
                      )
                  ),
                  const SizedBox(height: 5),
                  Text(
                      name.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.0,
                          shadows: [Shadow(blurRadius: 10, color: Colors.black45, offset: Offset(0, 4))]
                      )
                  ),

                  const SizedBox(height: 40),

                  // --- PLAY BUTTON ---
                  _buildModernButton(
                    text: "PLAY GAME",
                    icon: Icons.play_arrow_rounded,
                    gradient: const LinearGradient(
                        colors: [Color(0xFFFF8C00), Color(0xFFFF4B1F)],
                        begin: Alignment.centerLeft, end: Alignment.centerRight
                    ),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SudokuScreen(
                        playerName: name,
                        userUid: _currentUser!.uid,
                        user: _currentUser!,
                        userData: _userData
                    ))),
                  ),

                  const SizedBox(height: 15),

                  // --- LEADERBOARD BUTTON ---
                  _buildModernButton(
                    text: "LEADERBOARD",
                    icon: Icons.emoji_events_outlined,
                    gradient: LinearGradient(
                        colors: [Colors.cyan.shade800, Colors.blue.shade900],
                        begin: Alignment.centerLeft, end: Alignment.centerRight
                    ),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RankingScreen())),
                  ),

                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernButton({required String text, required IconData icon, required Gradient gradient, required VoidCallback onPressed}) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(30),
          splashColor: Colors.white24,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- DRAWER UI ---
class UserDrawer extends StatelessWidget {
  final User user;
  final Map<String, dynamic>? userData;
  const UserDrawer({super.key, required this.user, this.userData});

  @override
  Widget build(BuildContext context) {
    final isGuest = user.isAnonymous;
    final name = userData?['displayName'] ?? (isGuest ? "Guest Player" : (user.displayName ?? 'Player'));

    final int xp = userData?['xp'] ?? 0;
    final int rp = userData?['rp'] ?? 0;
    final int winStreak = userData?['winStreak'] ?? 0;

    String rank = 'Bronze';
    if (rp >= 600) {
      rank = 'Platinum';
    } else if (rp >= 300) rank = 'Gold';
    else if (rp >= 100) rank = 'Silver';

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(20))),
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.cyan.shade800, Colors.blue.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                    child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : "?",
                            style: TextStyle(fontSize: 35, color: Colors.cyan.shade900, fontWeight: FontWeight.bold)
                        )
                    )
                ),
                const SizedBox(height: 15),
                Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),

                if (isGuest)
                  const Padding(
                    padding: EdgeInsets.only(top: 4.0),
                    child: Text("(Guest Account)", style: TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic)),
                  ),

                const SizedBox(height: 10),
                const Divider(color: Colors.white54, thickness: 1),
                const SizedBox(height: 10),

                _buildStatRow(Icons.star_rounded, "Level", "${xp ~/ 500}", Colors.yellowAccent),
                _buildStatRow(Icons.emoji_events_rounded, "Rank", rank, Colors.orangeAccent),
                _buildStatRow(Icons.local_fire_department_rounded, "Streak", "$winStreak", Colors.redAccent),
              ],
            ),
          ),

          // Drawer Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 10),
              children: [
                _buildDrawerItem(context, Icons.menu_book_rounded, 'How to Play', const TutorialScreen()),
                _buildDrawerItem(context, Icons.info_outline_rounded, 'About', const AboutScreen()),
                _buildDrawerItem(context, Icons.policy_rounded, 'Privacy Policy', const PrivacyPolicyScreen()),
                _buildDrawerItem(context, Icons.support_agent_rounded, 'Support', const SupportScreen()),

                ListTile(
                    leading: Icon(Icons.copyright_rounded, color: Colors.cyan.shade900),
                    title: const Text('Copyright', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      showDialog(
                          context: context,
                          builder: (_) => CustomDialog(
                              title: 'Copyright',
                              content: '© 2024 Mojistudio.vn.\nAll rights reserved.',
                              buttonText: 'Close',
                              onPressed: () => Navigator.pop(context),
                              icon: Icons.copyright,
                              iconColor: Colors.grey
                          )
                      );
                    }
                ),
              ],
            ),
          ),

          // Logout Button
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.red),
                title: Text(
                    isGuest ? 'Exit Guest Mode' : 'Sign Out',
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
                ),
                onTap: () => FirebaseAuth.instance.signOut()
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Text('$label:', style: const TextStyle(fontSize: 14, color: Colors.white70)),
        const SizedBox(width: 5),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
      ]),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, Widget screen) {
    return ListTile(
      leading: Icon(icon, color: Colors.cyan.shade900),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
    );
  }
}