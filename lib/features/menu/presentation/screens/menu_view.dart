import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truelovesocio/core/components/dish_item_widget.dart';
import 'package:truelovesocio/features/auth/controllers/auth_controller.dart';
import 'package:truelovesocio/features/menu/controllers/socio_menu_controller.dart';
import 'package:truelovesocio/features/menu/presentation/screens/category_view.dart';
import 'package:truelovesocio/features/menu/presentation/screens/create_menu_view.dart';
import 'package:truelovesocio/features/promociones/presentation/screens/promociones_view.dart';
import 'package:truelovesocio/features/adicionales/presentation/screens/biblioteca_adicionales_view.dart';
import 'package:truelovesocio/features/adicionales/presentation/screens/grupos_adicionales_view.dart';
import 'package:truelovesocio/features/agotados/presentation/screens/marcar_productos_agotados_view.dart';
import 'package:truelovesocio/features/agotados/presentation/screens/marcar_opciones_agotadas_view.dart';

class MenuView extends GetView<SocioMenuController> {
  const MenuView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SocioMenuController>()) {
      Get.put(SocioMenuController());
    }
    
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? null : const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('Mi Carta Digital', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => controller.loadAll(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(context, colorScheme, textTheme),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Obx(() {
              final list = controller.filteredDishes;
              if (controller.isLoading.value && list.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: Colors.red));
              }
              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        controller.searchQuery.value.isNotEmpty 
                            ? Icons.search_off_rounded 
                            : Icons.restaurant_menu_rounded, 
                        size: 80, 
                        color: Colors.grey[300]
                      ),
                      const SizedBox(height: 16),
                      Text(
                        controller.searchQuery.value.isNotEmpty 
                            ? 'No se encontraron resultados'
                            : 'No hay platos disponibles',
                        style: TextStyle(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final dish = list[index];
                  return DishItemWidget(
                    name: dish.titulo,
                    price: dish.precio,
                    isActive: dish.status == 'active',
                    imageUrl: dish.foto,
                    onToggle: (val) => controller.toggleDishStatus(dish, val),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const CreateMenuView())?.then((_) => controller.loadMenu()),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withAlpha(10) : Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey[300]!),
              ),
              child: TextField(
                onChanged: (v) => controller.searchQuery.value = v,
                decoration: InputDecoration(
                  hintText: 'Buscar en el menú...',
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.red[300], size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // Categories Title and Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CATEGORÍAS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.red[400],
                    letterSpacing: 1.2,
                  ),
                ),
                Obx(() => Text(
                  '${controller.dishes.length} PLATOS TOTALES',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                )),
              ],
            ),
          ),

          // Category Chips
          SizedBox(
            height: 40,
            child: Obx(() {
              final activeCategories = controller.categories.where((cat) => cat.estado == 1).toList();
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: activeCategories.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final isAll = index == 0;
                  final category = isAll ? null : activeCategories[index - 1];
                  final isSelected = controller.selectedCategoryId.value == (isAll ? null : category!.id);

                  return InkWell(
                    onTap: () => controller.filterByCategory(isAll ? null : category!.id),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Colors.red[700] 
                            : (isDark ? Colors.white.withAlpha(15) : Colors.grey[100]),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : (isDark ? Colors.white12 : Colors.transparent),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        isAll ? 'Todas' : category!.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey[700]),
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
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
          ListTile(
            leading: const Icon(Icons.campaign, color: Colors.red),
            title: const Text('Gestionar Promociones', style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {
              Get.back();
              Get.to(() => const PromocionesView());
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.list_alt_rounded, color: Colors.red),
            title: const Text('Biblioteca de Adicionales', style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {
              Get.back();
              Get.to(() => const BibliotecaAdicionalesView());
            },
          ),
          ListTile(
            leading: const Icon(Icons.layers_rounded, color: Colors.red),
            title: const Text('Grupos de Adicionales', style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {
              Get.back();
              Get.to(() => const GruposAdicionalesView());
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.remove_shopping_cart_rounded, color: Colors.deepOrange),
            title: const Text('Marcar Productos Agotados', style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {
              Get.back();
              Get.to(() => const MarcarProductosAgotadosView());
            },
          ),
          ListTile(
            leading: const Icon(Icons.block_rounded, color: Colors.deepOrange),
            title: const Text('Marcar Opciones Agotadas', style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {
              Get.back();
              Get.to(() => const MarcarOpcionesAgotadasView());
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
