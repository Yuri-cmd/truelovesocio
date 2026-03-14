import 'package:dio/dio.dart';
import 'package:truelovesocio/core/api/api_client.dart';

class OrderService {
  final Dio _dio = ApiClient.dio;

  Future<Response> fetchPedidos(int socioId, {String fecha = 'hoy', String tipo = 'todos'}) async {
    return await _dio.get('socio/get/pedidos/$socioId', queryParameters: {
      'fecha': fecha,
      'tipo': tipo,
    });
  }

  Future<Response> fetchPedidoById(int id) async {
    return await _dio.get('socio/get/pedido/$id');
  }

  Future<Response> actualizarEstadoPedido(int id, int estado, {int tiempo = 0}) async {
    return await _dio.put('socio/update/estado/pedido/$id', data: {
      'estado': estado,
      'tiempo': tiempo,
    });
  }

  Future<Response> verificarConfirmacionPago(int idPedido) async {
    return await _dio.put('socio/update/verificar/confirmacion/$idPedido');
  }
}
