import 'package:flutter/material.dart';
import "package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart";
import 'package:truelovesocio/components/components.dart';
import 'package:truelovesocio/screen/screens.dart';
import 'package:truelovesocio/theme/app_theme.dart';
import 'package:truelovesocio/view/views.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
            targetView: Material(
              child: InkWell(
                onTap: () async {
                  Navigator.pop(context);
                  await Future.delayed(Duration(milliseconds: 300));
                  logout(context);
                },
                child: ListTile(
                  leading: Icon(Icons.exit_to_app),
                  title: Text("Cerrar sesión"),
                ),
              ),
            ),
          ),
        ],
      ),

      body: PersistentTabView(
        context,
        screens: [
          const PedidosView(),
          DashboardScreen(),
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

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('socio'); // Eliminar usuario guardado

    // Esperar un poco para evitar conflictos con Navigator
    await Future.delayed(Duration(milliseconds: 300));

    // Redirigir a la pantalla de login y eliminar historial de navegación
    Navigator.of(context, rootNavigator: true).pushReplacementNamed('/login');
  }
}
