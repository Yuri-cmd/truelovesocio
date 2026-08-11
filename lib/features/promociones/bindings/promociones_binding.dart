import 'package:get/get.dart';
import 'package:truelovesocio/features/promociones/controllers/promociones_controller.dart';

class PromocionesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PromocionesController>(() => PromocionesController());
  }
}
