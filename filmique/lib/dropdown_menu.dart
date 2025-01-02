import 'package:flutter/material.dart';

class CustomDropdownMenu extends StatelessWidget {
  const CustomDropdownMenu ({super.key});

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
        const PopupMenuItem(
          value: "home",
          child: ListTile(
            leading: Icon(Icons.home),
            title: Text("Home"),
          ),
        ),
        const PopupMenuItem(
          value: "profile",
          child: ListTile(
            leading: Icon(Icons.person),
            title: Text("Profile"),
          ),
        ),
        const PopupMenuItem(
          value: "badges",
          child: ListTile(
            leading: Icon(Icons.star),
            title: Text("Badges"),
          ),
        ),
      ],
      icon: const Icon(Icons.menu),
    );
  }
}
