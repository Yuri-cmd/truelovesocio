import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:truelovesocio/core/storage/secure_storage.dart';
import 'package:truelovesocio/data/services/auth_service.dart';
import 'package:truelovesocio/data/services/cuota_service.dart';
import 'package:truelovesocio/data/models/socio_model.dart';
import 'package:truelovesocio/core/routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  
  final isLoading = false.obs;
  final socio = Rxn<Socio>();
  final puedeAcceder = true.obs;
  final mensajeCuota = "".obs;
  final statusCuota = "".obs;

  @override
  void onInit() {
    super.onInit();
    loadSavedUser();
  }

  bool get isLoggedIn => socio.value != null;

  Future<void> loadSavedUser() async {
    final userStr = await SecureStorage.getUser();
    final prefs = await SharedPreferences.getInstance();
    
    // Cargar estado de acceso
    puedeAcceder.value = prefs.getBool('puedeAcceder') ?? true;
    mensajeCuota.value = prefs.getString('mensajeCuota') ?? '';
    statusCuota.value = prefs.getString('statusCuota') ?? '';

    if (userStr != null) {
      socio.value = Socio.fromJson(jsonDecode(userStr));
    } else {
      final oldSocio = prefs.getString('socio');
      if (oldSocio != null) {
        final decoded = jsonDecode(oldSocio);
        socio.value = Socio.fromJson(decoded);
        await SecureStorage.saveUser(oldSocio);
      }
    }
  }

  // Puente temporal: las sesiones guardadas antes de que el app empezara a
  // persistir el token de login se quedaron sin uno. En vez de forzar un
  // re-login (muchos socios no recuerdan su contraseña), pedimos uno nuevo
  // usando los datos que ya tenemos guardados localmente. Si falla, no pasa
  // nada: el interceptor de 401 ya redirige a login como respaldo.
  Future<void> ensureToken() async {
    if (socio.value == null) return;
    if (await SecureStorage.getToken() != null) return;

    try {
      final response = await _authService.renovarToken(socio.value!.id, socio.value!.documentNumber);
      final token = response.data?['token'];
      if (response.statusCode == 200 && token != null) {
        await SecureStorage.saveToken(token.toString());
      }
    } catch (_) {
      // Silencioso: si esto falla, el flujo normal de 401 se encarga después.
    }
  }

  Future<Map<String, dynamic>> loginWithQuota(String usuario, String password) async {
    try {
      isLoading.value = true;
      final response = await _authService.login(usuario, password);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data["status"] == "success" && data["socio"] != null) {
          final socioData = data["socio"];
          socio.value = Socio.fromJson(socioData);

          // Guardar estado de cuota
          if (data["estado_cuota"] != null) {
            puedeAcceder.value = data["estado_cuota"]["puede_acceder"] ?? true;
            mensajeCuota.value = data["estado_cuota"]["mensaje"] ?? '';
            statusCuota.value = data["estado_cuota"]["status"] ?? '';
          }

          await SecureStorage.saveUser(jsonEncode(socioData));

          if (data['token'] != null) {
            await SecureStorage.saveToken(data['token'].toString());
          }

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('socio', jsonEncode(socioData));
          await prefs.setBool('puedeAcceder', puedeAcceder.value);
          await prefs.setString('mensajeCuota', mensajeCuota.value);
          await prefs.setString('statusCuota', statusCuota.value);

          String? tokenFcm = prefs.getString('token_fcm');
          if (tokenFcm == null || tokenFcm.isEmpty) {
            try {
              tokenFcm = await FirebaseMessaging.instance.getToken();
              if (tokenFcm != null) await prefs.setString('token_fcm', tokenFcm);
            } catch (e) {
              throw Exception('Error obteniendo FCM token: $e');
            }
          }

          if (tokenFcm != null && tokenFcm.isNotEmpty) {
            await _authService.updateFcmToken(socio.value!.id, tokenFcm);
          }

          return {'success': true, 'data': data};
        }
        return {
          'success': false, 
          'message': data['message'] ?? 'Credenciales incorrectas',
          'data': data
        };
      }
      return {'success': false, 'message': 'Error en el servidor: ${response.statusCode}'};
    } catch (e) {
      if (e is DioException && e.response != null) {
        final data = e.response!.data;
        return {
          'success': false,
          'message': data is Map ? (data['message'] ?? 'Error de conexión') : 'Error de conexión',
          'data': data is Map ? data : null
        };
      }
      return {'success': false, 'message': 'Error de conexión'};
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await SecureStorage.clearSession();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('socio');
    socio.value = null;
    Get.offAllNamed(Routes.LOGIN);
  }

  /// Refresca el estado de acceso del socio consultando el API.
  /// Llamar después de registrar un pago para que el banner de
  /// "Acceso Restringido" desaparezca sin necesidad de cerrar sesión.
  Future<void> actualizarEstadoAcceso() async {
    if (socio.value == null) return;
    try {
      final cuotaService = Get.find<CuotaService>();
      final response = await cuotaService.verificarAcceso(socio.value!.id);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        puedeAcceder.value = data['puede_acceder'] ?? true;
        mensajeCuota.value = data['mensaje'] ?? '';
        statusCuota.value = data['motivo'] ?? '';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('puedeAcceder', puedeAcceder.value);
        await prefs.setString('mensajeCuota', mensajeCuota.value);
        await prefs.setString('statusCuota', statusCuota.value);
      }
    } catch (_) {
      // Silencioso: si falla la verificación no interrumpir al usuario
    }
  }
}
