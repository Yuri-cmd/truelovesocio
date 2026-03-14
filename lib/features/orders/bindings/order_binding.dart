import 'package:get/get.dart';
import 'package:truelovesocio/features/orders/controllers/orders_controller.dart';

class OrderBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OrdersController>(() => OrdersController());
  }
}
