import 'package:get/get.dart';
import 'package:truelovesocio/features/auth/controllers/auth_controller.dart';
import 'package:truelovesocio/data/services/auth_service.dart';
import 'package:truelovesocio/data/services/order_service.dart';
import 'package:truelovesocio/data/services/menu_service.dart';
import 'package:truelovesocio/data/services/review_service.dart';
import 'package:truelovesocio/data/services/cuota_service.dart';
import 'package:truelovesocio/data/services/misc_service.dart';
import 'package:truelovesocio/data/services/promocion_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Services
    Get.put(AuthService(), permanent: true);
    Get.put(OrderService(), permanent: true);
    Get.put(MenuService(), permanent: true);
    Get.put(ReviewService(), permanent: true);
    Get.put(CuotaService(), permanent: true);
    Get.put(MiscService(), permanent: true);
    Get.put(PromocionService(), permanent: true);

    // Controllers
    Get.put<AuthController>(AuthController(), permanent: true);
  }
}
