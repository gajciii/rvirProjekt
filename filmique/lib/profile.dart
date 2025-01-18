import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_theme.dart';
import 'dropdown_menu.dart';
import 'login.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  Future<void> _removeMovie(String listName, String movieId) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection(listName)
          .doc(movieId)
          .delete();
      print('$listName movie removed: $movieId');
    } catch (e) {
      print('Error removing movie from $listName: $e');
      throw Exception('Failed to remove movie');
    }
  }

  Future<void> _moveMovie(String fromList, String toList, String movieId) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    try {
      final movieDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection(fromList)
          .doc(movieId)
          .get();

      if (!movieDoc.exists) {
        throw Exception("Movie not found in $fromList");
      }

      final movieData = movieDoc.data();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection(toList)
          .doc(movieId)
          .set(movieData!);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection(fromList)
          .doc(movieId)
          .delete();

      print("Moved movie $movieId from $fromList to $toList");
    } catch (e) {
      print("Error moving movie: $e");
      throw Exception("Failed to move movie");
    }
  }

  Future<void> _updateUserData(String firstName, String lastName) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'firstName': firstName, 'lastName': lastName});
      print('User profile updated');
    } catch (e) {
      print('Error updating user profile: $e');
      throw Exception("Failed to update user profile");
    }
  }

  Future<Map<String, dynamic>> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print('User not logged in');
      throw Exception("User not logged in");
    }

    print('User: ${user.uid}');

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        print('User profile not found');
        throw Exception("User profile not found");
      } else {
        print('User profile loaded');
        return doc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      throw Exception("Error fetching user profile: $e");
    }
  }

  void _showEditProfileDialog(BuildContext context, Map<String, dynamic> userData) {
    final firstNameController = TextEditingController(text: userData['firstName']);
    final lastNameController = TextEditingController(text: userData['lastName']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
              ),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final firstName = firstNameController.text.trim();
                final lastName = lastNameController.text.trim();

                if (firstName.isNotEmpty && lastName.isNotEmpty) {
                  try {
                    await _updateUserData(firstName, lastName);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile updated successfully!')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating profile: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        leading: const CustomDropdownMenu(),
        title: Text(
          "Profile",
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                      (route) => false,
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Logout failed: $e')),
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No profile data found."));
          }

          final data = snapshot.data!;
          final firstName = data['firstName'] ?? 'Unknown';
          final lastName = data['lastName'] ?? 'Unknown';
          final email = data['email'] ?? 'Unknown';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      "${firstName[0]}${lastName[0]}",
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "$firstName $lastName",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    email,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  _buildProfileSection(context, "Watched"),
                  const SizedBox(height: 10),
                  _buildProfileSection(context, "To-Watch"),
                  const SizedBox(height: 20),
                  _buildBadgesSection(context),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _showEditProfileDialog(context, data),
                    child: const Text("Edit Profile"),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBadgesSection(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Theme.of(context).colorScheme.surface,
      shadowColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Badges',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .collection('badges')
                  .doc('badgeList')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data?.data() == null) {
                  return const Center(
                    child: Text(
                      'No badges yet. Check out the badges page!',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                final badgeData = snapshot.data!.data() as Map<String, dynamic>;
                final badges = List<String>.from(badgeData['badges'] ?? []);

                if (badges.isEmpty) {
                  return const Center(
                    child: Text(
                      'No badges yet. Check out the badges page!',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: badges.length,
                    itemBuilder: (context, index) {
                      final badgeName = badges[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: Image.asset(
                                'lib/images/badge.png', // Badge image
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              badgeName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildProfileSection(BuildContext context, String listName) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      color: Theme.of(context).colorScheme.surface,
      shadowColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              listName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .collection(listName)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No $listName movies yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  );
                }

                final movies = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: movies.length,
                  itemBuilder: (context, index) {
                    final movie = movies[index];
                    return ListTile(
                      leading: movie['poster_path'] != null
                          ? Image.network(
                        'https://image.tmdb.org/t/p/w92${movie['poster_path']}',
                        fit: BoxFit.cover,
                      )
                          : const Icon(Icons.movie),
                      title: Text(movie['title'] ?? 'Unknown Title'),
                      subtitle: Text(
                        (movie['genres'] as List?)
                            ?.map((genre) => genre['name'])
                            .join(', ') ??
                            'Unknown genres',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (listName == "To-Watch")
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.pinkAccent),
                              onPressed: () async {
                                try {
                                  await _moveMovie("To-Watch", "Watched", movie.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Movie moved to Watched list!")),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Error moving movie: $e")),
                                    );
                                  }
                                }
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.pinkAccent),
                            onPressed: () async {
                              try {
                                await _removeMovie(listName, movie.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Movie removed!")),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Error removing movie: $e")),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }


}
