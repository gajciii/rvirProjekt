import 'package:flutter/material.dart';

class CustomDropdownMenu extends StatelessWidget {
  const CustomDropdownMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu, color: Colors.white),
      onPressed: () {
        Navigator.of(context).push(_SlideInMenuRoute());
      },
    );
  }
}

class _SlideInMenuRoute extends PageRouteBuilder {
  _SlideInMenuRoute()
      : super(
    pageBuilder: (context, animation, secondaryAnimation) => _SlideInMenu(animation: animation),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(-1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOut;

      final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      final offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
  );
}

class _SlideInMenu extends StatelessWidget {
  final Animation<double> animation;

  const _SlideInMenu({required this.animation, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Container(
                color: Colors.black.withOpacity(animation.value * 0.7),
              );
            },
          ),
          // Sliding Menu Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 40),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MenuItem(
                      icon: Icons.home,
                      text: "Home",
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.pushReplacementNamed(context, '/home');
                      },
                    ),
                    const SizedBox(height: 40),
                    _MenuItem(
                      icon: Icons.person,
                      text: "Profile",
                      onTap: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile page coming soon!')),
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                    _MenuItem(
                      icon: Icons.star,
                      text: "Badges",
                      onTap: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Badges page coming soon!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _MenuItem({required this.icon, required this.text, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 16),
          Text(
            text,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
