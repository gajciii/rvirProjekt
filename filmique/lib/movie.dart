import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';



class MovieDetailsPage extends StatefulWidget {
  final int movieId;

  const MovieDetailsPage({Key? key, required this.movieId}) : super(key: key);

  @override
  State<MovieDetailsPage> createState() => _MovieDetailsPageState();
}

class _MovieDetailsPageState extends State<MovieDetailsPage> {
  ConfettiController _confettiController = ConfettiController(duration: const Duration(seconds: 2));

  @override
  void initState() {
    super.initState();
    fetchMovieDetails();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }
  Map<String, dynamic>? movieDetails;
  bool isLoading = true;


  void _showBadgeEarned(BuildContext context, String badgeName) {
    _confettiController.play();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Future.delayed(const Duration(seconds: 5), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });

        return Dialog(
          backgroundColor: Colors.white.withOpacity(0.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 250),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '🎉 Badge Earned! 🎉',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    badgeName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 60,
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      shouldLoop: false,
                      colors: const [Colors.blue, Colors.pink, Colors.orange, Colors.purple],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }




  Future<void> addMovieToList(String listName, Map<String, dynamic> movieDetails, BuildContext context) async {
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
        await checkAndAwardBadgeBingeMaster(user.uid, context);
        await checkAndAwardBadgeRetroFan(user.uid, context);
        await checkAndAwardBadgeCinephile(user.uid, context);
      }
    } catch (e) {
      print('Error adding movie to $listName: $e');
    }
  }

  Future<void> checkAndAwardBadgeBingeMaster(String userId, BuildContext context) async {
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
            _showBadgeEarned(context, "Binge Master");
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

  Future<void> checkAndAwardBadgeCinephile(String userId, BuildContext context) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      // Pridobi seznam gledanih filmov uporabnika iz Firestore
      final watchedCollection = await firestore
          .collection('users')
          .doc(userId)
          .collection('Watched')
          .get();

      // Preveri, ali je uporabnik pogledal vsaj 50 filmov
      if (watchedCollection.docs.length >= 6) {
        // Preveri, če obstaja kolekcija značk, in dodaj značko
        final badgesRef = firestore.collection('users').doc(userId).collection('badges');
        final badgesDoc = await badgesRef.doc('badgeList').get();

        if (badgesDoc.exists) {
          // Če značke že obstajajo, jih posodobi
          final List<dynamic> badges = badgesDoc.data()?['badges'] ?? [];
          if (!badges.contains("Cinephile")) {
            badges.add("Cinephile");
            await badgesRef.doc('badgeList').update({'badges': badges});
            _showBadgeEarned(context, "Cinephile");
          }
        } else {
          // Če značke še ne obstajajo, jih ustvari
          await badgesRef.doc('badgeList').set({
            'badges': ["Cinephile"],
          });

        }
      }
    } catch (e) {
      print('Napaka pri preverjanju ali dodajanju značke: $e');
    }
  }

  Future<void> checkAndAwardBadgeRetroFan(String userId, BuildContext context) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      // Pridobi seznam gledanih filmov uporabnika iz Firestore
      final watchedCollection = await firestore
          .collection('users')
          .doc(userId)
          .collection('Watched')
          .get();

      // Pripravi seznam desetletij od leta 1900 do trenutnega desetletja
      final currentYear = DateTime.now().year;
      final decades = List.generate((currentYear - 1900) ~/ 10 + 1, (index) => 1900 + index * 10);

      // Preveri, ali ima uporabnik filme iz vsakega desetletja
      final Set<int> coveredDecades = {};
      for (var doc in watchedCollection.docs) {
        final releaseDate = doc.data()['release_date'] as String?;
        if (releaseDate != null && releaseDate.isNotEmpty) {
          final year = int.tryParse(releaseDate.split('-').first);
          if (year != null) {
            final decade = (year ~/ 10) * 10;
            coveredDecades.add(decade);
          }
        }
      }

      // Preveri, ali so zajeta vsa desetletja
      if (decades.every((decade) => coveredDecades.contains(decade))) {
        // Preveri, če obstaja kolekcija značk, in dodaj značko
        final badgesRef = firestore.collection('users').doc(userId).collection('badges');
        final badgesDoc = await badgesRef.doc('badgeList').get();

        if (badgesDoc.exists) {
          // Če značke že obstajajo, jih posodobi
          final List<dynamic> badges = badgesDoc.data()?['badges'] ?? [];
          if (!badges.contains("Retro Fan")) {
            badges.add("Retro Fan");
            await badgesRef.doc('badgeList').update({'badges': badges});
            _showBadgeEarned(context, "Retro Fan");

          }
        } else {
          // Če značke še ne obstajajo, jih ustvari
          await badgesRef.doc('badgeList').set({
            'badges': ["Retro Fan"],
          });
        }
      }
    } catch (e) {
      print('Napaka pri preverjanju ali dodajanju značke: $e');
    }
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Zapri dialog
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
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

  Future<void> _rateMovie(BuildContext context, double rating, Map<String, dynamic> movieDetails) async {
    const String apiUrl = 'https://api.themoviedb.org/3/movie/';
    const String apiKey = 'Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiIwZDlhMjkyNDczYjgwNzBiNDA2MzlkODI4NzkxNGZiZCIsIm5iZiI6MTczMjEwMjMxNS4yMjIwMDAxLCJzdWIiOiI2NzNkYzhhYjc1N2IyODQyZDlkOGFiYjMiLCJzY29wZXMiOlsiYXBpX3JlYWQiXSwidmVyc2lvbiI6MX0.ZJqk5ScIvPfSojaJ-VI-gl_k5DHuSdLje8HGGRk-gmo';

    final String url = '$apiUrl${movieDetails['id']}/rating';
    final Map<String, String> headers = {
      'Authorization': apiKey,
      'Content-Type': 'application/json;charset=utf-8',
    };
    final String body = jsonEncode({'value': rating});

    try {
      print('Sending POST request to $url');
      print('Headers: $headers');
      print('Body: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        print("Response koda je 201");

        print("začetek shranjevanja v firebase");
        final user = FirebaseAuth.instance.currentUser;
        print(user);
        if (user != null) {
          final movieId = movieDetails['id'].toString();
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('ratings') // Nova zbirka za ocene filmov
              .doc(movieId)
              .set({
            'movie_id': movieId,
            'rating': rating,
            'timestamp': FieldValue.serverTimestamp(),
          });

          print('Movie rating saved in Firestore');
          _checkHighStandardsBadge(context);
        }
      } else {
        throw Exception('Failed to rate movie. Status: ${response.statusCode}');
      }
    } catch (error) {
      print('Error occurred: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  Future<void> _checkHighStandardsBadge(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Pridobi vse ocene iz zbirke 'ratings'
        final ratingsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('ratings')
            .get();

        // Preštej filme z oceno 2 ali manj
        final lowRatingsCount = ratingsSnapshot.docs
            .where((doc) => doc.data()['rating'] != null && doc.data()['rating'] <= 2)
            .length;

        print('Število filmov z oceno 2 ali manj: $lowRatingsCount');

        // Če je uporabnik dal oceno 2 ali manj desetim ali več filmom
        if (lowRatingsCount >= 3) {
          // Dodaj značko "High Standards" v zbirko badges
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('badges')
              .doc('badgeList')
              .set({
            'badges': FieldValue.arrayUnion(['High Standards']),
          }, SetOptions(merge: true));

          print('Badge "High Standards" added.');
          _showBadgeEarned(context, "High Standards");
        } else {
          print('User has not rated enough movies 2 or less for "High Standards" badge.');
        }
      } else {
        print('No user is logged in.');
      }
    } catch (error) {
      print('Error occurred while checking High Standards badge: $error');
    }
  }



  void _showRatingModal(BuildContext context, Map<String, dynamic> movieDetails) {
    final TextEditingController ratingController = TextEditingController();

    // Preverimo, ali je widget še vedno prikazan
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Rate the Movie'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter a rating (1-10):'),
              TextField(
                controller: ratingController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Enter rating',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final rating = double.tryParse(ratingController.text);
                if (rating != null && rating >= 1 && rating <= 10) {
                  // Preverimo, ali je widget še vedno prikazan, preden posodobimo stanje
                  if (mounted) {
                    _rateMovie(context, rating, movieDetails); // Posredujemo context in movieDetails.
                    Navigator.pop(context);
                  }
                } else {
                  // Preverimo, če je widget še vedno prikazan, preden prikažemo SnackBar
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid rating between 1 and 10!')),
                    );
                  }
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
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
                    await addMovieToList('Watched', movieDetails!, context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Added to Watched')),
                    );
                  },
                  child: const Text('Watched'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await addMovieToList('To-Watch', movieDetails!, context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Added to To-Watch')),
                    );
                  },
                  child: const Text('To-Watch'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (movieDetails != null) {
                      _showRatingModal(context, movieDetails!); // Posredujemo movieDetails.
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Movie details not available')),
                      );
                    }
                  },
                  child: const Text('RATE'),
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


