import 'package:flutter/material.dart';
import "package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart";
import 'package:truelovesocio/components/components.dart';
import 'package:truelovesocio/theme/app_theme.dart';
import 'package:truelovesocio/view/views.dart';

// Definir un GlobalKey para el Scaffold
final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: CustomNavOption(
        options: [
          NavOption(
            title: 'Evaluaciones',
            icon: Icons.star,
            targetView: const ReviewView(),
          ),
          NavOption(
            title: 'Cerrar sesión',
            icon: Icons.exit_to_app,
            targetView: _buildScreen('Cerrar sesión', Colors.red),
          ),
        ],
      ),
      body: PersistentTabView(
        context,
        screens: [
          // Pantalla principal
          _buildScreen('Home', Colors.blue),
          // Otra pantalla
          _buildScreen('Home', Colors.blue),
          const MenuView(),
          _buildScreen('Settings', Colors.red),
        ],
        items: [
          PersistentBottomNavBarItem(
            icon: const Icon(Icons.shopping_bag_outlined),
            title: 'Pedidos',
            activeColorPrimary: AppTheme.primary,
            inactiveColorPrimary: Colors.grey,
          ),
          PersistentBottomNavBarItem(
            icon: const Icon(Icons.dashboard),
            title: 'Tablero',
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
            icon: const Icon(Icons.list),
            title: 'Más',
            activeColorPrimary: AppTheme.primary,
            inactiveColorPrimary: Colors.grey,
            onPressed: (dynamic) {
              // Aquí mostramos el Drawer cuando se presiona "Más"
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
        navBarStyle: NavBarStyle.style6,
      ),
    );
  }

  Widget _buildScreen(String title, Color color) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: color),
      body: Center(
        child: Text(
          '$title Screen',
          style: const TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
      backgroundColor: color,
    );
  }
}
