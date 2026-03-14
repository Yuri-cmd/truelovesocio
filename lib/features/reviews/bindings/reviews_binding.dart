import 'package:get/get.dart';
import 'package:truelovesocio/features/reviews/controllers/reviews_controller.dart';

class ReviewsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReviewsController>(() => ReviewsController());
  }
}
