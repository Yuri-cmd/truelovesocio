import 'package:flutter/material.dart';

class PedidoEstadoTimeline extends StatelessWidget {
  final int estado;
  final List<Map<String, dynamic>> pedidos;
  final Function(int id, int estado) onUpdateEstado;
  final int id;
  final int tipoPedido;

  const PedidoEstadoTimeline({
    super.key,
    required this.estado,
    required this.pedidos,
    required this.onUpdateEstado,
    required this.id,
    required this.tipoPedido,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        [3, 4, 5, 6, 7, 8, 9].contains(estado)
            ? _buildTimelineButton('Indicar orden como preparada', false, true)
            : _buildTimelineButton('Indicar orden como preparada', true, false),
        if (tipoPedido == 0) ...[
          Icon(Icons.keyboard_arrow_down_sharp, color: Colors.grey),
          [5, 6, 7, 8].contains(estado)
              ? _buildTimelineButton('Motorizado llegó al negocio', false, true)
              : _buildTimelineButton(
                'Motorizado llegó al negocio',
                true,
                false,
              ),
          Icon(Icons.keyboard_arrow_down_sharp, color: Colors.grey),
          [6, 7, 8].contains(estado)
              ? _buildTimelineButton('Motorizado está en camino', false, true)
              : _buildTimelineButton('Motorizado está en camino', true, false),
        ],
        if (tipoPedido == 1) ...[
          Icon(Icons.keyboard_arrow_down_sharp, color: Colors.grey),
          [8].contains(estado)
              ? _buildTimelineButton('Pedido Entregado', false, true)
              : _buildTimelineButton('Pedido Entregado', true, false),
        ],
      ],
    );
  }

  Widget _buildTimelineButton(String label, bool isLast, bool isBlack) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isBlack ? Colors.black : Colors.white,
        side: const BorderSide(color: Colors.grey),
        minimumSize: const Size(double.infinity, 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () {
        if (isLast) {
          if (estado == 2) {
            if (tipoPedido == 1) {
              onUpdateEstado(id, 9);
            } else {
              onUpdateEstado(id, 3);
            }
          }

          if (estado == 4) {
            onUpdateEstado(id, 5);
          }

          if (estado == 9) {
            onUpdateEstado(id, 8);
          }
        }
      },
      child: Text(
        label,
        style: TextStyle(color: isBlack ? Colors.white : Colors.black),
        textAlign: TextAlign.center,
      ),
    );
  }
}
