import 'package:flutter/material.dart';

class CustomDropdownMenu extends StatelessWidget {
  const CustomDropdownMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == "home") {
          Navigator.pushReplacementNamed(context, '/home');
        } else if (value == "profile") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile page coming soon!')),
          );
        } else if (value == "badges") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Badges page coming soon!')),
          );
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem(
          value: "home",
          child: ListTile(
            leading: const Icon(Icons.home, color: Colors.white),
            title: Text("Home", style: Theme.of(context).textTheme.bodyLarge),
          ),
        ),
        PopupMenuItem(
          value: "profile",
          child: ListTile(
            leading: const Icon(Icons.person, color: Colors.white),
            title: Text("Profile", style: Theme.of(context).textTheme.bodyLarge),
          ),
        ),
        PopupMenuItem(
          value: "badges",
          child: ListTile(
            leading: const Icon(Icons.star, color: Colors.white),
            title: Text("Badges", style: Theme.of(context).textTheme.bodyLarge),
          ),
        ),
      ],
      icon: const Icon(Icons.menu, color: Colors.white),
    );
  }
}
