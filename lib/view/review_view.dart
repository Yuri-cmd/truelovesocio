import 'package:flutter/material.dart';
import 'package:truelovesocio/components/components.dart';

class ReviewView extends StatelessWidget {
  const ReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Evaluaciones',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Text(
                  '4.7',
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Icon(Icons.star, color: Colors.red, size: 24),
                Icon(Icons.star, color: Colors.red, size: 24),
                Icon(Icons.star, color: Colors.red, size: 24),
                Icon(Icons.star, color: Colors.red, size: 24),
                Icon(Icons.star_half, color: Colors.red, size: 24),
              ],
            ),
            const SizedBox(height: 8),
            const Text('300 evaluaciones',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            _buildRatingBar(5, 222),
            _buildRatingBar(4, 120),
            _buildRatingBar(3, 50),
            _buildRatingBar(2, 20),
            _buildRatingBar(1, 20),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.grey),
                  ),
                  child: const Text('Personalizado'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.grey),
                  ),
                  child: const Text('Última semana'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.star, color: Colors.red),
              title: Text(
                'La Pizza Margarita estaba ok, nada del otro mundo.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Tal vez le faltaba un poco más...',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBar(int stars, int count) {
    return Row(
      children: [
        Text('$stars estrellas'),
        const SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: count / 300,
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
