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
      if (detalleArray == null) continue;

      final grupos = _agruparPorProducto(detalleArray);

      for (var grupo in grupos) {
        final producto = grupo['producto'] as Map<String, dynamic>;
        final adicionales = grupo['adicionales'] as List<Map<String, dynamic>>;
        final cantidad = int.tryParse(producto['cantidad'].toString()) ?? 0;
        final precio = double.tryParse(producto['precio'].toString()) ?? 0.0;
        final nombre = producto['nombre'] ?? '';

        productosWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '($cantidad) $nombre',
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                    ),
                    Text(
                      (precio * cantidad).toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black
                      ),
                    ),
                  ],
                ),
                if (adicionales.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var adicional in adicionales) ...[
                          const SizedBox(height: 4),
                          _buildAdicional(adicional),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      }
    }

    return Column(children: productosWidgets);
  }

  Widget _buildAdicional(Map<String, dynamic> adicional) {
    final precio = double.tryParse(adicional['precio']?.toString() ?? '') ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${adicional['nombre'] ?? ''}',
              style: const TextStyle(fontSize: 12.5, color: Colors.black87),
            ),
          ),
          if (precio > 0)
            Text(
              '+ S/ ${precio.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
        ],
      ),
    );
  }

  /// Agrupa cada adicional debajo del producto principal que lo precede,
  /// según el campo `tipo` ('item' | 'adicional') que envía el backend.
  List<Map<String, dynamic>> _agruparPorProducto(List<dynamic> detalleArray) {
    final grupos = <Map<String, dynamic>>[];
    Map<String, dynamic>? ultimoGrupo;

    for (var item in detalleArray) {
      final detalle = Map<String, dynamic>.from(item as Map);
      final tipo = detalle['tipo']?.toString();

      if (tipo == 'adicional' && ultimoGrupo != null) {
        (ultimoGrupo['adicionales'] as List<Map<String, dynamic>>).add(detalle);
      } else {
        ultimoGrupo = {'producto': detalle, 'adicionales': <Map<String, dynamic>>[]};
        grupos.add(ultimoGrupo);
      }
    }

    return grupos;
  }

  Widget _buildTotalRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text(
          'Total a cobrar: ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
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
