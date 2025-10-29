import 'package:flutter/material.dart';
import 'package:truelovesocio/components/pedido_buttons.dart';
import 'package:truelovesocio/components/pedido_cliente_card.dart';
import 'package:truelovesocio/components/pedido_estado_timeline.dart';
import 'package:truelovesocio/components/pedido_motorizado_card.dart';
import 'package:truelovesocio/components/pedido_productos_list.dart';
import 'package:truelovesocio/model/pedido_model.dart';
import 'package:truelovesocio/service/api_service.dart';
import 'package:truelovesocio/theme/app_theme.dart';
import 'package:truelovesocio/utils/connection_helper.dart';
import 'package:truelovesocio/utils/helpers.dart';
import 'package:url_launcher/url_launcher.dart';

import 'dart:async';

class SeguimientoPedidoView extends StatefulWidget {
  final Pedido pedido;

  const SeguimientoPedidoView({super.key, required this.pedido});

  @override
  State<SeguimientoPedidoView> createState() => _SeguimientoPedidoViewState();
}

class _SeguimientoPedidoViewState extends State<SeguimientoPedidoView> {
  final ApiService apiService = ApiService();
  List<Map<String, dynamic>> pedidos = [];
  int estado = 0;
  double total = 0.0;
  int tiempo = 0;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadInfoPedido(widget.pedido.id);
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _loadInfoPedido(widget.pedido.id);
    });
  }
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadInfoPedido(int id) async {
    try {
      final data = await apiService.fetchPedidoById(id);
      setState(() {
        pedidos = data;
      });
      _calcularTotal();
    } catch (e) {
      throw ('Error al obtener pedidos: $e');
    }
  }

  void _calcularTotal() {
    double tempTotal = 0.0;
    int estadoAnterior = estado;

    for (var pedido in pedidos) {
      estado = int.tryParse(pedido['ultimo_estado_tracking']) ?? 0;
      tiempo = pedido['tiempo'];

      if (pedido['detalleArray'] is List) {
        for (var detalle in pedido['detalleArray']) {
          final rawCantidad = detalle['cantidad'];
          final rawPrecio = detalle['precio'];

          int cantidad = 0;
          double precio = 0.0;

          if (rawCantidad is int) {
            cantidad = rawCantidad;
          } else if (rawCantidad is String) {
            cantidad = int.tryParse(rawCantidad) ?? 0;
          }

          if (rawPrecio is int) {
            precio = rawPrecio.toDouble();
          } else if (rawPrecio is double) {
            precio = rawPrecio;
          } else if (rawPrecio is String) {
            precio = double.tryParse(rawPrecio) ?? 0.0;
          }

          tempTotal += precio * cantidad;
        }
      }
    }

    setState(() {
      total = tempTotal;
    });
    // Verificar si el estado cambió a 8 (entregado)
    if (estadoAnterior != 8 && estado == 8) {
      _mostrarToastPedidoEntregado();
    }
  }

  void _mostrarToastPedidoEntregado() {
    // Mostrar toast
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('El pedido fue entregado exitosamente'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
    // Regresar a la pantalla anterior después de un breve delay y devolver true
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    });
  }

  Future<void> actualizarEstadoPedido(int id, int estado) async {
    bool confirmar = await mostrarAlertaConfirmacion(estado);
    if (!confirmar) return;
    try {
      await apiService.actualizarEstado(id, estado);
      setState(() {
        this.estado = estado;
      });
    } catch (e) {
      throw ('Error actualizando pedido: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: const Text(
          'Órdenes activas',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => await _loadInfoPedido(widget.pedido.id),
        child:
            pedidos.isEmpty
                ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                )
                : SingleChildScrollView(
                  child: Column(
                    children: [
                      const ConnectionHelper(),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.white,
                        child: PedidoEstadoTimeline(
                          estado: estado,
                          onUpdateEstado: actualizarEstadoPedido,
                          pedidos: pedidos,
                          id: widget.pedido.id,
                          tipoPedido: widget.pedido.tipoPedido,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.white,
                        child: Column(
                          children: [
                            PedidoClienteCard(
                              pedidos: pedidos,
                              onCall: _llamar,
                            ),
                            const SizedBox(height: 10),
                            if (estado >= 2 && pedidos[0]['motorizado'].isNotEmpty) ...[
                              PedidoMotorizadoCard(
                                pedidos: pedidos,
                                onCall: _llamar,
                              ),
                            ],
                            const SizedBox(height: 10),
                            const Divider(),
                            if (pedidos.isNotEmpty &&
                                pedidos[0]['nota'] != null &&
                                pedidos[0]['nota'].toString().trim().isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.amber.shade300,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.sticky_note_2_outlined,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        pedidos[0]['nota'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // MÉTODO DE PAGO (diseño mejorado)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.blue.shade100,
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Puedes mejorar el widget de imagen según tu lógica
                                  getMetodoPagoImage(widget.pedido.tipoPago),
                                  const SizedBox(width: 14),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Método de pago',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade900,
                                          fontSize: 15,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.pedido.tipoPago,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // COMPROBANTE (diseño mejorado)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.green.shade100,
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.receipt_long_rounded,
                                    color: Colors.green.shade700,
                                    size: 30,
                                  ),
                                  const SizedBox(width: 14),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Comprobante',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade900,
                                          fontSize: 15,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            widget.pedido.tipoComprobante,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            widget.pedido.documento,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Divider(),
                            PedidoProductosList(
                              pedidos: pedidos,
                              estado: estado,
                              total: total,
                              onCall: _llamar,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      PedidoButtons(
                        estado: estado,
                        pedidos: pedidos,
                        tiempo: tiempo,
                        onUpdateEstado: actualizarEstadoPedido,
                        id: widget.pedido.id,
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Future<void> _llamar(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    await launchUrl(launchUri);
  }
}
