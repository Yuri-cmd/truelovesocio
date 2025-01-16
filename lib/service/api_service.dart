import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:truelovesocio/model/category_model.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:truelovesocio/model/menu_model.dart';

class ApiService {
  final String baseUrl = 'https://magusemail.com/truelove-back/public/api';

  Future<List<Category>> fetchCategories() async {
    String id_empresa = "1";
    final response = await http.get(
      Uri.parse('$baseUrl/categories/$id_empresa'),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Category.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar las categorías');
    }
  }

  Future<void> createCategory(String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/categories'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': name,
        'empresa_id': 1, // Agregar el id_empresa como estático
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Error al crear la categoría');
    }
  }

  Future<void> updateCategory(int id, String name) async {
    final response = await http.put(
      Uri.parse('$baseUrl/categories/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': name,
        'empresa_id': 1, // Agregar el id_empresa como estático
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar la categoría');
    }
  }

  Future<void> deleteCategory(int id) async {
    String empresa_id = "1";
    final response = await http.delete(
      Uri.parse('$baseUrl/categorias/$id/$empresa_id'),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar la categoría');
    }
  }

  Future<void> crearMenu(
    String titulo,
    String descripcion,
    XFile foto, // Cambiado para aceptar un archivo XFile
    double precio,
    String status,
    int categoriaId,
  ) async {
    var uri = Uri.parse('$baseUrl/crear/menus');

    // Crear una solicitud multipart
    var request =
        http.MultipartRequest('POST', uri)
          ..fields['titulo'] = titulo
          ..fields['descripcion'] = descripcion
          ..fields['precio'] = precio.toString()
          ..fields['status'] = status
          ..fields['categoria_id'] = categoriaId.toString()
          ..fields['empresa_id'] = '1'; // Id de la empresa

    // Agregar la imagen al cuerpo de la solicitud
    var file = await http.MultipartFile.fromPath(
      'foto', // El nombre del campo en el servidor
      foto.path, // La ruta de la imagen seleccionada
      contentType: MediaType(
        'image',
        'jpeg',
      ), // Cambiar según el tipo de imagen
    );

    request.files.add(file);

    // Enviar la solicitud
    var response = await request.send();

    // Verificar si la respuesta fue exitosa
    if (response.statusCode == 201) {
      print('Menú creado correctamente');
    } else {
      throw Exception('Error al crear el menú');
    }
  }

  Future<List<Menu>> fetchMenu() async {
    String idEmpresa = "1"; // ID de la empresa
    final response = await http.get(
      Uri.parse('$baseUrl/listar/menus/$idEmpresa'),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Menu.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar los menús');
    }
  }

  Future<void> updateDishStatus(int id, bool isActive) async {
    final response = await http.put(
      Uri.parse('$baseUrl/menu/$id/status'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'status': isActive ? 'active' : 'inactive'}),
    );

    if (response.statusCode == 200) {
      print('Estado actualizado correctamente');
    } else {
      throw Exception('Error al actualizar el estado');
    }
  }
}
