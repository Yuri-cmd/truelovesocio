import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truelovesocio/features/menu/controllers/socio_menu_controller.dart';
import 'package:truelovesocio/features/menu/presentation/screens/add_edit_category_screen.dart';

class CategoryView extends GetView<SocioMenuController> {
  const CategoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? null : const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('Categorías', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const AddEditCategoryScreen())?.then((_) => controller.loadCategories()),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.categories.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Colors.red));
        }
        if (controller.categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.category_outlined, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No hay categorías configuradas',
                  style: TextStyle(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: Colors.red,
          onRefresh: () => controller.loadCategories(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            itemCount: controller.categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final category = controller.categories[index];
              return _CategoryItem(category: category, controller: controller);
            },
          ),
        );
      }),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final dynamic category;
  final SocioMenuController controller;

  const _CategoryItem({required this.category, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = category.estado == 1;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: isDark 
            ? Border.all(color: isActive ? Colors.red.withAlpha(40) : Colors.white12, width: 0.5) 
            : Border.all(color: isActive ? Colors.red.withAlpha(20) : Colors.black.withAlpha(8)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.black.withAlpha(isActive ? 15 : 8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => Get.to(() => AddEditCategoryScreen(category: category))?.then((_) => controller.loadCategories()),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon Section
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: (isActive ? Colors.red : Colors.grey).withAlpha(20),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.folder_open_rounded,
                    color: isActive ? Colors.red[700] : Colors.grey[500],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Content Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isActive ? (isDark ? Colors.white : Colors.black87) : Colors.grey[500],
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            category.horarios.isEmpty ? Icons.access_time_rounded : Icons.event_note_rounded,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            category.horarios.isEmpty ? '24 Horas' : '${category.horarios.length} horarios',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Actions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isActive ? 'ACTIVA' : 'INACTIVA',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: isActive ? Colors.red[700] : Colors.grey[500],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Transform.scale(
                      scale: 0.8,
                      child: Obx(() {
                        // Accedemos a la categoría desde la lista observable para reactividad
                        final currentCat = controller.categories.firstWhere((c) => c.id == category.id);
                        return Switch(
                          value: currentCat.estado == 1,
                          onChanged: (val) => controller.toggleCategoryStatus(category, val),
                          activeThumbColor: Colors.red[700],
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
