import 'package:flutter/material.dart';
import 'package:truelovesocio/components/components.dart';
import 'package:truelovesocio/model/menu_model.dart';
import 'package:truelovesocio/service/api_service.dart';
import 'package:truelovesocio/view/category_view.dart';
import 'package:truelovesocio/view/crear_menu_view.dart';
// Importa el setThemeMode si lo tienes
import 'package:truelovesocio/main.dart';

class MenuView extends StatefulWidget {
  const MenuView({super.key});

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  List<Menu> dishes = [];

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  void _loadMenu() {
    ApiService()
        .fetchMenu()
        .then((menus) {
          setState(() {
            dishes = menus;
          });
        })
        .catchError((e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cargar los menús: $e')),
          );
        });
  }

  void _toggleDishStatus(Menu dish, bool isActive) {
    ApiService()
        .updateDishStatus(dish.id, isActive)
        .then((_) {
          setState(() {
            dish.status = isActive ? 'active' : 'inactive';
          });
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Estado del platillo actualizado')),
          );
        })
        .catchError((e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar el estado: $e')),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        title: const Text("Menú"),
        actions: [
          Row(
            children: [
              Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: colorScheme.onPrimary),
              Switch(
                value: isDark,
                onChanged: (val) {
                  setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                },
              ),
              const SizedBox(width: 8),
            ],
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: colorScheme.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Opciones',
                    style: textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.category, color: colorScheme.primary),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Producto',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CategoryView(),
                        ),
                      );
                    },
                    child: Text(
                      'Categorías',
                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.secondary),
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CategoryView(),
                        ),
                      );
                    },
                    child: Text(
                      'Adicional',
                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.secondary),
                    ),
                  ),
                ],
              ),
              onTap: () {},
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Main Container
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        'Menú',
                        style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DropdownButton<String>(
                          value: 'Menú Almuerzo',
                          items: ['Menú Almuerzo', 'Menú Cena']
                              .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {},
                        ),
                        TextButton.icon(
                          onPressed: _loadMenu,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Cambios'),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Platos principales',
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: dishes.length,
                        itemBuilder: (context, index) {
                          final dish = dishes[index];
                          return DishItemWidget(
                            name: dish.titulo,
                            price: dish.precio,
                            isActive: dish.status == 'active',
                            imageUrl:
                                "https://magusemail.com/truelove-back/public/${dish.foto}",
                            onToggle: (val) {
                              _toggleDishStatus(dish, val);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CrearMenuView(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [Icon(Icons.add)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}