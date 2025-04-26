import 'dart:async';
import 'package:flutter/material.dart';
import 'package:truelovesocio/model/pedido_model.dart';
import 'package:truelovesocio/screen/seguimiento_pedido_screen.dart';
import 'package:truelovesocio/service/api_service.dart';
import 'package:truelovesocio/theme/app_theme.dart';
import 'package:truelovesocio/utils/helpers.dart';

class PedidosView extends StatefulWidget {
  const PedidosView({super.key});

  @override
  State<PedidosView> createState() => _PedidosViewState();
}

class _PedidosViewState extends State<PedidosView> {
  List<Pedido> pedidos = [];
  final ApiService apiService = ApiService();
  Timer? timer;
  final Map<int, bool> _bloqueoBotones = {};

  @override
  void initState() {
    super.initState();
    loadPedidos();
    timer = Timer.periodic(
      const Duration(seconds: 5),
      (Timer t) => loadPedidos(),
    );
  }

  // Muestra un diálogo para ingresar el tiempo de preparación
  Future<int?> _mostrarDialogoTiempo() async {
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

  Future<void> actualizarEstadoPedido(Pedido pedido, int nuevoEstado) async {
    // Bloquear el botón
    setState(() {
      _bloqueoBotones[pedido.id] = true;
    });

    try {
      int? tiempoPrep;
      final int estadoActual = int.parse(pedido.estado);
      if (estadoActual == 1) {
        // Si no está aceptado, pedir tiempo de preparación
        tiempoPrep = await _mostrarDialogoTiempo();
        if (tiempoPrep == null) {
          // Usuario canceló diálogo
          return;
        }
      }
      if (estadoActual == 0 || estadoActual == 1) {
        // Llamada API: actualizar estado y, si aplica, tiempo de preparación
        await apiService.actualizarEstado(
          pedido.id,
          nuevoEstado,
          tiempo: tiempoPrep ?? 0,
        );
      }
      await loadPedidos();
      // Si nuevoEstado es aceptado (1), navegar a seguimiento
      if (nuevoEstado == 2 && context.mounted) {
        if (tiempoPrep != null) {
          pedido.tiempo = tiempoPrep;
        }
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SeguimientoPedidoView(pedido: pedido),
          ),
        );
      }
    } catch (e) {
      // showErrorSnackBar(context, 'Error: $e');
    } finally {
      // Desbloquear el botón
      setState(() {
        _bloqueoBotones[pedido.id] = false;
      });
    }
  }

  Future<bool> mostrarAlertaConfirmacion(int estado) async {
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

  Future<void> loadPedidos() async {
    try {
      final data = await apiService.fetchPedidos();
      setState(() {
        pedidos = data;
      });
    } catch (e) {
      throw ('Error cargando pedidos: $e');
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pedidos Pendientes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body:
          pedidos.isEmpty
              ? const Center(
                child: Text(
                  '📭 Sin pedidos pendientes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              )
              : ListView.builder(
                itemCount: pedidos.length,
                padding: const EdgeInsets.all(10),
                itemBuilder: (context, index) {
                  final pedido = pedidos[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Cliente y Estado
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  pedido.cliente,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              Chip(
                                label: Text(
                                  obtenerEstado(int.parse(pedido.estado)),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: obtenerColorEstado(
                                  int.parse(pedido.estado),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),
                          Divider(color: Colors.grey[300]),

                          // Detalles del pedido
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.indigo,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  pedido.direccionEntrega,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.phone, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(
                                pedido.celular,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.timer, color: Colors.orange),
                              const SizedBox(width: 8),
                              Text(
                                '${pedido.tiempo} min',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Productos
                          const Text(
                            '🛒 Productos:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pedido.productos,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Botones de acción
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Botón Finalizar
                              ElevatedButton.icon(
                                onPressed:
                                    int.parse(pedido.estado) == 0 ||
                                            _bloqueoBotones[pedido.id] == true
                                        ? null
                                        : () {
                                          actualizarEstadoPedido(pedido, 2);
                                        },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                icon: const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Aceptar',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),

                              // Botón Cancelar
                              ElevatedButton.icon(
                                onPressed:
                                    int.parse(pedido.estado) == 0 ||
                                            int.parse(pedido.estado) == 2 ||
                                            int.parse(pedido.estado) == 3 ||
                                            int.parse(pedido.estado) == 4 ||
                                            int.parse(pedido.estado) == 5 ||
                                            int.parse(pedido.estado) == 6 ||
                                            int.parse(pedido.estado) == 7 ||
                                            int.parse(pedido.estado) == 8 ||
                                            int.parse(pedido.estado) == 9 ||
                                            _bloqueoBotones[pedido.id] == true
                                        ? null
                                        : () {
                                          actualizarEstadoPedido(pedido, 0);
                                        },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                ),
                                icon: const Icon(
                                  Icons.cancel,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Cancelar',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      backgroundColor: Colors.grey[200],
    );
  }
}
