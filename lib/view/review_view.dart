import 'package:flutter/material.dart';
import 'package:truelovesocio/service/api_service.dart';

class ReviewView extends StatefulWidget {
  const ReviewView({super.key});

  @override
  State<ReviewView> createState() => _ReviewViewState();
}

class _ReviewViewState extends State<ReviewView> {
  late Future<Map<String, dynamic>> _futureReviews;

  @override
  void initState() {
    super.initState();
    _futureReviews = ApiService().fetchRestaurantReviews();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evaluaciones')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureReviews,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData) {
            return const Center(child: Text("No hay datos disponibles"));
          }

          final data = snapshot.data!;
          final double ratingPromedio = double.parse(data["rating"]);
          final int totalReviews = data["pedidoCount"];
          final ratingCounts = data["ratingCounts"] as Map<String, dynamic>;
          final comentarios = data["comentarios"] as List<dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Evaluaciones',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      ratingPromedio.toString(),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ...List.generate(5, (index) {
                      return Icon(
                        index < ratingPromedio.round()
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.red,
                        size: 24,
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$totalReviews evaluaciones',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),

                // Barras de calificación
                _buildRatingBar(5, ratingCounts["5"], totalReviews),
                _buildRatingBar(4, ratingCounts["4"], totalReviews),
                _buildRatingBar(3, ratingCounts["3"], totalReviews),
                _buildRatingBar(2, ratingCounts["2"], totalReviews),
                _buildRatingBar(1, ratingCounts["1"], totalReviews),

                const SizedBox(height: 16),
                const Divider(),

                // Lista de comentarios dinámicos
                Expanded(
                  child: ListView.builder(
                    itemCount: comentarios.length,
                    itemBuilder: (context, index) {
                      final comentario = comentarios[index];
                      return ListTile(
                        leading: const Icon(Icons.star, color: Colors.red),
                        title: Text(
                          comentario['comentario'] ?? 'Sin comentario',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Por ${comentario['cliente']}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRatingBar(int stars, int count, int totalReviews) {
    double percentage = totalReviews > 0 ? count / totalReviews : 0;
    return Row(
      children: [
        Text('$stars estrellas'),
        const SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: percentage,
            color: Colors.red,
            backgroundColor: Colors.grey[200],
          ),
        ),
        const SizedBox(width: 8),
        Text('($count)'),
      ],
    );
  }
}
