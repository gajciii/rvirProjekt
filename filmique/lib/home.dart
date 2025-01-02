import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vreme_app/tmdb_service.dart';
import 'login.dart';
import 'dropdown_menu.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final TMDBService _tmdbService = TMDBService();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> newMovies = [];
  List<dynamic> recommendations = [];
  List<dynamic> searchResults = [];
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    _fetchMovies();
  }

  Future<void> _fetchMovies() async {
    try {
      final fetchedMovies = await _tmdbService.fetchPopularMovies();
      setState(() {
        newMovies = fetchedMovies;
        recommendations = fetchedMovies;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching movies: $e')),
      );
    }
  }

  Future<void> _searchMovies() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a search term.')),
      );
      return;
    }

    setState(() {
      isSearching = true;
    });

    try {
      final searchResults = await _tmdbService.searchMovies(query);
      setState(() {
        this.searchResults = searchResults;
        isSearching = false;
      });
    } catch (e) {
      setState(() {
        isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching for movies: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const CustomDropdownMenu(),
        title: const Text("Filmique"),
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _searchMovies,
                  child: const Text("Search"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (isSearching)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (searchResults.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final movie = searchResults[index];
                    return MovieListItem(movie: movie);
                  },
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Priporočila zate:",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 150,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: newMovies.length,
                          itemBuilder: (context, index) {
                            final movie = newMovies[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: MovieCard(movie: movie),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Novo:",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recommendations.length,
                        itemBuilder: (context, index) {
                          final movie = recommendations[index];
                          return MovieListItem(movie: movie);
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class MovieCard extends StatelessWidget {
  final dynamic movie;

  const MovieCard({Key? key, required this.movie}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final posterPath = movie['poster_path'] ?? '';
    return Container(
      width: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: posterPath.isNotEmpty
            ? DecorationImage(
          image: NetworkImage('https://image.tmdb.org/t/p/w200$posterPath'),
          fit: BoxFit.cover,
        )
            : null,
        color: Colors.grey[300],
      ),
    );
  }
}

class MovieListItem extends StatelessWidget {
  final dynamic movie;

  const MovieListItem({Key? key, required this.movie}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final posterPath = movie['poster_path'] ?? '';
    final title = movie['title'] ?? 'Unknown';
    final rating = movie['vote_average']?.toString() ?? 'N/A';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 100,
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: posterPath.isNotEmpty
                  ? DecorationImage(
                image: NetworkImage('https://image.tmdb.org/t/p/w200$posterPath'),
                fit: BoxFit.cover,
              )
                  : null,
              color: Colors.grey[300],
            ),
            child: posterPath.isEmpty
                ? const Center(child: Text('No Image'))
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  '⭐ $rating',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
