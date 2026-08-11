import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:truelovesocio/data/models/promocion_model.dart';
import 'package:truelovesocio/data/services/promocion_service.dart';

class PromocionesController extends GetxController {
  final PromocionService _promocionService = Get.find<PromocionService>();

  final promociones = <Promocion>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadPromociones();
  }

  Future<void> loadPromociones() async {
    isLoading.value = true;
    try {
      final response = await _promocionService.fetchPromociones();
      final List<dynamic> data = response.data['data'];
      promociones.assignAll(data.map((json) => Promocion.fromJson(json)).toList());
    } catch (e) {
      Get.snackbar("Error", "No se pudieron cargar tus promociones");
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> crearPromocion({
    required String titulo,
    required String subtitulo,
    required bool estado,
    XFile? imagen,
  }) async {
    try {
      await _promocionService.crearPromocion(
        titulo: titulo,
        subtitulo: subtitulo,
        estado: estado,
        imagen: imagen,
      );
      await loadPromociones();
      return true;
    } catch (e) {
      Get.snackbar("Error", "No se pudo crear la promoción");
      return false;
    }
  }

  Future<bool> actualizarPromocion({
    required int id,
    required String titulo,
    required String subtitulo,
    required bool estado,
    XFile? imagen,
  }) async {
    try {
      await _promocionService.actualizarPromocion(
        id: id,
        titulo: titulo,
        subtitulo: subtitulo,
        estado: estado,
        imagen: imagen,
      );
      await loadPromociones();
      return true;
    } catch (e) {
      Get.snackbar("Error", "No se pudo actualizar la promoción");
      return false;
    }
  }

  Future<void> eliminarPromocion(int id) async {
    try {
      await _promocionService.eliminarPromocion(id);
      promociones.removeWhere((p) => p.id == id);
      Get.snackbar("Éxito", "Promoción eliminada correctamente");
    } catch (e) {
      Get.snackbar("Error", "No se pudo eliminar la promoción");
    }
  }
}
