import 'dart:developer';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:truelovesocio/model/category_model.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:truelovesocio/model/cuota_model.dart';
import 'package:truelovesocio/model/heatmap_data.dart';
import 'package:truelovesocio/model/menu_model.dart';
import 'package:truelovesocio/model/pedido_model.dart';
import 'package:truelovesocio/model/rating_data.dart';
import 'package:truelovesocio/model/socio_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _productionUrl =
      'https://magusemail.com/truelove-back/public/api';
  static const String _localUrl =
      'http://192.168.100.50/truelove-back/public/api';

  // Cambiar este valor para alternar entre desarrollo y producción
  static const bool _useProduction = true;

  static String get baseUrl => _useProduction ? _productionUrl : _localUrl;

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

          // Enviar el token almacenado a la API
          String? tokenFcm = prefs.getString('token_fcm');

          if (tokenFcm != null && tokenFcm.isNotEmpty) {
            await updateFcmToken(data["socio"]['id'], tokenFcm);
          }
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

  static Future<Map<String, dynamic>?> loginWithQuotaValidation(
    String nroDocumento,
    String password,
  ) async {
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
          final prefs = await SharedPreferences.getInstance();
          prefs.setString('socio', jsonEncode(data["socio"]));

          // Enviar el token almacenado a la API
          String? tokenFcm = prefs.getString('token_fcm');

          if (tokenFcm != null && tokenFcm.isNotEmpty) {
            await updateFcmToken(data["socio"]['id'], tokenFcm);
          }

          // Retornar toda la respuesta incluyendo información de cuota
          return data;
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
    // Agregamos ?fecha=todas para que traiga pedidos de cualquier fecha que sigan activos
    final String apiUrl = '$baseUrl/socio/get/pedidos/$idBiker?fecha=hoy';
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

  Future<List<Pedido>> fetchPedidosConFiltros({
    String fecha = 'todas',
    String tipo = 'todos',
  }) async {
    final int? idBiker = await getUsuarioId();
    final String apiUrl =
        '$baseUrl/socio/get/pedidos/$idBiker?fecha=$fecha&tipo=$tipo';
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

  Future<bool> actualizarEstado(int id, int estado, {int tiempo = 0}) async {
    final response = await http.put(
      Uri.parse('$baseUrl/socio/update/estado/pedido/$id'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"estado": estado, "tiempo": tiempo}),
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

  Future<void> createCategory(
    String name, {
    List<CategorySchedule>? horarios,
  }) async {
    final int? idEmpresa = await getUsuarioId();
    final response = await http.post(
      Uri.parse('$baseUrl/categories'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': name,
        'empresa_id': idEmpresa, // Agregar el id_empresa como estático
        'horarios':
            horarios
                ?.map((e) => e.toJson())
                .toList(), // Enviar horarios como lista JSON
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Error al crear la categoría');
    }
  }

  Future<void> updateCategory(
    int id,
    String name, {
    List<CategorySchedule>? horarios,
  }) async {
    final int? idEmpresa = await getUsuarioId();
    final response = await http.put(
      Uri.parse('$baseUrl/categories/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': name,
        'empresa_id': idEmpresa, // Agregar el id_empresa como estático
        'horarios':
            horarios
                ?.map((e) => e.toJson())
                .toList(), // Enviar horarios como lista JSON
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

  Future<List<Menu>> fetchMenu({int? categoriaId}) async {
    final int? idEmpresa = await getUsuarioId();
    final String url =
        categoriaId != null
            ? '$baseUrl/listar/menus/$idEmpresa?categoria=$categoriaId'
            : '$baseUrl/listar/menus/$idEmpresa';

    final response = await http.get(Uri.parse(url));

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
      // Enviar ambos campos por compatibilidad con distintos backends
      body: json.encode({
        'status': isActive ? 'active' : 'inactive',
        'estado': isActive ? 'active' : 'inactive',
      }),
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

  Future<bool> actualizarEstadoRepartidor(int activo) async {
    try {
      final int? usuarioId = await getUsuarioId();
      final response = await http.post(
        Uri.parse('$baseUrl/socio/estado'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'activo': activo, 'id': usuarioId}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw ("Error status: ${response.statusCode}");
      }
    } catch (e) {
      //print("Error actualizando estado: $e");
    }
    return false;
  }

  static Future<void> updateLoggedUser(Socio socio) async {
    final prefs = await SharedPreferences.getInstance();
    final socioJson = jsonEncode(
      socio.toJson(),
    ); // Asegúrate de tener `toJson()` implementado
    await prefs.setString('socio', socioJson);
  }

  static Future<Map<String, dynamic>> sendCode(String email) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/socio/sendCode"),
        body: {'email': email},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        // Si el backend devuelve error con json (como en tu ejemplo)
        return {
          'success': false,
          'message': data['message'] ?? 'Error desconocido',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error en la consulta: $e'};
    }
  }

  static Future<Map<String, dynamic>> updatePassword(
    int id,
    String newPassword,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/socio/update-password');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id, 'password': newPassword}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': responseData['message']};
      } else {
        return {'success': false, 'message': responseData['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  Future<List<Map<String, dynamic>>> fetchPedidoById(int id) async {
    final String apiUrl = '$baseUrl/socio/get/pedido/$id';
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);

        if (decodedResponse is List) {
          return List<Map<String, dynamic>>.from(decodedResponse);
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

  Future<bool> verificarConfirmacionPago(int idPedido) async {
    final response = await http.put(
      Uri.parse('$baseUrl/socio/update/verificar/confirmacion/$idPedido'),
    );
    return response.statusCode == 200;
  }

  static Future<bool> updateFcmToken(int idBiker, String tokenFcm) async {
    final url = Uri.parse("$baseUrl/socio/update-token");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id_reparto": idBiker, "token_fcm": tokenFcm}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<void> updateCategoryStatus(int id, int estado) async {
    final int? idEmpresa = await getUsuarioId();
    final response = await http.put(
      Uri.parse('$baseUrl/categories/$id/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'estado': estado, 'empresa_id': idEmpresa}),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar el estado de la categoría');
    }
  }

  Future<Map<String, dynamic>> getAppVersion(String appName) async {
    try {
      String platform = Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'unknown');
      final response = await http.get(
        Uri.parse('$baseUrl/app-version/$appName?platform=$platform'),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'status': response.statusCode,
          'message': 'Error al obtener la versión',
        };
      }
    } catch (e) {
      return {'status': 500, 'message': 'Error de conexión'};
    }
  }

  static Future<void> acknowledgeNotification(
    String? notificationId,
    String status,
  ) async {
    if (notificationId == null || notificationId.isEmpty) return;

    try {
      final String baseUrl = _productionUrl;

      await http.post(
        Uri.parse('$baseUrl/notifications/update-status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'notification_id': notificationId, 'status': status}),
      );
    } catch (e) {
      log('Error acknowledging notification: $e');
    }
  }

  // --- CUOTAS ENDPOINTS ---

  static Future<CuotaActiva?> getCuotaActiva(int socioId) async {
    final url = Uri.parse('$baseUrl/socio/cuota-activa?socio_id=$socioId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return CuotaActiva.fromJson(data['data']);
        }
      }
    } catch (e) {
      log("Error fetching cuota activa: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getMiPeriodoActual(int socioId) async {
    final url = Uri.parse('$baseUrl/socio/mi-periodo-actual?socio_id=$socioId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
    } catch (e) {
      log("Error fetching periodo actual: $e");
    }
    return null;
  }

  static Future<List<PeriodoCuota>> getMisPeriodos(int socioId) async {
    final url = Uri.parse('$baseUrl/socio/mis-periodos?socio_id=$socioId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((p) => PeriodoCuota.fromJson(p))
              .toList();
        }
      }
    } catch (e) {
      log("Error fetching periodos: $e");
    }
    return [];
  }

  static Future<List<PagoCuota>> getMisPagos(int socioId) async {
    final url = Uri.parse('$baseUrl/socio/mis-pagos?socio_id=$socioId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((p) => PagoCuota.fromJson(p))
              .toList();
        }
      }
    } catch (e) {
      log("Error fetching pagos: $e");
    }
    return [];
  }

  static Future<List<PedidoPeriodo>> getPedidosPeriodo(int periodoId, int socioId) async {
    final url = Uri.parse('$baseUrl/socio/pedidos-periodo/$periodoId?socio_id=$socioId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null && data['data']['pedidos'] != null) {
          return (data['data']['pedidos'] as List)
              .map((p) => PedidoPeriodo.fromJson(p))
              .toList();
        }
      }
    } catch (e) {
      log("Error fetching pedidos periodo: $e");
    }
    return [];
  }

  static Future<bool> subirComprobante({
    required int socioId,
    required int cuotaSocioId,
    required XFile file,
    required String fechaPago,
    required String montoPagado,
    required String metodoPago,
    String? numeroOperacion,
    String? observaciones,
  }) async {
    final url = Uri.parse('$baseUrl/socio/subir-comprobante?socio_id=$socioId');
    try {
      var request = http.MultipartRequest('POST', url);
      request.fields['cuota_socio_id'] = cuotaSocioId.toString();
      request.fields['fecha_pago'] = fechaPago;
      request.fields['monto_pagado'] = montoPagado;
      request.fields['metodo_pago'] = metodoPago;
      if (numeroOperacion != null) request.fields['numero_operacion'] = numeroOperacion;
      if (observaciones != null) request.fields['observaciones'] = observaciones;

      request.files.add(await http.MultipartFile.fromPath(
        'comprobante_pago',
        file.path,
        contentType: MediaType('image', 'jpeg'),
      ));

      var response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      log("Error subir comprobante: $e");
      return false;
    }
  }

  static Future<bool> subirComprobantePeriodo({
    required int socioId,
    required int periodoId,
    required XFile file,
    required String fechaPago,
    required String montoPagado,
    required String metodoPago,
    String? numeroOperacion,
    String? observaciones,
  }) async {
    final url = Uri.parse('$baseUrl/socio/subir-comprobante-periodo?socio_id=$socioId');
    try {
      var request = http.MultipartRequest('POST', url);
      request.fields['periodo_id'] = periodoId.toString();
      request.fields['fecha_pago'] = fechaPago;
      request.fields['monto_pagado'] = montoPagado;
      request.fields['metodo_pago'] = metodoPago;
      if (numeroOperacion != null) request.fields['numero_operacion'] = numeroOperacion;
      if (observaciones != null) request.fields['observaciones'] = observaciones;

      request.files.add(await http.MultipartFile.fromPath(
        'comprobante_pago',
        file.path,
        contentType: MediaType('image', 'jpeg'),
      ));

      var response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      log("Error subir comprobante periodo: $e");
      return false;
    }
  }
}
