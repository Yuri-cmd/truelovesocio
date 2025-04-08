import 'dart:async';
import 'package:flutter/material.dart';
import 'package:truelovesocio/model/pedido_model.dart';
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

  Future<void> actualizarEstadoPedido(int id, int estado) async {
    bool confirmar = await mostrarAlertaConfirmacion(estado);
    if (!confirmar) return; // Si cancela, no hace nada

    setState(() {
      _bloqueoBotones[id] = true; // Bloquea el botón
    });

    try {
      await apiService.actualizarEstado(id, estado);
      loadPedidos();
    } catch (e) {
      throw('Error actualizando pedido: $e');
    } finally {
      setState(() {
        _bloqueoBotones[id] =
            false; // Desbloquea el botón después de la petición
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
      throw('Error cargando pedidos: $e');
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
                                '${pedido.tiempoEstimado} min',
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
                              // Botón Finalizar
                              ElevatedButton.icon(
                                onPressed:
                                    int.parse(pedido.estado) == 0 ||
                                            int.parse(pedido.estado) == 2 ||
                                            _bloqueoBotones[pedido.id] == true
                                        ? null
                                        : () {
                                          actualizarEstadoPedido(pedido.id, 2);
                                        },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                icon: const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Finalizar',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),

                              // Botón Cancelar
                              ElevatedButton.icon(
                                onPressed:
                                    int.parse(pedido.estado) == 0 ||
                                            int.parse(pedido.estado) == 2 ||
                                            _bloqueoBotones[pedido.id] == true
                                        ? null
                                        : () {
                                          actualizarEstadoPedido(pedido.id, 0);
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
