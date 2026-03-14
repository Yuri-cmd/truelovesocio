import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truelovesocio/features/reviews/controllers/reviews_controller.dart';

class ReviewsView extends GetView<ReviewsController> {
  const ReviewsView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(ReviewsController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluaciones'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.reviewsData.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.reviewsData.value == null) {
          return const Center(child: Text("No hay datos disponibles"));
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadReviews(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildRatingBars(),
                const SizedBox(height: 16),
                const Divider(),
                const Text(
                  'Comentarios recientes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildCommentsList(),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              controller.ratingPromedio.toStringAsFixed(1),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < controller.ratingPromedio.round() ? Icons.star : Icons.star_border,
                      color: Colors.red,
                      size: 24,
                    );
                  }),
                ),
                Text(
                  '${controller.totalReviews} evaluaciones',
                  style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingBars() {
    return Column(
      children: [
        _buildRatingBar(5, controller.ratingCounts["5"] ?? 0),
        _buildRatingBar(4, controller.ratingCounts["4"] ?? 0),
        _buildRatingBar(3, controller.ratingCounts["3"] ?? 0),
        _buildRatingBar(2, controller.ratingCounts["2"] ?? 0),
        _buildRatingBar(1, controller.ratingCounts["1"] ?? 0),
      ],
    );
  }

  Widget _buildRatingBar(int stars, int count) {
    double percentage = controller.totalReviews > 0 ? count / controller.totalReviews : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text('$stars estrellas', style: const TextStyle(fontSize: 12))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                color: Colors.red,
                backgroundColor: Colors.grey[200],
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 30, child: Text('($count)', style: const TextStyle(fontSize: 12, color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.comentarios.length,
      itemBuilder: (context, index) {
        final comentario = controller.comentarios[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFFFEBEE),
              child: Icon(Icons.star, color: Colors.red, size: 20),
            ),
            title: Text(
              comentario['comentario'] ?? 'Sin comentario',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              "Por ${comentario['cliente']}",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
        );
      },
    );
  }
}
