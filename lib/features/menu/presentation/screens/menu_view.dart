import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truelovesocio/components/dish_item_widget.dart';
import 'package:truelovesocio/features/auth/controllers/auth_controller.dart';
import 'package:truelovesocio/features/menu/controllers/socio_menu_controller.dart';
import 'package:truelovesocio/main.dart';
import 'package:truelovesocio/features/menu/presentation/screens/category_view.dart';
import 'package:truelovesocio/features/menu/presentation/screens/create_menu_view.dart';

class MenuView extends GetView<SocioMenuController> {
  const MenuView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SocioMenuController>()) {
      Get.put(SocioMenuController());
    }
    
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
                onChanged: (val) => themeNotifier.setTheme(val ? ThemeMode.dark : ThemeMode.light),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(context, colorScheme, textTheme),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text('Explorar Menú', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    _buildFilters(colorScheme),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Obx(() {
                        if (controller.isLoading.value && controller.dishes.isEmpty) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (controller.dishes.isEmpty) {
                          return const Center(child: Text('No hay platos disponibles en esta categoría'));
                        }
                        return ListView.builder(
                          itemCount: controller.dishes.length,
                          itemBuilder: (context, index) {
                            final dish = controller.dishes[index];
                            return DishItemWidget(
                              name: dish.titulo,
                              price: dish.precio,
                              isActive: dish.status == 'active',
                              imageUrl: "https://magusemail.com/truelove-back/public/${dish.foto}",
                              onToggle: (val) => controller.toggleDishStatus(dish, val),
                            );
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const CreateMenuView())?.then((_) => controller.loadMenu()),
        backgroundColor: Colors.red,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilters(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Obx(() => DropdownButton<int?>(
          value: controller.selectedCategoryId.value,
          hint: const Text('Categoría'),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('Todas')),
            ...controller.categories.where((cat) => cat.estado == 1).map((cat) => DropdownMenuItem<int?>(
              value: cat.id,
              child: Text(cat.name),
            )),
          ],
          onChanged: (val) => controller.filterByCategory(val),
        )),
        IconButton(
          onPressed: () => controller.loadAll(),
          icon: const Icon(Icons.refresh),
          tooltip: 'Refrescar',
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.red),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Configuración', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.category, color: Colors.red),
            title: const Text('Gestionar Categorías', style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {
              Get.back();
              Get.to(() => const CategoryView())?.then((_) => controller.loadCategories());
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person_remove_outlined, color: Colors.grey),
            title: const Text('Eliminar Cuenta', style: TextStyle(color: Colors.grey)),
            onTap: () => _showDeleteAccountDialog(),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('¿Eliminar cuenta?'),
        content: const Text('Esta acción es irreversible y eliminará todos sus datos. ¿Desea continuar?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Get.find<AuthController>().logout();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sí, eliminar'),
          ),
        ],
      ),
    );
  }
}
