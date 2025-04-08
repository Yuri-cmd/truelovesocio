import 'dart:developer';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:truelovesocio/model/category_model.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:truelovesocio/model/heatmap_data.dart';
import 'package:truelovesocio/model/menu_model.dart';
import 'package:truelovesocio/model/pedido_model.dart';
import 'package:truelovesocio/model/rating_data.dart';
import 'package:truelovesocio/model/socio_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String baseUrl = 'https://magusemail.com/truelove-back/public/api';
  // static const String baseUrl =
  //     'http://192.168.100.50/truelove-back/public/api';

  static Future<Socio?> login(String nroDocumento, String password) async {
    final url = Uri.parse('$baseUrl/socio/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'usuario': nroDocumento, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["status"] == "success" && data["socio"] != null) {
          Socio socio = Socio.fromJson(data["socio"]);

          final prefs = await SharedPreferences.getInstance();
          prefs.setString('socio', jsonEncode(data["socio"]));

          return socio;
        } else {
          throw ("No se encontró la clave 'socio' en la respuesta.");
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Socio?> getLoggedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final conductorJson = prefs.getString('socio');

    if (conductorJson != null) {
      final Map<String, dynamic> decodedData = jsonDecode(conductorJson);
      return Socio.fromJson(decodedData);
    }

    return null;
  }

  static Future<int?> getUsuarioId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final conductorJson = prefs.getString('socio');
    if (conductorJson != null) {
      final Map<String, dynamic> decodedData = jsonDecode(conductorJson);
      Socio socio = Socio.fromJson(decodedData);
      return socio.id;
    }
    return null;
  }

  Future<List<Pedido>> fetchPedidos() async {
    final int? idBiker = await getUsuarioId();
    final String apiUrl = '$baseUrl/socio/get/pedidos/$idBiker';
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final dynamic decodedResponse = json.decode(response.body);

        // Verificar si la respuesta es una lista
        if (decodedResponse is List) {
          return decodedResponse
              .map((pedido) => Pedido.fromJson(pedido))
              .toList();
        } else {
          throw Exception('Formato inesperado de respuesta');
        }
      } else {
        throw Exception('Error al cargar los pedidos');
      }
    } catch (error) {
      throw Exception('Error al obtener los pedidos: $error');
    }
  }

  Future<bool> actualizarEstado(int id, int estado) async {
    final response = await http.put(
      Uri.parse('$baseUrl/socio/update/estado/pedido/$id'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"estado": estado}),
    );
    if (response.statusCode == 200) {
      return true; // Actualización exitosa
    } else {
      return false;
    }
  }

  Future<List<Category>> fetchCategories() async {
    final int? idEmpresa = await getUsuarioId();
    final response = await http.get(
      Uri.parse('$baseUrl/categories/$idEmpresa'),
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
        'empresa_id': 2, // Agregar el id_empresa como estático
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
        'empresa_id': 2, // Agregar el id_empresa como estático
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar la categoría');
    }
  }

  Future<void> deleteCategory(int id) async {
    final int? idEmpresa = await getUsuarioId();
    final response = await http.delete(
      Uri.parse('$baseUrl/categorias/$id/$idEmpresa'),
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
    final int? idEmpresa = await getUsuarioId();

    // Crear una solicitud multipart
    var request =
        http.MultipartRequest('POST', uri)
          ..fields['titulo'] = titulo
          ..fields['descripcion'] = descripcion
          ..fields['precio'] = precio.toString()
          ..fields['status'] = status
          ..fields['categoria_id'] = categoriaId.toString()
          ..fields['empresa_id'] = idEmpresa.toString(); // Id de la empresa

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
      log('Menú creado correctamente');
    } else {
      throw Exception('Error al crear el menú');
    }
  }

  Future<List<Menu>> fetchMenu() async {
    final int? idEmpresa = await getUsuarioId();
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
      log('Estado actualizado correctamente');
    } else {
      throw Exception('Error al actualizar el estado');
    }
  }

  Future<Map<String, dynamic>> fetchRestaurantReviews() async {
    final int? idEmpresa = await getUsuarioId();

    final url = Uri.parse("$baseUrl/getRestaurante/$idEmpresa");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Error al cargar las evaluaciones");
    }
  }

  static Future<Map<String, dynamic>> fetchDataReviewChart() async {
    final int? idEmpresa = await getUsuarioId();

    final response = await http.get(Uri.parse('$baseUrl/reviews/$idEmpresa'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<List<HeatmapData>> fetchHeatmapData() async {
    final int? idEmpresa = await getUsuarioId();
    final response = await http.get(Uri.parse('$baseUrl/heatmap/$idEmpresa'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body)['data'];
      return (data as List)
          .map(
            (item) => HeatmapData(
              hour: item['hour'].toString(),
              day: HeatmapData.dayToNumber(item['day']),
              orders: item['orders'],
              rating: double.parse(item['rating'].toString()),
            ),
          )
          .toList();
    } else {
      throw Exception('Error al cargar datos del heatmap');
    }
  }

  Future<List<RatingDataChart>> fetchRatingEvolution(String groupBy) async {
    final url = Uri.parse('$baseUrl/rating-evolution?group_by=$groupBy');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<dynamic> ratings = data['data'];

      return ratings
          .map(
            (item) => RatingDataChart(
              date: item['date'],
              rating: item['rating'].toDouble(),
            ),
          )
          .toList();
    } else {
      throw Exception('Error al cargar los datos del rating');
    }
  }
}
