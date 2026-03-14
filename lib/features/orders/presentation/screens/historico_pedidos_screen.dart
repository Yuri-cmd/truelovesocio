import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:truelovesocio/features/orders/controllers/orders_controller.dart';
import 'package:truelovesocio/utils/helpers.dart';
import 'package:url_launcher/url_launcher.dart';

class HistoricoPedidosScreen extends GetView<OrdersController> {
  const HistoricoPedidosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Aseguramos que el controlador esté disponible
    Get.put(OrdersController());
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Histórico de pedidos'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.pedidos.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.pedidos.isEmpty) {
                return const Center(child: Text('No hay pedidos disponibles'));
              }
              return RefreshIndicator(
                onRefresh: () => controller.loadFilteredOrders(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: controller.pedidos.length,
                  itemBuilder: (context, idx) => _PedidoItem(pedido: controller.pedidos[idx]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Obx(() => DropdownButtonFormField<String>(
              value: controller.selectedFecha.value,
              decoration: InputDecoration(
                labelText: 'Fecha',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: const [
                DropdownMenuItem(value: 'todas', child: Text('Todas', style: TextStyle(color: Colors.black))),
                DropdownMenuItem(value: 'hoy', child: Text('Hoy', style: TextStyle(color: Colors.black))),
              ],
              onChanged: (v) {
                if (v != null) {
                  controller.selectedFecha.value = v;
                  controller.loadFilteredOrders();
                }
              },
            )),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(() => DropdownButtonFormField<String>(
              value: controller.selectedTipo.value,
              decoration: InputDecoration(
                labelText: 'Tipo',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: const [
                DropdownMenuItem(value: 'todos', child: Text('Todos', style: TextStyle(color: Colors.black))),
                DropdownMenuItem(value: 'finalizados', child: Text('Finalizados', style: TextStyle(color: Colors.black))),
                DropdownMenuItem(value: 'activos', child: Text('Activos')),
              ],
              onChanged: (v) {
                if (v != null) {
                  controller.selectedTipo.value = v;
                  controller.loadFilteredOrders();
                }
              },
            )),
          ),
        ],
      ),
    );
  }
}

class _PedidoItem extends StatefulWidget {
  final dynamic pedido;
  const _PedidoItem({required this.pedido});

  @override
  State<_PedidoItem> createState() => _PedidoItemState();
}

class _PedidoItemState extends State<_PedidoItem> {
  bool isExpanded = false;

  String _formatDate(String? fecha) {
    if (fecha == null || fecha.isEmpty) return 'Sin fecha';
    try {
      final dt = DateTime.parse(fecha);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return fecha;
    }
  }

  Future<void> _downloadImage(String url) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savePath = '${dir.path}/$fileName';
      await Dio().download(url, savePath);
      const platform = MethodChannel('app.channel.documents');
      await platform.invokeMethod('saveFileToDownloads', {'path': savePath, 'displayName': fileName});
      if (mounted) Get.snackbar("Éxito", "Imagen guardada en descargas");
    } catch (e) {
      if (mounted) Get.snackbar("Error", "No se pudo descargar la imagen");
    }
  }

  @override
  Widget build(BuildContext context) {
    final pedido = widget.pedido;
    final estadoText = obtenerEstado(int.tryParse(pedido.estado) ?? 0);
    final estadoColor = obtenerColorEstado(int.tryParse(pedido.estado) ?? 0);
    final total = (double.tryParse(pedido.subtotal.toString()) ?? 0) - (double.tryParse(pedido.descuento.toString()) ?? 0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.grey.withAlpha(25), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pedido #${pedido.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(pedido.cliente ?? 'Sin nombre'),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: estadoColor.withAlpha(38), borderRadius: BorderRadius.circular(20)),
                  child: Text(estadoText, style: TextStyle(color: estadoColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Dirección: ${pedido.direccionEntrega ?? 'Sin dirección'}'),
            Text('Fecha: ${_formatDate(pedido.fecha)}'),
            const Divider(),
            if (isExpanded) ...[
              const Text('Productos:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...(pedido.detalleArray as List).map((d) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${d.cantidad}x ${d.nombre}'),
                  Text('S/. ${d.precio}'),
                ],
              )),
              const Divider(),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total: S/. ${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => setState(() => isExpanded = !isExpanded),
                  child: Text(isExpanded ? 'Ver menos' : 'Ver más'),
                ),
              ],
            ),
            if (pedido.fotoPago != null)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => _downloadImage(pedido.fotoPago),
                  icon: const Icon(Icons.download),
                  tooltip: 'Descargar comprobante',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
