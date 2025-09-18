
  import 'package:flutter/material.dart';
  import 'package:truelovesocio/model/pedido_model.dart';
  import 'package:truelovesocio/model/socio_model.dart';
  import 'package:truelovesocio/screen/seguimiento_pedido_screen.dart';
  import 'package:truelovesocio/service/api_service.dart';

class PedidosHelper {
  static Future<dynamic> navegarASeguimiento(BuildContext context, Pedido pedido) async {
    return await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeguimientoPedidoView(pedido: pedido),
      ),
    );
  }
  static Future<int?> mostrarDialogoTiempo(BuildContext context) async {
    final TextEditingController controller = TextEditingController();
    return showDialog<int>(
      context: context,
      builder:
          (context) => AlertDialog(
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
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  final String text = controller.text;
                  final int? minutos = int.tryParse(text);
                  Navigator.of(context).pop(minutos);
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
    return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirmación'),
              content: Text(
                estado == 0
                    ? '¿Estás seguro de cancelar este pedido?'
                    : '¿Marcar pedido como listo?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Sí'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  static Future<void> cambiarEstadoRepartidor(
    BuildContext context,
    int estadoActual,
    Function(int) onEstadoActualizado,
  ) async {
    final nuevoEstado = estadoActual == 1 ? 0 : 1;

    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar cambio de estado'),
            content: Text(
              '¿Estás seguro de ${nuevoEstado == 1 ? 'activar' : 'desactivar'} al local?',
            ),
            actions: [
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              ElevatedButton(
                child: const Text('Confirmar'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
    );

    if (confirmar != true) return;

    final success = await ApiService().actualizarEstadoRepartidor(nuevoEstado);

    if (success) {
      Socio? socio = await ApiService.getLoggedUser();
      if (socio != null) {
        socio.activo = nuevoEstado;
        await ApiService.updateLoggedUser(socio);
      }

      onEstadoActualizado(nuevoEstado);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estado actualizado correctamente.')),
      );
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al actualizar el estado.')),
      );
    }
  }

  static Future<void> actualizarEstadoPedido({
    required BuildContext context,
    required Pedido pedido,
    required int nuevoEstado,
    required ApiService apiService,
    required Function() onUpdate,
    required Function(bool) bloquearBoton,
  }) async {
    bloquearBoton(true);

    try {
      int? tiempoPrep;
      final int estadoActual = int.parse(pedido.estado);
      if (estadoActual == 1 && nuevoEstado == 2) {
        tiempoPrep = await mostrarDialogoTiempo(context);
        if (tiempoPrep == null) return;
      }

      if (estadoActual == 0 || estadoActual == 1) {
        await apiService.actualizarEstado(
          pedido.id,
          nuevoEstado,
          tiempo: tiempoPrep ?? 0,
        );
      }

      await onUpdate();

      if (nuevoEstado == 2 && context.mounted) {
        if (tiempoPrep != null) pedido.tiempo = tiempoPrep;
        pedido.estado = nuevoEstado.toString();

        if (!context.mounted) return;
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SeguimientoPedidoView(pedido: pedido),
          ),
        );
        if (result == true && context.mounted) {
          onUpdate();
        }
      }
    } catch (_) {
      // manejar errores
    } finally {
      bloquearBoton(false);
    }
  }

  static Future<void> actualizarEstadoPago({
    required BuildContext context,
    required Pedido pedido,
    required ApiService apiService,
    required Function() onUpdate,
  }) async {
    try {
      await apiService.verificarConfirmacionPago(pedido.id);
      await onUpdate();
    } catch (_) {
      // manejar errores
    }
  }
}
