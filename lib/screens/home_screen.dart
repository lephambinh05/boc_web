import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import '../widgets/common_widgets.dart';
import '../services/sound_manager.dart';
import 'game_screen.dart';
import 'ranking_screen.dart';
import 'tutorial_screen.dart';
import 'about_screen.dart';
import 'extra_screens.dart';

class HomeScreen extends StatefulWidget {
  final User? user;
  const HomeScreen({super.key, this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? _currentUser;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user ?? FirebaseAuth.instance.currentUser;
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (_currentUser == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
      if (mounted) {
        setState(() {
          _userData = doc.data();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String name = _userData?['displayName'] ?? (_currentUser?.isAnonymous == true ? "GUEST" : "PLAYER");
    int level = _userData?['level'] ?? 1;
    int xp = _userData?['xp'] ?? 0;
    
    // Calculate progress to next level
    int nextLevelXp = level * 500;
    int currentLevelBaseXp = (level - 1) * 500;
    double progress = (xp - currentLevelBaseXp) / (nextLevelXp - currentLevelBaseXp);
    if (progress < 0) progress = 0.0;
    if (progress > 1) progress = 1.0;

    return BeachBackground(
      showBlur: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: _currentUser != null ? UserDrawer(user: _currentUser!, userData: _userData) : null,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildHeader(context, name, level, progress),
                      const SizedBox(height: 40),
                      _buildHeroPlayCard(context, name),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionCard(
                              context, 
                              "LEADERBOARD", 
                              Icons.emoji_events_rounded, 
                              const Color(0xFFF2C94C), 
                              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RankingScreen()))
                            )
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildActionCard(
                              context, 
                              "HOW TO PLAY", 
                              Icons.menu_book_rounded, 
                              const Color(0xFF00D2FF), 
                              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TutorialScreen()))
                            )
                          ),
                        ],
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name, int level, double progress) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Color(0xFF00D2FF), Color(0xFF3A7BD5)]),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [BoxShadow(color: Colors.cyan.withOpacity(0.4), blurRadius: 10)],
          ),
          child: const Icon(Icons.person_rounded, color: Colors.white, size: 30),
        ),
        const SizedBox(width: 15),
        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome back,",
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              Text(
                name,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              // Level & XP Bar
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFF2994A), Color(0xFFF2C94C)]),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text("Lv.$level", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                        minHeight: 6,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
        const SizedBox(width: 15),
        // Menu Button
        Builder(
          builder: (context) => InkWell(
            onTap: () {
              SoundManager().playClickSound();
              Scaffold.of(context).openDrawer();
            },
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 24),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroPlayCard(BuildContext context, String name) {
    return GestureDetector(
      onTap: () {
        SoundManager().playClickSound();
        Navigator.push(context, MaterialPageRoute(builder: (_) => PuzzleScreen(
          playerName: name,
          userUid: _currentUser!.uid,
          user: _currentUser!,
          userData: _userData,
        )));
      },
      child: Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 20, offset: Offset(0, 10))],
          image: const DecorationImage(
            image: AssetImage("assets/images/puzzles/puzzle_1.png"), 
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.8)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
          ),
          padding: const EdgeInsets.all(25),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 65, shadows: [Shadow(color: Colors.black54, blurRadius: 10)]),
              SizedBox(height: 10),
              Text(
                "SUMMER PUZZLE",
                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 1.5, shadows: [Shadow(color: Colors.black, blurRadius: 5)]),
              ),
              Text(
                "Continue your journey",
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        SoundManager().playClickSound();
        onTap();
      },
      child: Container(
        height: 130,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class UserDrawer extends StatelessWidget {
  final User user;
  final Map<String, dynamic>? userData;
  const UserDrawer({super.key, required this.user, this.userData});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A).withOpacity(0.8), // Dark Glass
            border: Border(right: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- CUSTOM HEADER ---
                Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(colors: [Color(0xFF00D2FF), Color(0xFF3A7BD5)]),
                          boxShadow: [BoxShadow(color: const Color(0xFF00D2FF).withOpacity(0.4), blurRadius: 10)],
                        ),
                        child: const Icon(Icons.person_rounded, color: Colors.white, size: 40),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        userData?['displayName'] ?? "PLAYER",
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        user.email ?? (user.isAnonymous ? "Guest Session" : ""),
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                
                const Divider(color: Colors.white10),
                
                // --- MENU ITEMS ---
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    children: [
                      _buildModernItem(Icons.auto_stories_rounded, "Manual", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TutorialScreen()))),
                      _buildModernItem(Icons.insights_rounded, "Insights", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()))),
                      _buildModernItem(Icons.shield_moon_rounded, "Legal", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()))),
                      _buildModernItem(Icons.alternate_email_rounded, "Feedback", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()))),
                    ],
                  ),
                ),
                
                // --- FOOTER ---
                const Divider(color: Colors.white10),
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 0, 15, 20),
                  child: Column(
                    children: [
                      _buildModernItem(Icons.delete_forever_rounded, "Erase Data", () => _deleteAccount(context), color: Colors.redAccent.withOpacity(0.8)),
                      _buildModernItem(Icons.power_settings_new_rounded, "Sign Out", () => FirebaseAuth.instance.signOut(), color: Colors.white70),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: color ?? Colors.white, size: 22),
        title: Text(
          title,
          style: TextStyle(color: color ?? Colors.white, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.2), size: 18),
        tileColor: Colors.white.withOpacity(0.03),
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("ERASE ALL DATA?", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text("This action will permanently delete your progress.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("ERASE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
        await user.delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Data erased successfully!"), backgroundColor: Colors.green),
          );
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } on FirebaseAuthException catch (e) {
        if (context.mounted) {
          String msg = "Error: ${e.message}";
          if (e.code == 'requires-recent-login') {
            msg = "Please logout and login again to delete your account.";
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Critical Error: $e"), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }
}