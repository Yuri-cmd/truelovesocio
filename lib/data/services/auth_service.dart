import 'package:dio/dio.dart';
import 'package:truelovesocio/core/api/api_client.dart';

class AuthService {
  final Dio _dio = ApiClient.dio;

  Future<Response> login(String usuario, String password) async {
    return await _dio.post('socio/login', data: {
      'usuario': usuario,
      'password': password,
    });
  }

  Future<Response> updateFcmToken(int socioId, String tokenFcm) async {
    return await _dio.post('socio/update-token', data: {
      'id_reparto': socioId,
      'token_fcm': tokenFcm,
    });
  }

  Future<Response> sendCode(String email) async {
    // Note: This endpoint might expect multipart or urlencoded depending on old ApiService
    // Re-checking ApiService.sendCode: it used http.post with body: {'email': email}
    // and headers: none specified, so it's likely form-url-encoded or multipart.
    // By default Dio with a Map uses json.
    return await _dio.post('socio/sendCode', data: FormData.fromMap({'email': email}));
  }

  Future<Response> updatePassword(int id, String newPassword) async {
    return await _dio.post('socio/update-password', data: {
      'id': id,
      'password': newPassword,
    });
  }

  Future<Response> updateEstado(int id, int activo) async {
    return await _dio.post('socio/estado', data: {
      'id': id,
      'activo': activo,
    });
  }

  // Puente temporal para sesiones guardadas antes de que el app empezara a
  // persistir el token de login. No requiere contraseña.
  Future<Response> renovarToken(int id, String documentNumber) async {
    return await _dio.post('socio/renovar-token', data: {
      'id': id,
      'documentNumber': documentNumber,
    });
  }
}
