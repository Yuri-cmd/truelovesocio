import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:truelovesocio/service/api_service.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  List<RatingData> ratingCounts = [];
  List<RatingDateData> ratingsByDate = [];
  int totalRatings = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await ApiService.fetchDataReviewChart();
      setState(() {
        totalRatings = data['totalRatings'];
        ratingCounts =
            (data['ratingCounts'] as List)
                .map((item) => RatingData(item['star'], item['count']))
                .toList();
        ratingsByDate =
            (data['ratingsByDate'] as List)
                .map((item) => RatingDateData(item['date'], item['count']))
                .toList();
      });
    } catch (e) {
      throw('Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Evaluaciones')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Evaluaciones: $totalRatings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            // Gráfico de Distribución de Calificaciones
            Expanded(
              child: SfCartesianChart(
                title: ChartTitle(text: 'Distribución de Calificaciones'),
                primaryXAxis: CategoryAxis(),
                series: <CartesianSeries>[
                  ColumnSeries<RatingData, int>(
                    dataSource: ratingCounts,
                    xValueMapper: (RatingData data, _) => data.star,
                    yValueMapper: (RatingData data, _) => data.count,
                    dataLabelSettings: DataLabelSettings(isVisible: true),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Gráfico de Evolución del Rating en el tiempo
            Expanded(
              child: SfCartesianChart(
                title: ChartTitle(text: 'Evolución del Rating'),
                primaryXAxis: CategoryAxis(),
                series: <CartesianSeries>[
                  LineSeries<RatingDateData, String>(
                    dataSource: ratingsByDate,
                    xValueMapper: (RatingDateData data, _) => data.date,
                    yValueMapper: (RatingDateData data, _) => data.count,
                    dataLabelSettings: DataLabelSettings(isVisible: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Clases de datos para las gráficas
class RatingData {
  final int star;
  final int count;
  RatingData(this.star, this.count);
}

class RatingDateData {
  final String date;
  final int count;
  RatingDateData(this.date, this.count);
}
