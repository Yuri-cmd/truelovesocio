import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:truelovesocio/model/heatmap_data.dart';
import 'package:truelovesocio/service/api_service.dart';

class HeatmapScreen extends StatefulWidget {
  const HeatmapScreen({super.key});

  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  List<HeatmapData> heatmapData = [];
  final ApiService apiService = ApiService(); // Instancia del servicio

  @override
  void initState() {
    super.initState();
    loadHeatmapData();
  }

  Future<void> loadHeatmapData() async {
    try {
      List<HeatmapData> data = await apiService.fetchHeatmapData();
      setState(() {
        heatmapData = data;
      });
    } catch (e) {
      throw('Error al obtener los datos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mapa de Calor - Pedidos')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SfCartesianChart(
          title: ChartTitle(text: 'Pedidos por Hora y Día'),
          primaryXAxis: CategoryAxis(title: AxisTitle(text: 'Hora del Día')),
          primaryYAxis: CategoryAxis(title: AxisTitle(text: 'Día de la Semana')),
          legend: Legend(isVisible: true),
          tooltipBehavior: TooltipBehavior(enable: true),
          series: <BubbleSeries<HeatmapData, String>>[
            BubbleSeries<HeatmapData, String>(
              dataSource: heatmapData,
              xValueMapper: (HeatmapData data, _) => data.hour,
              yValueMapper: (HeatmapData data, _) => data.day,
              sizeValueMapper: (HeatmapData data, _) => data.orders.toDouble(),
              pointColorMapper: (HeatmapData data, _) {
                if (data.rating >= 4.5) return Colors.green;
                if (data.rating >= 4.0) return Colors.lightGreen;
                if (data.rating >= 3.5) return Colors.yellow;
                return Colors.red;
              },
              dataLabelSettings: DataLabelSettings(isVisible: true),
            ),
          ],
        ),
      ),
    );
  }
}
