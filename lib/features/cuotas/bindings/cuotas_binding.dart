import 'package:get/get.dart';
import 'package:truelovesocio/features/cuotas/controllers/cuotas_controller.dart';

class CuotasBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CuotasController>(() => CuotasController());
  }
}
