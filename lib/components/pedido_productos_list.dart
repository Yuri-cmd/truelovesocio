import 'package:flutter/material.dart';

class PedidoProductosList extends StatelessWidget {
  final List<Map<String, dynamic>> pedidos;
  final int estado;
  final double total;
  final Function(String numero) onCall;

  const PedidoProductosList({
    super.key,
    required this.pedidos,
    required this.estado,
    required this.total,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [_buildProductosList(), const Divider(), _buildTotalRow()],
    );
  }

  Widget _buildProductosList() {
    List<Widget> productosWidgets = [];

    for (var pedido in pedidos) {
      final detalleArray = pedido['detalleArray'] as List<dynamic>?;

      if (detalleArray != null) {
        for (var detalle in detalleArray) {
          final cantidad = int.tryParse(detalle['cantidad'].toString()) ?? 0;
          final precio = double.tryParse(detalle['precio'].toString()) ?? 0.0;
          final nombre = detalle['nombre'] ?? '';

          productosWidgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '($cantidad) $nombre',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    (precio * cantidad).toStringAsFixed(2),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    }

    return Column(children: productosWidgets);
  }

  Widget _buildTotalRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text(
          'Total a cobrar: ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          total.toStringAsFixed(2),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }
}
