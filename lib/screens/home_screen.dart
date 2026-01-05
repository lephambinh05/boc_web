import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/common_widgets.dart';
import '../widgets/custom_dialog.dart';
import '../services/sound_manager.dart'; // ✅ Đã thêm Import SoundManager

// Import các màn hình game
import 'game_screen.dart';
import 'ranking_screen.dart';
import 'extra_screens.dart';
import 'tutorial_screen.dart';
import 'about_screen.dart';

// =======================
// 1. HOME SCREEN MAIN UI
// =======================
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

    // ✅ KÍCH HOẠT NHẠC NỀN KHI VÀO HOME
    SoundManager().startBackgroundMusic();

    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ✅ XỬ LÝ NHẠC KHI ẨN/HIỆN APP
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData();
      SoundManager().resumeBackgroundMusic(); // App hiện lại -> Bật nhạc
    } else if (state == AppLifecycleState.paused) {
      SoundManager().pauseBackgroundMusic();  // App ẩn đi -> Tắt nhạc
    }
  }

  Future<void> _loadData() async {
    if (_currentUser == null) return;
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
      if (userDoc.exists) {
        if (mounted) setState(() => _userData = userDoc.data());
      }
    } catch (e) {
      // Silent error
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
                  const SudokuLogo(size: 90),
                  const Spacer(flex: 1),
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

// =======================
// 2. USER DRAWER & DELETE LOGIC
// =======================
class UserDrawer extends StatelessWidget {
  final User user;
  final Map<String, dynamic>? userData;
  const UserDrawer({super.key, required this.user, this.userData});

  // --- HÀM XỬ LÝ XÓA TÀI KHOẢN (ĐÃ FIX LỖI TREO LOADING) ---
  Future<void> _deleteAccount(BuildContext context) async {
    // 1. Hiển thị hộp thoại xác nhận
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("DELETE ACCOUNT?", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: const Text(
          "This action cannot be undone.\nAll your game data will be lost immediately.",
          style: TextStyle(fontSize: 14),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("DELETE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 2. Tiến hành xóa
    try {
      // Hiện loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.red)),
      );

      // A. Xóa dữ liệu Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();

      // B. Xóa User trên Auth
      await user.delete();

      // C. [QUAN TRỌNG] Tắt Loading TRƯỚC khi SignOut
      // Để tránh việc màn hình bị hủy trước khi tắt dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // D. Sau đó mới SignOut để Wrapper tự đá về màn hình Auth
      await FirebaseAuth.instance.signOut();

    } on FirebaseAuthException catch (e) {
      // Nếu lỗi xảy ra, dialog vẫn đang hiện, nên cần pop nó đi
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      String errorMsg = "Error deleting account.";
      if (e.code == 'requires-recent-login') {
        errorMsg = "Please Sign Out and Sign In again to delete account.";
      } else if (e.code == 'user-not-found') {
        // User đã mất rồi thì logout luôn
        await FirebaseAuth.instance.signOut();
        return;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      // Pop dialog nếu có lỗi khác
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    }
  }

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

                const Divider(height: 30), // Gạch ngang phân cách

                // --- [NÚT XÓA TÀI KHOẢN] ---
                ListTile(
                  leading: const Icon(Icons.delete_forever_rounded, color: Colors.grey),
                  title: const Text('Delete Account', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                  onTap: () => _deleteAccount(context), // Gọi hàm xóa
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