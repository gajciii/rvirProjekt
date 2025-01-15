import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'dropdown_menu.dart';
import 'login.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BadgesPage extends StatefulWidget {
  const BadgesPage({super.key});

  @override
  _BadgesPageState createState() => _BadgesPageState();
}

class _BadgesPageState extends State<BadgesPage> {
  final List<Map<String, String>> badges = const [
    {"name": "High Standards", "description": "For giving 20 movies a rating of 1 or 2 stars."},
    {"name": "Cinephile", "description": "Awarded for watching 50 movies."},
    {"name": "Binge Master", "description": "Awarded for watching 5 movies in a single day."},
    {"name": "100 Club", "description": "Awarded for watching 100 movies."},
    {"name": "250 Club", "description": "Awarded for watching 250 movies."},
    {"name": "500 Club", "description": "Awarded for watching 500 movies."},
    {"name": "Retro Fan", "description": "Awarded for watching a movie from every decade since 1900."}
  ];

  List<String> userBadges = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserBadges();
  }

  Future<void> _loadUserBadges() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final badgesDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('badges')
          .doc('badgeList')
          .get();

      if (badgesDoc.exists) {
        setState(() {
          userBadges = List<String>.from(badgesDoc.data()?['badges'] ?? []);
        });
      }
    } catch (e) {
      print('Napaka pri nalaganju značk: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        leading: const CustomDropdownMenu(),
        title: Text(
          'Značke',
          style: AppTheme.theme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: AppTheme.theme.appBarTheme.backgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Center(
                child: BadgeCard(
                  badge: badges[0],
                  isLarge: true,
                  hasBadge: userBadges.contains(badges[0]["name"]),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                ),
                itemCount: badges.length - 1,
                itemBuilder: (context, index) {
                  return BadgeCard(
                    badge: badges[index + 1],
                    hasBadge: userBadges.contains(badges[index + 1]["name"]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class BadgeCard extends StatefulWidget {
  final Map<String, String> badge;
  final bool isLarge;
  final bool hasBadge;

  const BadgeCard({required this.badge, this.isLarge = false, required this.hasBadge, super.key});

  @override
  _BadgeCardState createState() => _BadgeCardState();
}

class _BadgeCardState extends State<BadgeCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleCard() {
    if (_isFlipped) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * 3.1416; // Flip angle in radians
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(angle),
            child: angle < 1.57
                ? _buildFront()
                : Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(3.1416),
              child: _buildBack(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFront() {
    return Card(
      shape: AppTheme.theme.cardTheme.shape,
      color: const Color(0xD553639D),
      elevation: AppTheme.theme.cardTheme.elevation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            widget.hasBadge
                ? Image.asset(
              'lib/images/badge.png',
              width: widget.isLarge ? 80 : 50,
              height: widget.isLarge ? 80 : 50,
            )
                : Icon(
              Icons.shield,
              size: widget.isLarge ? 80 : 50,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              widget.badge['name']!,
              style: AppTheme.theme.textTheme.bodyLarge?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBack() {
    return Card(
      shape: AppTheme.theme.cardTheme.shape,
      color: const Color(0xD553639D),
      elevation: AppTheme.theme.cardTheme.elevation,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            widget.badge['description']!,
            style: AppTheme.theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
