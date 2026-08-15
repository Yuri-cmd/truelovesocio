import 'package:dio/dio.dart';
import 'package:truelovesocio/core/api/api_client.dart';

class AdicionalService {
  final Dio _dio = ApiClient.dio;

  // --- Biblioteca de adicionales ---

  Future<Response> fetchAdicionales(int empresaId) async {
    return await _dio.get('adicionales/web/$empresaId');
  }

  Future<Response> createAdicional({
    required int empresaId,
    required String titulo,
    required String descripcion,
    required double precio,
    String status = 'active',
  }) async {
    return await _dio.post('adicionales/web', data: FormData.fromMap({
      'empresa_id': empresaId.toString(),
      'titulo': titulo,
      'descripcion': descripcion,
      'precio': precio.toString(),
      'status': status,
    }));
  }

  Future<Response> updateAdicional({
    required int id,
    required int empresaId,
    required String titulo,
    required String descripcion,
    required double precio,
    required String status,
  }) async {
    return await _dio.post('adicionales/web/$id', data: FormData.fromMap({
      '_method': 'PUT',
      'empresa_id': empresaId.toString(),
      'titulo': titulo,
      'descripcion': descripcion,
      'precio': precio.toString(),
      'status': status,
    }));
  }

  Future<Response> deleteAdicional(int id) async {
    return await _dio.delete('adicionales/web/$id');
  }

  // --- Marcar agotados / disponibles en lote ---

  Future<Response> marcarProductosAgotados(List<int> ids, String duracion) async {
    return await _dio.post('menu/agotar-lote', data: {'ids': ids, 'duracion': duracion});
  }

  Future<Response> marcarProductosDisponibles(List<int> ids) async {
    return await _dio.post('menu/disponible-lote', data: {'ids': ids});
  }

  Future<Response> marcarOpcionesAgotadas(List<int> ids, String duracion) async {
    return await _dio.post('adicionales/agotar-lote', data: {'ids': ids, 'duracion': duracion});
  }

  Future<Response> marcarOpcionesDisponibles(List<int> ids) async {
    return await _dio.post('adicionales/disponible-lote', data: {'ids': ids});
  }

  // --- Grupos de adicionales ---

  Future<Response> fetchGrupos(int empresaId) async {
    return await _dio.get('grupos-adicionales/$empresaId');
  }

  Future<Response> createGrupo({
    required int empresaId,
    required String nombre,
    required int minimo,
    required int maximo,
  }) async {
    return await _dio.post('grupos-adicionales', data: {
      'empresa_id': empresaId,
      'nombre': nombre,
      'minimo': minimo,
      'maximo': maximo,
    });
  }

  Future<Response> updateGrupo({
    required int id,
    required String nombre,
    required int minimo,
    required int maximo,
    String? estado,
  }) async {
    return await _dio.put('grupos-adicionales/$id', data: {
      'nombre': nombre,
      'minimo': minimo,
      'maximo': maximo,
      if (estado != null) 'estado': estado,
    });
  }

  Future<Response> deleteGrupo(int id) async {
    return await _dio.delete('grupos-adicionales/$id');
  }

  Future<Response> reordenarGrupos(List<Map<String, int>> grupos) async {
    return await _dio.post('grupos-adicionales/reordenar', data: {'grupos': grupos});
  }

  Future<Response> addItemToGrupo(int grupoId, int adicionalId, double precio) async {
    return await _dio.post('grupos-adicionales/$grupoId/items', data: {
      'adicional_id': adicionalId,
      'precio': precio,
    });
  }

  Future<Response> removeItemFromGrupo(int grupoId, int adicionalId) async {
    return await _dio.delete('grupos-adicionales/$grupoId/items/$adicionalId');
  }

  Future<Response> getAvailableItems(int grupoId) async {
    return await _dio.get('grupos-adicionales/$grupoId/disponibles');
  }
}
