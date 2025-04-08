import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:truelovesocio/model/rating_data.dart';
import 'package:truelovesocio/service/api_service.dart';

class RatingChartScreen extends StatefulWidget {
  const RatingChartScreen({super.key});

  @override
  State<RatingChartScreen> createState() => _RatingChartScreenState();
}

class _RatingChartScreenState extends State<RatingChartScreen> {
  List<RatingDataChart> ratingData = [];
  String selectedGroupBy = 'daily'; // Opciones: daily, weekly, monthly
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  // Función para obtener datos de la API
  Future<void> fetchData() async {
    try {
      final data = await ApiService().fetchRatingEvolution(selectedGroupBy);
      setState(() {
        ratingData = data;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      throw ('Error al cargar datos: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evolución del Rating')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Dropdown para seleccionar el tipo de agrupación
            DropdownButton<String>(
              value: selectedGroupBy,
              onChanged: (String? newValue) {
                setState(() {
                  selectedGroupBy = newValue!;
                  isLoading = true;
                });
                fetchData(); // Llamar API con la nueva opción
              },
              items: [
                DropdownMenuItem(value: 'daily', child: Text('Diario')),
                DropdownMenuItem(value: 'weekly', child: Text('Semanal')),
                DropdownMenuItem(value: 'monthly', child: Text('Mensual')),
              ],
            ),

            const SizedBox(height: 20),

            // Mostrar indicador de carga mientras se obtienen los datos
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                  child: SfCartesianChart(
                    title: ChartTitle(text: 'Evolución del Rating'),
                    primaryXAxis: CategoryAxis(title: AxisTitle(text: 'Fecha')),
                    primaryYAxis: NumericAxis(
                      title: AxisTitle(text: 'Rating Promedio'),
                    ),
                    tooltipBehavior: TooltipBehavior(enable: true),
                    series: <LineSeries<RatingDataChart, String>>[
                      LineSeries<RatingDataChart, String>(
                        dataSource: ratingData,
                        xValueMapper: (RatingDataChart data, _) => data.date,
                        yValueMapper: (RatingDataChart data, _) => data.rating,
                        dataLabelSettings: const DataLabelSettings(
                          isVisible: true,
                        ),
                        color: Colors.blue,
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
