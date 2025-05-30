import 'package:flutter/material.dart';

class PedidoButtons extends StatelessWidget {
  final int estado;
  final int tiempo;
  final List<Map<String, dynamic>> pedidos;
  final Function(int id, int estado) onUpdateEstado;
  final int id;

  const PedidoButtons({
    super.key,
    required this.estado,
    required this.pedidos,
    required this.tiempo,
    required this.onUpdateEstado,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildTimelineButton(
            'Aceptada\nTiempo Estimado Prep: ${(tiempo).toString()} min',
            false,
            false,
          ),
          // _buildTimelineButton(
          //   'Indicar orden como preparada',
          //   estado < 3,
          //   true,
          // ),
        ],
      ),
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
            onUpdateEstado(id, 3);
          }

          if (estado == 4) {
            onUpdateEstado(id, 5);
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
