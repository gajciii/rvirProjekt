import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> addMovieToList(String listName, Map<String, dynamic> movieDetails) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User is not logged in");
    }

    final movieId = movieDetails['id'].toString();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection(listName) // "To-Watch" or "Watched"
        .doc(movieId)
        .set({
      'title': movieDetails['title'],
      'release_date': movieDetails['release_date'],
      'poster_path': movieDetails['poster_path'],
      'genres': movieDetails['genres'],
      'timestamp': FieldValue.serverTimestamp(),
    });

    print('$listName list updated with movie: ${movieDetails['title']}');

    if (listName == 'Watched') {
      await checkAndAwardBadgeBingeMaster(user.uid);
    }
  } catch (e) {
    print('Error adding movie to $listName: $e');
  }
}

Future<void> checkAndAwardBadgeBingeMaster(String userId) async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  try {
    // Pridobi seznam gledanih filmov uporabnika iz Firestore
    final watchedCollection = await firestore
        .collection('users')
        .doc(userId)
        .collection('Watched')
        .get();

    // Filtriraj filme, gledane v zadnjih 24 urah
    final now = DateTime.now();
    final watchedToday = watchedCollection.docs.where((doc) {
      final timestamp = (doc.data()['timestamp'] as Timestamp).toDate();
      return timestamp.year == now.year &&
          timestamp.month == now.month &&
          timestamp.day == now.day;
    }).toList();

    // Preveri, če je gledanih vsaj 5 filmov
    if (watchedToday.length >= 5) {
      // Preveri, če obstaja kolekcija značk, in dodaj značko
      final badgesRef = firestore.collection('users').doc(userId).collection('badges');
      final badgesDoc = await badgesRef.doc('badgeList').get();

      if (badgesDoc.exists) {
        // Če značke že obstajajo, jih posodobi
        final List<dynamic> badges = badgesDoc.data()?['badges'] ?? [];
        if (!badges.contains("Binge Master")) {
          badges.add("Binge Master");
          await badgesRef.doc('badgeList').update({'badges': badges});
        }
      } else {
        // Če značke še ne obstajajo, jih ustvari
        await badgesRef.doc('badgeList').set({
          'badges': ["Binge Master"],
        });
      }
    }
  } catch (e) {
    print('Napaka pri preverjanju ali dodajanju značke: $e');
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

class MovieDetailsPage extends StatefulWidget {
  final int movieId;

  const MovieDetailsPage({Key? key, required this.movieId}) : super(key: key);

  @override
  State<MovieDetailsPage> createState() => _MovieDetailsPageState();
}

class _MovieDetailsPageState extends State<MovieDetailsPage> {
  Map<String, dynamic>? movieDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMovieDetails();
  }

  Future<void> fetchMovieDetails() async {
    const String apiUrl = 'https://api.themoviedb.org/3/movie/';
    const String apiKey = 'Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiIwZDlhMjkyNDczYjgwNzBiNDA2MzlkODI4NzkxNGZiZCIsIm5iZiI6MTczMjEwMjMxNS4yMjIwMDAxLCJzdWIiOiI2NzNkYzhhYjc1N2IyODQyZDlkOGFiYjMiLCJzY29wZXMiOlsiYXBpX3JlYWQiXSwidmVyc2lvbiI6MX0.ZJqk5ScIvPfSojaJ-VI-gl_k5DHuSdLje8HGGRk-gmo';

    try {
      final response = await http.get(
        Uri.parse('$apiUrl${widget.movieId}?language=en-US'),
        headers: {
          'Authorization': apiKey,
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          movieDetails = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load movie details');
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching movie details: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(movieDetails != null ? movieDetails!['title'] : 'Movie Details'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : movieDetails != null
          ? SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (movieDetails!['poster_path'] != null)
              Center(
                child: Image.network(
                  'https://image.tmdb.org/t/p/w500${movieDetails!['poster_path']}',
                ),
              ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                movieDetails!['title'] ?? '',
                style: Theme.of(context).textTheme.displayLarge,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                double rating = (movieDetails!['vote_average'] ?? 0) / 2;
                return Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              'Release Date: ${movieDetails!['release_date'] ?? 'N/A'}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Runtime: ${movieDetails!['runtime'] != null ? '${movieDetails!['runtime']} minutes' : 'N/A'}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Genres: ${movieDetails!['genres'] != null ? (movieDetails!['genres'] as List).map((genre) => genre['name']).join(', ') : 'N/A'}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Budget: \$${movieDetails!['budget']?.toStringAsFixed(0) ?? 'N/A'}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Revenue: \$${movieDetails!['revenue']?.toStringAsFixed(0) ?? 'N/A'}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text(
              movieDetails!['overview'] ?? 'No description available.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await addMovieToList('Watched', movieDetails!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Added to Watched')),
                    );
                  },
                  child: const Text('Watched'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await addMovieToList('To-Watch', movieDetails!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Added to To-Watch')),
                    );
                  },
                  child: const Text('To-Watch'),
                ),
              ],
            ),

          ],
        ),
      )
          : const Center(child: Text('No details available')),
    );
  }
}


