import 'package:flutter/material.dart';
import 'package:truelovesocio/data/models/detall_pedido_model.dart';

/// Muestra los productos de un pedido agrupando cada adicional debajo
/// de su producto principal, en vez de un texto plano tipo
/// "Bbq x1, Ají x1, Mostaza x1, MIXTO (queso + hot dog) x1, ...".
///
/// Cada 'adicional' se agrupa con el 'item' inmediatamente anterior,
/// según el campo `tipo` que envía el backend.
class PedidoProductosAgrupados extends StatelessWidget {
  final List<DetallePedido> detalleArray;
  final String fallbackTexto;

  const PedidoProductosAgrupados({
    super.key,
    required this.detalleArray,
    this.fallbackTexto = 'Sin productos',
  });

  List<Map<String, dynamic>> _agrupar() {
    final grupos = <Map<String, dynamic>>[];
    Map<String, dynamic>? ultimoGrupo;

    for (final detalle in detalleArray) {
      if (detalle.tipo == 'adicional' && ultimoGrupo != null) {
        (ultimoGrupo['adicionales'] as List<DetallePedido>).add(detalle);
      } else {
        ultimoGrupo = {'producto': detalle, 'adicionales': <DetallePedido>[]};
        grupos.add(ultimoGrupo);
      }
    }
    return grupos;
  }

  @override
  Widget build(BuildContext context) {
    final grupos = _agrupar();
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;

    if (grupos.isEmpty) {
      return Text(fallbackTexto, style: TextStyle(color: textColor));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < grupos.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _buildGrupo(grupos[i], textColor),
        ],
      ],
    );
  }

  Widget _buildGrupo(Map<String, dynamic> grupo, Color? textColor) {
    final producto = grupo['producto'] as DetallePedido;
    final adicionales = grupo['adicionales'] as List<DetallePedido>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '(${producto.cantidad}) ${producto.nombre}',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        ),
        if (adicionales.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adicionales:',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: textColor?.withValues(alpha: 0.7),
                  ),
                ),
                for (final adicional in adicionales) ...[
                  const SizedBox(height: 4),
                  _buildAdicional(adicional),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAdicional(DetallePedido adicional) {
    final precio = double.tryParse(adicional.precio) ?? 0.0;

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
              adicional.nombre,
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
}
