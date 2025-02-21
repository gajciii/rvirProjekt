import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vreme_app/tmdb_service.dart';
import 'login.dart';
import 'dropdown_menu.dart';
import 'movie.dart';

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
    _fetchRecommendations();
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
  Future<Map<String, int>> fetchUserGenres() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User is not logged in");
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('Watched')
        .get();

    final genreCounts = <String, int>{};

    for (final doc in snapshot.docs) {
      final genres = doc.data()['genres'] as List<dynamic>?;
      if (genres != null) {
        for (final genre in genres) {
          final genreName = genre['name'] as String;
          genreCounts[genreName] = (genreCounts[genreName] ?? 0) + 1;
        }
      }
    }

    return genreCounts;
  }

  Future<void> _fetchRecommendations() async {
    try {
      final genreCounts = await fetchUserGenres();
      if (genreCounts.isEmpty) return;

      final topGenre = genreCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      final genreId = await _fetchGenreIdByName(topGenre);

      final recommendedMovies = await _tmdbService.fetchMoviesByGenre(genreId);
      setState(() {
        recommendations = recommendedMovies;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching recommendations: $e')),
      );
    }
  }

  Future<String> _fetchGenreIdByName(String genreName) async {
    try {
      final genres = await _tmdbService.fetchGenres();
      final genre = genres.firstWhere((g) => g['name'] == genreName, orElse: () => null);
      if (genre == null) throw Exception('Genre not found');
      return genre['id'].toString();
    } catch (e) {
      throw Exception('Error fetching genre ID: $e');
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

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      searchResults = [];
      isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        leading: const CustomDropdownMenu(),
        title: Text(
          "Filmique",
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search for movies...",
                        hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
                        border: InputBorder.none,
                        prefixIcon: const Icon(Icons.search, color: Colors.white54),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                    onPressed: _searchMovies,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _clearSearch,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Content
            Expanded(
              child: isSearching && searchResults.isNotEmpty
                  ? _buildSearchResults()
                  : _buildDefaultContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final movie = searchResults[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: MovieListItem(movie: movie),
        );
      },
    );
  }

  Widget _buildDefaultContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Novi filmi",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: newMovies.length,
              itemBuilder: (context, index) {
                final movie = newMovies[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MovieDetailsPage(movieId: movie['id']),
                        ),
                      );
                    },
                    child: MovieCard(movie: movie),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Priporočila",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              final movie = recommendations[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: MovieListItem(movie: movie),
              );
            },
          ),
        ],
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
    final title = movie['title'] ?? 'Unknown';

    return Container(
      width: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: posterPath.isNotEmpty
            ? DecorationImage(
          image: NetworkImage('https://image.tmdb.org/t/p/w200$posterPath'),
          fit: BoxFit.cover,
        )
            : null,
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          color: Colors.black54,
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
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

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 75,
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
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        subtitle: Text(
          '⭐ $rating',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MovieDetailsPage(movieId: movie['id']),
            ),
          );
        },
      ),
    );
  }
}
