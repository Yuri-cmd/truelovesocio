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

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: 0);
  }

  @override
  Widget build(BuildContext context) {
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
          icon: const Icon(Icons.shopping_bag_outlined),
          title: 'Pedidos',
          activeColorPrimary: Colors.red,
          inactiveColorPrimary: Colors.grey,
        ),
        PersistentBottomNavBarItem(
          icon: const Icon(Icons.book),
          title: 'Historico',
          activeColorPrimary: Colors.red,
          inactiveColorPrimary: Colors.grey,
        ),
        PersistentBottomNavBarItem(
          icon: const Icon(Icons.menu_book_rounded),
          title: 'Menu',
          activeColorPrimary: Colors.red,
          inactiveColorPrimary: Colors.grey,
        ),
        PersistentBottomNavBarItem(
          icon: const Icon(Icons.receipt_long),
          title: 'Cuotas',
          activeColorPrimary: Colors.red,
          inactiveColorPrimary: Colors.grey,
        ),
        PersistentBottomNavBarItem(
          icon: const Icon(Icons.star),
          title: 'Evaluaciones',
          activeColorPrimary: Colors.red,
          inactiveColorPrimary: Colors.grey,
        ),
        PersistentBottomNavBarItem(
          icon: const Icon(Icons.exit_to_app),
          title: 'Cerrar',
          activeColorPrimary: Colors.red,
          inactiveColorPrimary: Colors.grey,
        ),
      ],
      navBarStyle: NavBarStyle.style6,
      onItemSelected: (int index) {
        if (index == 5) {
          _showLogoutDialog();
        }
      },
    );
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              authController.logout();
            },
            child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
