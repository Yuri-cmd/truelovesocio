import 'package:flutter/material.dart';

class PedidoClienteCard extends StatelessWidget {
  final List<Map<String, dynamic>> pedidos;
  final Function(String numero) onCall;
  const PedidoClienteCard({
    super.key,
    required this.pedidos,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children:
          pedidos.map((pedido) {
            final cliente = pedido['cliente'] ?? 'Cliente desconocido';
            final celular = pedido['celular'] ?? '';

            return Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 5,
              child: ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: colorScheme.primary,
                  child: Icon(Icons.person, color: colorScheme.onPrimary),
                ),
                title: Text(cliente, style: TextStyle(color: Colors.black),),
                trailing: ElevatedButton(
                  onPressed: () {
                    onCall(celular);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(30, 30),
                  ),
                  child: const Icon(Icons.call, color: Colors.white, size: 16),
                ),
              ),
            );
          }).toList(),
    );
  }
}
