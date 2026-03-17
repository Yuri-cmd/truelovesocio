import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:truelovesocio/features/orders/controllers/orders_controller.dart';
import 'package:truelovesocio/core/utils/helpers.dart';
import 'package:truelovesocio/data/models/pedido_model.dart';

class HistoricoPedidosScreen extends GetView<OrdersController> {
  const HistoricoPedidosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Aseguramos que el controlador esté disponible
    Get.put(OrdersController());
    
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? null : const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('Historial de Ventas', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFilters(context),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.pedidos.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: Colors.red));
              }
              if (controller.pedidos.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No hay pedidos que mostrar', style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                color: Colors.red,
                onRefresh: () => controller.loadFilteredOrders(),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: controller.pedidos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) => _PedidoItem(pedido: controller.pedidos[idx]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Obx(() => _buildStyledDropdown(
              context,
              label: 'Periodo',
              value: controller.selectedFecha.value,
              items: {
                'todas': 'Todas las fechas',
                'hoy': 'Solo Hoy',
              },
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
            child: Obx(() => _buildStyledDropdown(
              context,
              label: 'Estado',
              value: controller.selectedTipo.value,
              items: {
                'todos': 'Todos los estados',
                'finalizados': 'Finalizados',
                'activos': 'En Curso',
              },
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

  Widget _buildStyledDropdown(
    BuildContext context, {
    required String label,
    required String value,
    required Map<String, String> items,
    required Function(String?) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.red[400],
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withAlpha(12) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white12 : Colors.transparent),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.red[300], size: 20),
              dropdownColor: Theme.of(context).cardColor,
              items: items.entries.map((e) => DropdownMenuItem(
                value: e.key,
                child: Text(
                  e.value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              )).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _PedidoItem extends StatefulWidget {
  final Pedido pedido;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final totalStr = pedido.subtotal;
    final descuentoStr = pedido.descuento;
    final totalNum = (double.tryParse(totalStr) ?? 0) - (double.tryParse(descuentoStr) ?? 0);

    return InkWell(
      onTap: () => setState(() => isExpanded = !isExpanded),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: isDark ? Border.all(color: Colors.white12, width: 0.5) : Border.all(color: Colors.black.withAlpha(8)),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black45 : Colors.black.withAlpha(12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // Header with status indicator line
              Container(
                height: 4,
                width: double.infinity,
                color: estadoColor,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '#${pedido.id}',
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (pedido.tipoPago.isNotEmpty) 
                                    getMetodoPagoImage(pedido.tipoPago),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                pedido.cliente,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildStatusChip(estadoText, estadoColor),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildIconLabel(Icons.location_on_rounded, pedido.direccionEntrega),
                    const SizedBox(height: 8),
                    _buildIconLabel(Icons.access_time_filled_rounded, _formatDate(pedido.fecha)),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL RECIBIDO',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.grey[500],
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              'S/ ${totalNum.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: -0.8,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            if (pedido.fotoPago.isNotEmpty && 
                                pedido.fotoPago != 'null' && 
                                pedido.fotoPago != '(Null)')
                              IconButton.filledTonal(
                                onPressed: () => _downloadImage(pedido.fotoPago),
                                icon: const Icon(Icons.receipt_long_rounded, size: 20),
                                tooltip: 'Ver Comprobante',
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.blue.withAlpha(25),
                                  foregroundColor: Colors.blue[700],
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.withAlpha(isDark ? 20 : 15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (isExpanded) ...[
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Text(
                        'DETALLE DE PRODUCTOS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.red[400],
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...pedido.detalleArray.map((d) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.withAlpha(isDark ? 30 : 20),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${d.cantidad}x',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                d.nombre,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                                ),
                              ),
                            ),
                            Text(
                              'S/ ${d.precio}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconLabel(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.red[300]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(50), width: 1),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
