import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:truelovesocio/model/cuota_model.dart';
import 'package:truelovesocio/model/socio_model.dart';
import 'package:truelovesocio/data/services/cuota_service.dart';
import 'package:truelovesocio/features/auth/controllers/auth_controller.dart';

class CuotasController extends GetxController {
  final CuotaService _cuotaService = Get.find<CuotaService>();
  final AuthController _authController = Get.find<AuthController>();

  final isLoading = true.obs;
  final socio = Rxn<Socio>();
  final cuotaActiva = Rxn<CuotaActiva>();
  final periodoActualData = Rxn<Map<String, dynamic>>();
  final periodos = <PeriodoCuota>[].obs;
  final pagos = <PagoCuota>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadAllData();
  }

  Future<void> loadAllData() async {
    final user = _authController.socio.value;
    socio.value = user;
    
    if (user == null) {
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    try {
      final results = await Future.wait([
        _cuotaService.getCuotaActiva(user.id),
        _cuotaService.getMiPeriodoActual(user.id),
        _cuotaService.getMisPeriodos(user.id),
        _cuotaService.getMisPagos(user.id),
      ]);

      if (results[0].statusCode == 200 && results[0].data['success'] == true) {
        cuotaActiva.value = CuotaActiva.fromJson(results[0].data['data']);
      }
      
      if (results[1].statusCode == 200 && results[1].data['success'] == true) {
        periodoActualData.value = results[1].data['data'];
      }

      if (results[2].statusCode == 200 && results[2].data['success'] == true) {
        final List<dynamic> data = results[2].data['data'];
        periodos.assignAll(data.map((p) => PeriodoCuota.fromJson(p)).toList());
      }

      if (results[3].statusCode == 200 && results[3].data['success'] == true) {
        final List<dynamic> data = results[3].data['data'];
        pagos.assignAll(data.map((p) => PagoCuota.fromJson(p)).toList());
      }
    } catch (e) {
      Get.snackbar("Error", "Error al cargar datos de cuotas: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> registrarPago({
    required int periodoId,
    required String monto,
    required String operacion,
    required String metodo,
    required XFile image,
  }) async {
    if (socio.value == null) return false;

    try {
      final response = await _cuotaService.registrarPagoCuota(
        periodoId: periodoId,
        socioId: socio.value!.id,
        monto: monto,
        operacion: operacion,
        metodo: metodo,
        imagen: image,
      );
      
      if (response.statusCode == 200) {
        await loadAllData();
        Get.snackbar("Éxito", "Pago registrado correctamente. En revisión.");
        return true;
      }
      return false;
    } catch (e) {
      Get.snackbar("Error", "No se pudo registrar el pago: $e");
      return false;
    }
  }

  Future<List<PedidoPeriodo>> getPedidosPeriodo(int periodoId) async {
    if (socio.value == null) return [];
    try {
      final response = await _cuotaService.getPedidosPeriodo(periodoId, socio.value!.id);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data']['pedidos'];
        return data.map((p) => PedidoPeriodo.fromJson(p)).toList();
      }
      return [];
    } catch (e) {
      Get.snackbar("Error", "No se pudo obtener el detalle de pedidos");
      return [];
    }
  }
}
