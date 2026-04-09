import 'package:flutter/material.dart';
import 'package:get/get.dart';
import "package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart";
import 'package:truelovesocio/features/auth/controllers/auth_controller.dart';
import 'package:truelovesocio/features/orders/presentation/screens/historico_pedidos_screen.dart';
import 'package:truelovesocio/features/orders/presentation/screens/pedidos_view.dart';
import 'package:truelovesocio/features/menu/presentation/screens/menu_view.dart';
import 'package:truelovesocio/features/cuotas/presentation/screens/cuotas_view.dart';
import 'package:truelovesocio/features/reviews/presentation/screens/reviews_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PersistentTabController _controller;
  final AuthController authController = Get.find<AuthController>();
  int _lastIndex = 0;

  @override
  void initState() {
    super.initState();
    // Si no puede acceder (deuda), iniciar en la pestaña de cuotas (índice 3)
    int initialIndex = authController.puedeAcceder.value ? 0 : 3;
    _controller = PersistentTabController(initialIndex: initialIndex);
    _lastIndex = initialIndex;

    // Escuchar cambios en puedeAcceder para forzar el cambio de pestaña
    ever(authController.puedeAcceder, (bool puede) {
      if (!puede && _controller.index != 3) {
        Get.snackbar(
          "Acceso Restringido",
          "Se ha detectado una deuda pendiente. Regulariza tus pagos para continuar.",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        _controller.index = 3;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;

    return PersistentTabView(
      context,
      controller: _controller,
      screens: [
        const PedidosView(),
        const HistoricoPedidosScreen(),
        const MenuView(),
        const CuotasView(),
        const ReviewsView(),
        const SizedBox.shrink(),
      ],
      items: [
        PersistentBottomNavBarItem(
          icon: const Icon(Icons.receipt_long_rounded),
          inactiveIcon: const Icon(Icons.receipt_long_outlined),
          title: 'Pedidos',
          activeColorPrimary: Colors.red[700]!,
          inactiveColorPrimary: Colors.grey[500]!,
        ),
        PersistentBottomNavBarItem(
          icon: const Icon(Icons.history_rounded),
          inactiveIcon: const Icon(Icons.history_outlined),
          title: 'Historial',
          activeColorPrimary: Colors.red[700]!,
          inactiveColorPrimary: Colors.grey[500]!,
        ),
        PersistentBottomNavBarItem(
          icon: const Icon(Icons.restaurant_menu_rounded),
          inactiveIcon: const Icon(Icons.restaurant_menu_outlined),
          title: 'Menú',
          activeColorPrimary: Colors.red[700]!,
          inactiveColorPrimary: Colors.grey[500]!,
        ),
        PersistentBottomNavBarItem(
          icon: const Icon(Icons.account_balance_wallet_rounded),
          inactiveIcon: const Icon(Icons.account_balance_wallet_outlined),
          title: 'Pagos',
          activeColorPrimary: Colors.red[700]!,
          inactiveColorPrimary: Colors.grey[500]!,
        ),
        PersistentBottomNavBarItem(
          icon: const Icon(Icons.stars_rounded),
          inactiveIcon: const Icon(Icons.stars_outlined),
          title: 'Reseñas',
          activeColorPrimary: Colors.red[700]!,
          inactiveColorPrimary: Colors.grey[500]!,
        ),
        PersistentBottomNavBarItem(
          icon: const Icon(Icons.logout_rounded),
          title: 'Salir',
          activeColorPrimary: Colors.orange[800]!,
          inactiveColorPrimary: Colors.grey[500]!,
        ),
      ],
      backgroundColor: cardColor,
      handleAndroidBackButtonPress: true,
      resizeToAvoidBottomInset: true,
      stateManagement: true,
      decoration: NavBarDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        colorBehindNavBar: isDark ? Colors.black : const Color(0xFFF8F9FD),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : Colors.black.withAlpha(15),
            blurRadius: 15,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      navBarStyle: NavBarStyle.style6,
      onItemSelected: (int index) {
        if (index == 5) {
          _showLogoutDialog();
          Future.delayed(const Duration(milliseconds: 100), () {
            _controller.index = _lastIndex;
          });
        } else if (!authController.puedeAcceder.value && index != 3) {
          // Si tiene deuda y trata de ir a otra pestaña que no sea Cuotas (3) o Salir (5)
          Get.snackbar(
            "Acceso Restringido",
            "Debes regularizar tus pagos para acceder a esta sección.",
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
          );
          Future.delayed(const Duration(milliseconds: 100), () {
            _controller.index = 3;
          });
        } else {
          _lastIndex = index;
        }
      },
    );
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('Cerrar Sesión'),
          ],
        ),
        content: const Text('¿Estás seguro de que deseas cerrar sesión en Truelove Socio?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('CANCELAR', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              authController.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('CERRAR SESIÓN', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
