import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
                title: Text(
                  cliente,
                  style: const TextStyle(color: Colors.black),
                ),
                subtitle:
                    (pedido['celular_whatsapp'] != null &&
                            pedido['celular_whatsapp'] != '')
                        ? Text(
                          'WhatsApp: ${pedido['celular_whatsapp']}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        )
                        : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (pedido['celular_whatsapp'] != null &&
                        pedido['celular_whatsapp'] != '')
                      IconButton(
                        onPressed: () async {
                          final whatsappUrl = Uri.parse(
                            "https://wa.me/${pedido['celular_whatsapp']}",
                          );
                          await launchUrl(
                            whatsappUrl,
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        icon: Icon(Icons.chat, color: Colors.green),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        onCall(celular);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(30, 30),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Icon(
                        Icons.call,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }
}
