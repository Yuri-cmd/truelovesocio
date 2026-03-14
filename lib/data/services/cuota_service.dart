import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:truelovesocio/core/api/api_client.dart';
import 'package:http_parser/http_parser.dart';

class CuotaService {
  final Dio _dio = ApiClient.dio;

  Future<Response> getCuotaActiva(int socioId) async {
    return await _dio.get('socio/cuota-activa', queryParameters: {'socio_id': socioId});
  }

  Future<Response> getMiPeriodoActual(int socioId) async {
    return await _dio.get('socio/mi-periodo-actual', queryParameters: {'socio_id': socioId});
  }

  Future<Response> getMisPeriodos(int socioId) async {
    return await _dio.get('socio/mis-periodos', queryParameters: {'socio_id': socioId});
  }

  Future<Response> getMisPagos(int socioId) async {
    return await _dio.get('socio/mis-pagos', queryParameters: {'socio_id': socioId});
  }

  Future<Response> getPedidosPeriodo(int periodoId, int socioId) async {
    return await _dio.get('socio/pedidos-periodo/$periodoId', queryParameters: {'socio_id': socioId});
  }

  Future<Response> registrarPagoCuota({
    required int socioId,
    required int periodoId,
    required String monto,
    required String operacion,
    required String metodo,
    required XFile imagen,
    String? observaciones,
  }) async {
    final formData = FormData.fromMap({
      'socio_id': socioId.toString(),
      'periodo_id': periodoId.toString(),
      'fecha_pago': DateTime.now().toIso8601String().split('T')[0], // yyyy-MM-dd
      'monto_pagado': monto,
      'metodo_pago': metodo,
      'numero_operacion': operacion,
      if (observaciones != null) 'observaciones': observaciones,
      'comprobante_pago': await MultipartFile.fromFile(
        imagen.path,
        filename: 'comprobante.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
    });

    return await _dio.post('socio/subir-comprobante-periodo', 
      queryParameters: {'socio_id': socioId},
      data: formData
    );
  }
}
