import 'package:flutter/material.dart';
import "package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart";
import 'package:truelovesocio/screen/historico_pedidos_screen.dart';
import 'package:truelovesocio/screen/screens.dart';
import 'package:truelovesocio/theme/app_theme.dart';
import 'package:truelovesocio/view/views.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PersistentTabController _controller;
  bool isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: 0);
  }

  Future<void> logout(BuildContext context) async {
    setState(() {
      isLoggingOut = true;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('socio');
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      // Usar Future.microtask para asegurarse de que el widget ya no está en el árbol
      Future.microtask(() {
        if (!context.mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoggingOut) {
      // Retorna un widget vacío para desmontar el tab bar antes de navegar
      return const SizedBox.shrink();
    }

    return PersistentTabView(
      context,
      controller: _controller,
      screens: [
        const PedidosView(),
        const HistoricoPedidosScreen(),
        const MenuView(),
        const CuotasScreen(),
        const ReviewView(),
        const SizedBox.shrink(),
      ],
      items: [
        PersistentBottomNavBarItem(
          icon: const Icon(Icons.shopping_bag_outlined),
          title: 'Pedidos',
          activeColorPrimary: AppTheme.primary,
          inactiveColorPrimary: Colors.grey,
        ),
        PersistentBottomNavBarItem(
          icon: const Icon(Icons.book),
          title: 'Historico',
          activeColorPrimary: AppTheme.primary,
          inactiveColorPrimary: Colors.grey,
        ),
        PersistentBottomNavBarItem(
          icon: const Icon(Icons.menu_book_rounded),
          title: 'Menu',
          activeColorPrimary: AppTheme.primary,
          inactiveColorPrimary: Colors.grey,
        ),
        PersistentBottomNavBarItem(
          icon: const Icon(Icons.receipt_long),
          title: 'Cuotas',
          activeColorPrimary: AppTheme.primary,
          inactiveColorPrimary: Colors.grey,
        ),
        PersistentBottomNavBarItem(
          icon: const Icon(Icons.star),
          title: 'Evaluaciones',
          activeColorPrimary: AppTheme.primary,
          inactiveColorPrimary: Colors.grey,
        ),
        PersistentBottomNavBarItem(
          icon: const Icon(Icons.exit_to_app),
          title: 'Cerrar',
          activeColorPrimary: AppTheme.primary,
          inactiveColorPrimary: Colors.grey,
        ),
      ],
      navBarStyle: NavBarStyle.style6,
      onItemSelected: (int index) async {
        if (index == 5 && !isLoggingOut) {
          await logout(context);
        }
      },
    );
  }
}
