import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truelovesocio/features/menu/controllers/socio_menu_controller.dart';
import 'package:truelovesocio/features/menu/presentation/screens/add_edit_category_screen.dart';

class CategoryView extends GetView<SocioMenuController> {
  const CategoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const AddEditCategoryScreen())?.then((_) => controller.loadCategories()),
        backgroundColor: Colors.red,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.categories.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.categories.isEmpty) {
          return const Center(child: Text('No hay categorías configuradas'));
        }
        return RefreshIndicator(
          onRefresh: () => controller.loadCategories(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.categories.length,
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withAlpha(25), blurRadius: 5, offset: const Offset(0, 3))],
      ),
      child: ListTile(
        title: Text(category.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        subtitle: Text(
          category.horarios.isEmpty ? 'Disponible 24 horas' : '${category.horarios.length} horarios configurados',
          style: TextStyle(color: category.horarios.isEmpty ? Colors.green : Colors.grey),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
              onPressed: () => Get.to(() => AddEditCategoryScreen(category: category))?.then((_) => controller.loadCategories()),
            ),
            Obx(() => Switch(
              value: controller.categories[controller.categories.indexOf(category)].estado == 1,
              onChanged: (val) => controller.toggleCategoryStatus(category, val),
              activeThumbColor: Colors.green,
            )),
          ],
        ),
      ),
    );
  }
}
