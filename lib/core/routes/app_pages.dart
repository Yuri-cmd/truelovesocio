// ignore_for_file: constant_identifier_names

import 'package:get/get.dart';
import 'package:truelovesocio/features/auth/bindings/auth_binding.dart';
import 'package:truelovesocio/features/auth/presentation/screens/change_password_screen.dart';
import 'package:truelovesocio/features/auth/presentation/screens/email_verify_screen.dart';
import 'package:truelovesocio/features/auth/presentation/screens/login_screen.dart';
import 'package:truelovesocio/features/cuotas/bindings/cuotas_binding.dart';
import 'package:truelovesocio/features/cuotas/presentation/screens/cuotas_view.dart';
import 'package:truelovesocio/features/home/presentation/screens/home_screen.dart';
import 'package:truelovesocio/features/menu/bindings/menu_binding.dart';
import 'package:truelovesocio/features/menu/presentation/screens/add_edit_category_screen.dart';
import 'package:truelovesocio/features/orders/bindings/order_binding.dart';
import 'package:truelovesocio/features/orders/presentation/screens/historico_pedidos_screen.dart';
import 'package:truelovesocio/features/reviews/bindings/reviews_binding.dart';
import 'package:truelovesocio/features/reviews/presentation/screens/reviews_view.dart';
import 'package:truelovesocio/features/splash/bindings/splash_binding.dart';
import 'package:truelovesocio/features/splash/presentation/screens/splash_screen.dart';
import 'app_routes.dart';

class AppPages {
  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: Routes.SPLASH,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: Routes.LOGIN,
      page: () => const LoginScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.HOME,
      page: () => const HomeScreen(),
      bindings: [
        AuthBinding(),
        OrderBinding(),
        SocioMenuBinding(),
        ReviewsBinding(),
        CuotasBinding(),
      ],
    ),
    GetPage(
      name: Routes.EMAIL_VERIFY,
      page: () => const EmailVerifyScreen(),
    ),
    GetPage(
      name: Routes.CHANGE_PASSWORD,
      page: () => ChangePasswordScreen(id: Get.arguments),
    ),
    GetPage(
      name: Routes.ORDER_HISTORY,
      page: () => const HistoricoPedidosScreen(),
      binding: OrderBinding(),
    ),
    GetPage(
      name: Routes.CATEGORY_EDIT,
      page: () => AddEditCategoryScreen(category: Get.arguments),
      binding: SocioMenuBinding(),
    ),
    GetPage(
      name: Routes.CUOTAS,
      page: () => const CuotasView(),
      binding: CuotasBinding(),
    ),
    GetPage(
      name: Routes.REVIEWS,
      page: () => const ReviewsView(),
      binding: ReviewsBinding(),
    ),
  ];
}
