import 'package:get/get.dart';
import 'package:truelovesocio/features/menu/controllers/socio_menu_controller.dart';

class SocioMenuBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SocioMenuController>(() => SocioMenuController());
  }
}
