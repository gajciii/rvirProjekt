import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
          ],
        ),
      )
          : const Center(child: Text('No details available')),
    );
  }
}
