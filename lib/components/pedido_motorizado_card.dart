import 'package:flutter/material.dart';

class PedidoMotorizadoCard extends StatelessWidget {
  final List<Map<String, dynamic>> pedidos;
  final Function(String numero) onCall;
  const PedidoMotorizadoCard({
    super.key,
    required this.pedidos,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children:
          pedidos.map((pedido) {
            final motorizado = pedido['motorizado'] ?? 'Cliente desconocido';
            final celular = pedido['celular_motorizado'] ?? '';
            return Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 5,
              child: ListTile(
                leading: const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.delivery_dining, color: Colors.white),
                ),
                title: Text(motorizado),
                trailing: ElevatedButton(
                  onPressed: () {
                    onCall(
                      celular,
                    ); // Aquí puedes pasar el número real del motorizado
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
