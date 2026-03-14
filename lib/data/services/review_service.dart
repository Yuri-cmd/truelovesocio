import 'package:dio/dio.dart';
import 'package:truelovesocio/core/api/api_client.dart';

class ReviewService {
  final Dio _dio = ApiClient.dio;

  Future<Response> fetchRestaurantReviews(int idEmpresa) async {
    return await _dio.get('getRestaurante/$idEmpresa');
  }

  Future<Response> fetchDataReviewChart(int idEmpresa) async {
    return await _dio.get('reviews/$idEmpresa');
  }

  Future<Response> fetchHeatmapData(int idEmpresa) async {
    return await _dio.get('heatmap/$idEmpresa');
  }

  Future<Response> fetchRatingEvolution(String groupBy) async {
    return await _dio.get('rating-evolution', queryParameters: {'group_by': groupBy});
  }
}
