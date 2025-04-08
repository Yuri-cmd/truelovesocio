import 'package:flutter/material.dart';
import 'package:truelovesocio/screen/heatmap_screen.dart';
import 'package:truelovesocio/screen/rating_chart.dart';
import 'package:truelovesocio/screen/review_screen.dart';

class DashboardScreen extends StatelessWidget {
  final List<Map<String, dynamic>> charts = [
    {
      'title': 'Mapa de Calor',
      'icon': Icons.view_headline_outlined,
      'page': const HeatmapScreen(),
    },
    {
      'title': 'Gráfico de Pastel',
      'icon': Icons.pie_chart,
      'page': const ReviewScreen(),
    },
    {
      'title': 'Evolución del Rating',
      'icon': Icons.linear_scale,
      'page': const RatingChartScreen(),
    },
  ];

  DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Dos columnas
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: charts.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => charts[index]['page'],
                  ),
                );
              },
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(charts[index]['icon'], size: 50, color: Colors.blue),
                    const SizedBox(height: 10),
                    Text(
                      charts[index]['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
