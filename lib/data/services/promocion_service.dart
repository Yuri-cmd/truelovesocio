import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:truelovesocio/core/api/api_client.dart';

class PromocionService {
  final Dio _dio = ApiClient.dio;

  Future<Response> fetchPromociones() async {
    return await _dio.get('socio/promociones');
  }

  Future<Response> crearPromocion({
    required String titulo,
    required String subtitulo,
    required bool estado,
    XFile? imagen,
  }) async {
    final formData = FormData.fromMap({
      'titulo': titulo,
      'subtitulo': subtitulo,
      'estado': estado ? '1' : '0',
      if (imagen != null)
        'imagen': await MultipartFile.fromFile(
          imagen.path,
          filename: 'imagen.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
    });

    return await _dio.post('socio/promociones', data: formData);
  }

  Future<Response> actualizarPromocion({
    required int id,
    required String titulo,
    required String subtitulo,
    required bool estado,
    XFile? imagen,
  }) async {
    final formData = FormData.fromMap({
      'titulo': titulo,
      'subtitulo': subtitulo,
      'estado': estado ? '1' : '0',
      // El backend solo parsea multipart en POST; se envía como POST con
      // _method=PUT (mismo enfoque que usa el panel web).
      '_method': 'PUT',
      if (imagen != null)
        'imagen': await MultipartFile.fromFile(
          imagen.path,
          filename: 'imagen.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
    });

    return await _dio.post('socio/promociones/$id', data: formData);
  }

  Future<Response> eliminarPromocion(int id) async {
    return await _dio.delete('socio/promociones/$id');
  }
}
