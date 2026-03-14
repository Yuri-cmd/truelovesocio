import 'package:get/get.dart';
import 'package:truelovesocio/model/menu_model.dart';
import 'package:truelovesocio/model/category_model.dart';
import 'package:truelovesocio/data/services/menu_service.dart';
import 'package:truelovesocio/features/auth/controllers/auth_controller.dart';

class SocioMenuController extends GetxController {
  final MenuService _menuService = Get.find<MenuService>();
  final AuthController _authController = Get.find<AuthController>();

  final dishes = <Menu>[].obs;
  final categories = <Category>[].obs;
  final isLoading = false.obs;
  final selectedCategoryId = Rxn<int>();

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    try {
      await Future.wait([
        loadCategories(),
        loadMenu(),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadCategories() async {
    final socioId = _authController.socio.value?.id;
    if (socioId == null) return;

    try {
      final response = await _menuService.fetchCategories(socioId);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        categories.assignAll(data.map((json) => Category.fromJson(json)).toList());
      }
    } catch (e) {
      Get.snackbar("Error", "Error al cargar categorías: $e");
    }
  }

  Future<void> loadMenu() async {
    final socioId = _authController.socio.value?.id;
    if (socioId == null) return;

    try {
      final response = await _menuService.fetchMenu(socioId, categoriaId: selectedCategoryId.value);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        dishes.assignAll(data.map((json) => Menu.fromJson(json)).toList());
      }
    } catch (e) {
      Get.snackbar("Error", "Error al cargar platos: $e");
    }
  }

  Future<void> toggleDishStatus(Menu dish, bool isActive) async {
    try {
      await _menuService.updateDishStatus(dish.id, isActive);
      dish.status = isActive ? 'active' : 'inactive';
      dishes.refresh();
      Get.snackbar("Éxito", "Estado del platillo actualizado");
    } catch (e) {
      Get.snackbar("Error", "Error al actualizar el estado: $e");
    }
  }

  Future<void> toggleCategoryStatus(Category category, bool isActive) async {
    final socioId = _authController.socio.value?.id;
    if (socioId == null) return;

    try {
      final nuevoEstado = isActive ? 1 : 0;
      await _menuService.updateCategoryStatus(category.id, socioId, nuevoEstado);
      category.estado = nuevoEstado;
      categories.refresh();
      Get.snackbar("Éxito", "Estado de categoría actualizado");
    } catch (e) {
      Get.snackbar("Error", "Error al actualizar el estado: $e");
    }
  }

  void filterByCategory(int? categoryId) {
    selectedCategoryId.value = categoryId;
    loadMenu();
  }
}
