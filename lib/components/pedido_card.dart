import 'package:flutter/material.dart';
import 'package:truelovesocio/model/pedido_model.dart';
import 'package:truelovesocio/service/api_service.dart';
import 'package:truelovesocio/utils/helpers.dart';
import 'package:truelovesocio/utils/pedidos_helper.dart';

class PedidoCard extends StatelessWidget {
  final Pedido pedido;
  final ApiService apiService;
  final Map<int, bool> bloqueoBotones;
  final Function onUpdate;
  final Function(bool) bloquearBoton;

  const PedidoCard({
    super.key,
    required this.pedido,
    required this.apiService,
    required this.bloqueoBotones,
    required this.onUpdate,
    required this.bloquearBoton,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 5,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cliente y Estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    pedido.cliente,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Chip(
                  label: Text(
                    obtenerEstado(int.parse(pedido.estado)),
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: obtenerColorEstado(int.parse(pedido.estado)),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Divider(color: colorScheme.surfaceContainerHighest),

            infoRow(
              context,
              Icons.location_on,
              pedido.direccionEntrega,
              color: Colors.indigo,
            ),
            infoRow(context, Icons.phone, pedido.celular, color: Colors.green),
            infoRow(context, Icons.person, pedido.cliente, color: Colors.orange),
            infoRow(context, Icons.timer, '${pedido.tiempo} min', color: Colors.orange),
            infoRow(context, Icons.article_sharp, pedido.nota, color: Colors.blue),

            const SizedBox(height: 6),
            Row(
              children: [
                getMetodoPagoImage(pedido.tipoPago),
                const SizedBox(width: 6),
                Text(
                  pedido.tipoPago,
                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (pedido.tipoComprobante.isNotEmpty &&
                pedido.documento.isNotEmpty)
              infoRow(
                context,
                Icons.receipt_long_rounded,
                "${pedido.tipoComprobante}: ${pedido.documento}",
                color: Colors.redAccent,
              )
            else
              infoRow(
                context,
                Icons.receipt_long_rounded,
                "Comprobante: Ninguno",
                color: Colors.redAccent,
              ),
            const SizedBox(height: 10),
            Text(
              '🛒 Productos:',
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              pedido.productos,
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                pedido.requiereConfirmacionLocal == true
                    ? ElevatedButton.icon(
                        onPressed: () async {
                          // Verificar si hay foto de pago
                          if (pedido.fotoPago.isEmpty || pedido.fotoPago == 'null') {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('No hay foto'),
                                content: const Text('No se ha cargado una foto del pago.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }

                          // Mostrar la imagen del pago
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Foto del pago'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.network(
                                    pedido.fotoPago,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Text('Error al cargar la imagen');
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('¿Deseas verificar este pago?'),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancelar'),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    if (!context.mounted) return;
                                    await PedidosHelper.actualizarEstadoPago(
                                      context: context,
                                      pedido: pedido,
                                      apiService: apiService,
                                      onUpdate: () => onUpdate(),
                                    );

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Pago verificado correctamente'),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('Verificar'),
                                ),
                              ],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber[700],
                        ),
                        icon: const Icon(Icons.verified, color: Colors.white),
                        label: const Text(
                          'Verificar pago',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: int.parse(pedido.estado) == 0 ||
                                bloqueoBotones[pedido.id] == true
                            ? null
                            : () {
                                PedidosHelper.actualizarEstadoPedido(
                                  context: context,
                                  pedido: pedido,
                                  nuevoEstado: 2,
                                  apiService: apiService,
                                  onUpdate: () => onUpdate(),
                                  bloquearBoton: bloquearBoton,
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        icon: const Icon(Icons.check_circle, color: Colors.white),
                        label: Text(
                          int.parse(pedido.estado) == 0 ||
                                  int.parse(pedido.estado) == 1
                              ? 'Aceptar'
                              : 'Ver Pedido',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                ElevatedButton.icon(
                  onPressed: _debeDeshabilitarBotonCancelar()
                      ? null
                      : () {
                          PedidosHelper.actualizarEstadoPedido(
                            context: context,
                            pedido: pedido,
                            nuevoEstado: 0,
                            apiService: apiService,
                            onUpdate: () => onUpdate(),
                            bloquearBoton: bloquearBoton,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  icon: const Icon(Icons.cancel, color: Colors.white),
                  label: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _debeDeshabilitarBotonCancelar() {
    final estado = int.parse(pedido.estado);
    return estado == 0 || estado >= 2 || bloqueoBotones[pedido.id] == true;
  }

  Widget infoRow(BuildContext context, IconData icon, String text, {Color color = Colors.black}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}