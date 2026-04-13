import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:truelovesocio/core/storage/secure_storage.dart';
import 'package:truelovesocio/data/services/auth_service.dart';
import 'package:truelovesocio/data/services/order_service.dart';
import 'package:truelovesocio/data/models/pedido_model.dart';
import 'package:truelovesocio/data/models/socio_model.dart';
import 'package:truelovesocio/features/orders/presentation/screens/seguimiento_pedido_view.dart';
import 'dart:convert';

class PedidosHelper {
  static Future<void> navegarASeguimiento(Pedido pedido) async {
    await Get.to(() => SeguimientoPedidoView(pedido: pedido));
  }

  static Future<int?> mostrarDialogoTiempo(BuildContext context) async {
    final TextEditingController controller = TextEditingController();
    return await Get.dialog<int>(
      AlertDialog(
        title: const Text('Tiempo de preparación'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Minutos estimados',
            hintText: 'Ej: 20',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final String text = controller.text;
              final int? minutos = int.tryParse(text);
              Get.back(result: minutos);
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  static Future<bool> mostrarAlertaConfirmacion(
    BuildContext context,
    int estado,
  ) async {
    return await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Confirmación'),
            content: Text(
              estado == 0
                  ? '¿Estás seguro de cancelar este pedido?'
                  : '¿Marcar pedido como listo?',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                child: const Text('Sí'),
              ),
            ],
          ),
        ) ??
        false;
  }

  static Future<void> cambiarEstadoSocio(
    BuildContext context,
    int estadoActual,
    Function(int) onEstadoActualizado,
  ) async {
    final nuevoEstado = estadoActual == 1 ? 0 : 1;
    final AuthService authService = Get.find<AuthService>();

    final confirmar = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmar cambio de estado'),
        content: Text(
          '¿Estás seguro de ${nuevoEstado == 1 ? 'activar' : 'desactivar'} al local?',
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Get.back(result: false),
          ),
          ElevatedButton(
            child: const Text('Confirmar'),
            onPressed: () => Get.back(result: true),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final userJson = await SecureStorage.getUser();
    if (userJson == null) return;
    final socio = Socio.fromJson(jsonDecode(userJson));

    // Mostrar diálogo de carga
    Get.dialog(
      Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(color: Colors.red),
                SizedBox(height: 16),
                Text('Actualizando estado...', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      final response = await authService.updateEstado(socio.id, nuevoEstado);
      Get.back(); // Cerrar diálogo de carga

      if (response.statusCode == 200) {
        socio.activo = nuevoEstado;
        await SecureStorage.saveUser(jsonEncode(socio.toJson()));
        onEstadoActualizado(nuevoEstado);
        Get.snackbar("Éxito", "Estado actualizado correctamente.", backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar("Error", "Error al actualizar el estado (${response.statusCode}).", backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.back(); // Cerrar diálogo de carga
      Get.snackbar(
        "Error de conexión",
        "No se pudo conectar con el servidor. Revisa tu internet e intenta de nuevo.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      debugPrint("Error updating socio state: $e");
    }
  }

  static Future<void> actualizarEstadoPedido({
    required BuildContext context,
    required Pedido pedido,
    required int nuevoEstado,
    required Function() onUpdate,
    required Function(bool) bloquearBoton,
  }) async {
    final OrderService orderService = Get.find<OrderService>();
    bloquearBoton(true);

    try {
      int? tiempoPrep;
      final int estadoActual = int.tryParse(pedido.estado) ?? 0;
      if (estadoActual == 1 && nuevoEstado == 2) {
        tiempoPrep = await mostrarDialogoTiempo(context);
        if (tiempoPrep == null) {
          bloquearBoton(false);
          return;
        }
      }

      final response = await orderService.actualizarEstadoPedido(
        pedido.id,
        nuevoEstado,
        tiempo: tiempoPrep ?? 0,
      );
      
      if (response.statusCode == 200) {
        Get.snackbar("Éxito", "Estado del pedido actualizado");
        onUpdate();
        
        if (nuevoEstado == 2) {
          pedido.tiempo = tiempoPrep ?? 0;
          pedido.estado = "2";
          navegarASeguimiento(pedido);
        }
      } else {
        Get.snackbar("Error", "No se pudo actualizar el estado");
      }
    } catch (e) {
      String errorMessage = "Error desconocido";
      if (e is DioException) {
        if (e.response?.data is Map && e.response?.data['error'] != null) {
          errorMessage = e.response?.data['error'];
        } else if (e.response?.data is Map && e.response?.data['message'] != null) {
          errorMessage = e.response?.data['message'];
        } else {
          errorMessage = e.message ?? e.toString();
        }
      } else {
        errorMessage = e.toString();
      }
      Get.snackbar("Error", "Error actualizando pedido: $errorMessage");
      debugPrint("Error actualizando pedido: $e");
    } finally {
      bloquearBoton(false);
    }
  }
  static Future<void> verificarPago({
    required int pedidoId,
    required Function() onUpdate,
    required Function(bool) bloquearBoton,
  }) async {
    final OrderService orderService = Get.find<OrderService>();
    bloquearBoton(true);
    try {
      final response = await orderService.verificarConfirmacionPago(pedidoId);
      if (response.statusCode == 200) {
        Get.snackbar("Éxito", "Pago verificado correctamente");
        onUpdate();
      } else {
        Get.snackbar("Error", "No se pudo verificar el pago");
      }
    } catch (e) {
      Get.snackbar("Error", "Error al verificar el pago: $e");
    } finally {
      bloquearBoton(false);
    }
  }
}
