import 'package:flutter/material.dart';
import '../services/tmdb.dart';

class HomeScreen extends StatelessWidget {
  final TMDBService _tmdbService = TMDBService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Filmique'),
      ),
      body: FutureBuilder(
        future: _tmdbService.fetchPopularMovies(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final movies = snapshot.data as List<dynamic>;
            return ListView.builder(
              itemCount: movies.length,
              itemBuilder: (context, index) {
                final movie = movies[index];
                return ListTile(
                  title: Text(movie['title']),
                  subtitle: Text('Rating: ${movie['vote_average']}'),
                  leading: Image.network(
                    'https://image.tmdb.org/t/p/w200${movie['poster_path']}',
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
