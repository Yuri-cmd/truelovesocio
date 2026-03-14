import 'package:get/get.dart';
import 'package:truelovesocio/data/services/review_service.dart';
import 'package:truelovesocio/features/auth/controllers/auth_controller.dart';

class ReviewsController extends GetxController {
  final ReviewService _reviewService = Get.find<ReviewService>();
  final AuthController _authController = Get.find<AuthController>();

  final reviewsData = Rxn<Map<String, dynamic>>();
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadReviews();
  }

  Future<void> loadReviews() async {
    final socioId = _authController.socio.value?.id;
    if (socioId == null) return;

    isLoading.value = true;
    try {
      final response = await _reviewService.fetchRestaurantReviews(socioId);
      if (response.statusCode == 200) {
        reviewsData.value = response.data;
      }
    } catch (e) {
      Get.snackbar("Error", "No se pudieron cargar las evaluaciones: $e");
    } finally {
      isLoading.value = false;
    }
  }

  double get ratingPromedio => double.tryParse(reviewsData.value?["rating"]?.toString() ?? "0") ?? 0.0;
  int get totalReviews => reviewsData.value?["pedidoCount"] ?? 0;
  Map<String, dynamic> get ratingCounts => reviewsData.value?["ratingCounts"] ?? {};
  List<dynamic> get comentarios => reviewsData.value?["comentarios"] ?? [];
}
