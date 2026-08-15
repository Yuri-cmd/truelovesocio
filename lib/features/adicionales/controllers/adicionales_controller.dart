import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:truelovesocio/data/models/adicional_model.dart';
import 'package:truelovesocio/data/services/adicional_service.dart';
import 'package:truelovesocio/features/auth/controllers/auth_controller.dart';

class AdicionalesController extends GetxController {
  final AdicionalService _service = Get.find<AdicionalService>();
  final AuthController _authController = Get.find<AuthController>();

  final adicionales = <Adicional>[].obs;
  final grupos = <GrupoAdicional>[].obs;
  final isLoading = false.obs;

  int? get empresaId => _authController.socio.value?.id;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    try {
      await Future.wait([loadAdicionales(), loadGrupos()]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadAdicionales() async {
    final id = empresaId;
    if (id == null) return;
    try {
      final response = await _service.fetchAdicionales(id);
      final List<dynamic> data = response.data;
      adicionales.assignAll(data.map((json) => Adicional.fromJson(json)).toList());
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron cargar los adicionales: $e');
    }
  }

  Future<void> loadGrupos() async {
    final id = empresaId;
    if (id == null) return;
    try {
      final response = await _service.fetchGrupos(id);
      final List<dynamic> data = response.data;
      grupos.assignAll(data.map((json) => GrupoAdicional.fromJson(json)).toList());
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron cargar los grupos: $e');
    }
  }

  Future<bool> createAdicional(String titulo, String descripcion, double precio) async {
    final id = empresaId;
    if (id == null) return false;
    try {
      await _service.createAdicional(empresaId: id, titulo: titulo, descripcion: descripcion, precio: precio);
      await loadAdicionales();
      return true;
    } catch (e) {
      Get.snackbar('Error', 'No se pudo crear el adicional: ${_errorMessage(e)}');
      return false;
    }
  }

  Future<bool> updateAdicional(Adicional adicional, {String? titulo, String? descripcion, double? precio, String? status}) async {
    final id = empresaId;
    if (id == null) return false;
    try {
      await _service.updateAdicional(
        id: adicional.id,
        empresaId: id,
        titulo: titulo ?? adicional.titulo,
        descripcion: descripcion ?? adicional.descripcion,
        precio: precio ?? double.tryParse(adicional.precio) ?? 0,
        status: status ?? adicional.status,
      );
      await Future.wait([loadAdicionales(), loadGrupos()]);
      return true;
    } catch (e) {
      Get.snackbar('Error', 'No se pudo actualizar el adicional: ${_errorMessage(e)}');
      return false;
    }
  }

  Future<bool> deleteAdicional(int id) async {
    try {
      await _service.deleteAdicional(id);
      await Future.wait([loadAdicionales(), loadGrupos()]);
      return true;
    } catch (e) {
      Get.snackbar('Error', 'No se pudo eliminar el adicional: ${_errorMessage(e)}');
      return false;
    }
  }

  Future<bool> createGrupo(String nombre, int minimo, int maximo) async {
    final id = empresaId;
    if (id == null) return false;
    try {
      await _service.createGrupo(empresaId: id, nombre: nombre, minimo: minimo, maximo: maximo);
      await loadGrupos();
      return true;
    } catch (e) {
      Get.snackbar('Error', 'No se pudo crear el grupo: ${_errorMessage(e)}');
      return false;
    }
  }

  Future<bool> updateGrupo(GrupoAdicional grupo, {String? nombre, int? minimo, int? maximo}) async {
    try {
      await _service.updateGrupo(
        id: grupo.id,
        nombre: nombre ?? grupo.nombre,
        minimo: minimo ?? grupo.minimo,
        maximo: maximo ?? grupo.maximo,
      );
      await loadGrupos();
      return true;
    } catch (e) {
      Get.snackbar('Error', 'No se pudo actualizar el grupo: ${_errorMessage(e)}');
      return false;
    }
  }

  Future<bool> deleteGrupo(int id) async {
    try {
      await _service.deleteGrupo(id);
      await loadGrupos();
      return true;
    } catch (e) {
      Get.snackbar('Error', 'No se pudo eliminar el grupo: ${_errorMessage(e)}');
      return false;
    }
  }

  Future<void> reordenarGrupos(List<GrupoAdicional> nuevoOrden) async {
    grupos.assignAll(nuevoOrden);
    try {
      await _service.reordenarGrupos(
        nuevoOrden.asMap().entries.map((e) => {'id': e.value.id, 'orden': e.key + 1}).toList(),
      );
    } catch (e) {
      Get.snackbar('Error', 'No se pudo reordenar: ${_errorMessage(e)}');
      await loadGrupos();
    }
  }

  Future<List<GrupoAdicionalItem>> getAvailableItems(int grupoId) async {
    try {
      final response = await _service.getAvailableItems(grupoId);
      final List<dynamic> data = response.data;
      return data.map((json) => GrupoAdicionalItem.fromJson(json)).toList();
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron cargar los adicionales disponibles: ${_errorMessage(e)}');
      return [];
    }
  }

  Future<bool> addItemToGrupo(int grupoId, int adicionalId, double precio) async {
    try {
      await _service.addItemToGrupo(grupoId, adicionalId, precio);
      await loadGrupos();
      return true;
    } catch (e) {
      Get.snackbar('Error', 'No se pudo agregar el adicional al grupo: ${_errorMessage(e)}');
      return false;
    }
  }

  Future<bool> removeItemFromGrupo(int grupoId, int adicionalId) async {
    try {
      await _service.removeItemFromGrupo(grupoId, adicionalId);
      await loadGrupos();
      return true;
    } catch (e) {
      Get.snackbar('Error', 'No se pudo quitar el adicional del grupo: ${_errorMessage(e)}');
      return false;
    }
  }

  String _errorMessage(Object e) {
    if (e is DioException && e.response?.data is Map && e.response?.data['message'] != null) {
      return e.response?.data['message'];
    }
    return e.toString();
  }
}
