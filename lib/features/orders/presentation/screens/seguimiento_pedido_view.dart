import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truelovesocio/core/components/pedido_buttons.dart';
import 'package:truelovesocio/core/components/pedido_cliente_card.dart';
import 'package:truelovesocio/core/components/pedido_estado_timeline.dart';
import 'package:truelovesocio/core/components/pedido_motorizado_card.dart';
import 'package:truelovesocio/core/components/pedido_productos_list.dart';
import 'package:truelovesocio/data/models/pedido_model.dart';
import 'package:truelovesocio/data/services/order_service.dart';
import 'package:truelovesocio/core/utils/connection_helper.dart';
import 'package:truelovesocio/core/utils/helpers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class SeguimientoPedidoView extends StatefulWidget {
  final Pedido pedido;

  const SeguimientoPedidoView({super.key, required this.pedido});

  @override
  State<SeguimientoPedidoView> createState() => _SeguimientoPedidoViewState();
}

class _SeguimientoPedidoViewState extends State<SeguimientoPedidoView> {
  final OrderService _orderService = Get.find<OrderService>();
  List<Map<String, dynamic>> pedidos = [];
  int estado = 0;
  double total = 0.0;
  int tiempo = 0;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadInfoPedido(widget.pedido.id);
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
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
      final response = await _orderService.fetchPedidoById(id);
      if (response.statusCode == 200) {
        setState(() {
          pedidos = List<Map<String, dynamic>>.from(response.data);
        });
        _calcularTotal();
      }
    } catch (e) {
      debugPrint('Error al obtener pedido: $e');
    }
  }

  void _calcularTotal() {
    double tempTotal = 0.0;
    int estadoAnterior = estado;

    for (var pedido in pedidos) {
      estado = int.tryParse(pedido['ultimo_estado_tracking'].toString()) ?? 0;
      tiempo = pedido['tiempo'] ?? 0;

      if (pedido['detalleArray'] is List) {
        for (var detalle in pedido['detalleArray']) {
          double precio = double.tryParse(detalle['precio'].toString()) ?? 0.0;
          int cantidad = int.tryParse(detalle['cantidad'].toString()) ?? 0;
          tempTotal += precio * cantidad;
        }
      }
    }

    setState(() {
      total = tempTotal;
    });
    if (estadoAnterior != 8 && estado == 8) {
      _mostrarToastPedidoEntregado();
    }
  }

  void _mostrarToastPedidoEntregado() {
    Get.snackbar(
      'Éxito',
      'El pedido fue entregado exitosamente',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) Get.back(result: true);
    });
  }

  Future<void> actualizarEstadoPedido(int id, int estado) async {
    bool confirmar = await mostrarAlertaConfirmacion(estado);
    if (!confirmar) return;
    try {
      final response = await _orderService.actualizarEstadoPedido(id, estado);
      if (response.statusCode == 200) {
        setState(() {
          this.estado = estado;
        });
        _loadInfoPedido(id);
      }
    } catch (e) {
      Get.snackbar("Error", "Error actualizando pedido: $e");
    }
  }

  Future<bool> mostrarAlertaConfirmacion(int estado) async {
    return await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmación'),
        content: Text(estado == 0 ? '¿Estás seguro de cancelar este pedido?' : '¿Marcar pedido como listo?'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('No')),
          ElevatedButton(onPressed: () => Get.back(result: true), child: const Text('Sí')),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text('Seguimiento de Pedido', style: TextStyle(color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Get.back()),
      ),
      body: RefreshIndicator(
        onRefresh: () async => await _loadInfoPedido(widget.pedido.id),
        child: pedidos.isEmpty
            ? const Center(child: CircularProgressIndicator())
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
                          PedidoClienteCard(pedidos: pedidos, onCall: _llamar),
                          const SizedBox(height: 10),
                          if (estado >= 2 && pedidos[0]['motorizado'] != null && (pedidos[0]['motorizado'] as String).isNotEmpty) ...[
                            PedidoMotorizadoCard(pedidos: pedidos, onCall: _llamar),
                          ],
                          const SizedBox(height: 10),
                          const Divider(),
                          _buildNota(),
                          _buildMetodoPago(),
                          _buildComprobante(),
                          const Divider(),
                          PedidoProductosList(pedidos: pedidos, estado: estado, total: total, onCall: _llamar),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    PedidoButtons(estado: estado, pedidos: pedidos, tiempo: tiempo, onUpdateEstado: actualizarEstadoPedido, id: widget.pedido.id),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildNota() {
    if (pedidos.isEmpty || pedidos[0]['nota'] == null || pedidos[0]['nota'].toString().trim().isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.shade300)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.sticky_note_2_outlined, color: Colors.amber),
          const SizedBox(width: 10),
          Expanded(child: Text(pedidos[0]['nota'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildMetodoPago() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color(int.parse(getMetodoPagoColor(widget.pedido.tipoPago).substring(1), radix: 16) + 0xFF000000),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          getMetodoPagoImage(widget.pedido.tipoPago),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Método de pago', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
              Text(widget.pedido.tipoPago, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white)),
              if (widget.pedido.pagaCon != null && widget.pedido.pagaCon!.isNotEmpty)
                Text(widget.pedido.pagaCon!.toLowerCase() == 'exacto' ? 'Monto: Exacto' : 'Paga con: S/ ${widget.pedido.pagaCon}', style: const TextStyle(fontSize: 13, color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComprobante() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.green.shade200)),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_rounded, color: Colors.green, size: 30),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Comprobante', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 13)),
              Text('${widget.pedido.tipoComprobante} - ${widget.pedido.documento}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _llamar(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    await launchUrl(launchUri);
  }
}
