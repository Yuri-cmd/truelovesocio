import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:truelovesocio/core/storage/secure_storage.dart';
import 'package:truelovesocio/data/services/auth_service.dart';
import 'package:truelovesocio/model/socio_model.dart';
import 'package:truelovesocio/core/routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  
  final isLoading = false.obs;
  final socio = Rxn<Socio>();

  @override
  void onInit() {
    super.onInit();
    loadSavedUser();
  }

  bool get isLoggedIn => socio.value != null;

  Future<void> loadSavedUser() async {
    final userStr = await SecureStorage.getUser();
    if (userStr != null) {
      socio.value = Socio.fromJson(jsonDecode(userStr));
    } else {
      final prefs = await SharedPreferences.getInstance();
      final oldSocio = prefs.getString('socio');
      if (oldSocio != null) {
        final decoded = jsonDecode(oldSocio);
        socio.value = Socio.fromJson(decoded);
        await SecureStorage.saveUser(oldSocio);
      }
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

          await SecureStorage.saveUser(jsonEncode(socioData));
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('socio', jsonEncode(socioData));

          String? tokenFcm = prefs.getString('token_fcm');
          if (tokenFcm != null && tokenFcm.isNotEmpty) {
            await _authService.updateFcmToken(socio.value!.id, tokenFcm);
          }

          return {'success': true, 'data': data};
        }
        return {'success': false, 'message': data['message'] ?? 'Credenciales incorrectas'};
      }
      return {'success': false, 'message': 'Error en el servidor: ${response.statusCode}'};
    } catch (e) {
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
}
