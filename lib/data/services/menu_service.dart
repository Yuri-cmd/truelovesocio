import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:truelovesocio/core/api/api_client.dart';
import 'package:truelovesocio/data/models/category_model.dart';
import 'package:http_parser/http_parser.dart';

class MenuService {
  final Dio _dio = ApiClient.dio;

  Future<Response> fetchCategories(int idEmpresa) async {
    return await _dio.get('categories/$idEmpresa');
  }

  Future<Response> createCategory(int idEmpresa, String name, List<CategorySchedule>? horarios) async {
    return await _dio.post('categories', data: {
      'nombre': name,
      'empresa_id': idEmpresa,
      'horarios': horarios?.map((e) => e.toJson()).toList(),
    });
  }

  Future<Response> updateCategory(int id, int idEmpresa, String name, List<CategorySchedule>? horarios) async {
    return await _dio.put('categories/$id', data: {
      'nombre': name,
      'empresa_id': idEmpresa,
      'horarios': horarios?.map((e) => e.toJson()).toList(),
    });
  }

  Future<Response> deleteCategory(int id, int idEmpresa) async {
    return await _dio.delete('categorias/$id/$idEmpresa');
  }

  Future<Response> updateCategoryStatus(int id, int idEmpresa, int estado) async {
    return await _dio.put('categories/$id/status', data: {
      'estado': estado,
      'empresa_id': idEmpresa,
    });
  }

  Future<Response> fetchMenu(int idEmpresa, {int? categoriaId}) async {
    return await _dio.get('listar/menus/$idEmpresa', queryParameters: {
      if (categoriaId != null) 'categoria': categoriaId,
    });
  }

  Future<Response> updateDishStatus(int id, bool isActive) async {
    final status = isActive ? 'active' : 'inactive';
    return await _dio.put('menu/$id/status', data: {
      'status': status,
      'estado': status,
    });
  }

  Future<Response> crearMenu({
    required int idEmpresa,
    required String titulo,
    required String descripcion,
    required XFile foto,
    required double precio,
    required String status,
    required int categoriaId,
  }) async {
    final formData = FormData.fromMap({
      'titulo': titulo,
      'descripcion': descripcion,
      'precio': precio.toString(),
      'status': status,
      'categoria_id': categoriaId.toString(),
      'empresa_id': idEmpresa.toString(),
      'foto': await MultipartFile.fromFile(
        foto.path,
        filename: 'foto.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
    });

    return await _dio.post('crear/menus', data: formData);
  }
}
