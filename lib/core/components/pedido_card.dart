import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:truelovesocio/data/models/pedido_model.dart';
import 'package:truelovesocio/core/utils/helpers.dart';
import 'package:truelovesocio/core/utils/pedidos_helper.dart';
import 'package:path_provider/path_provider.dart';

class PedidoCard extends StatefulWidget {
  final Pedido pedido;
  final Map<int, bool> bloqueoBotones;
  final Function onUpdate;
  final Function(bool) bloquearBoton;

  const PedidoCard({
    super.key,
    required this.pedido,
    required this.bloqueoBotones,
    required this.onUpdate,
    required this.bloquearBoton,
  });

  @override
  State<PedidoCard> createState() => _PedidoCardState();
}

class _PedidoCardState extends State<PedidoCard> {

  Future<void> _showPhotoDialog(String photoUrl) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (dialogContext) => Dialog(
            backgroundColor: Colors.black,
            insetPadding: const EdgeInsets.all(16),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                InteractiveViewer(
                  child: Image.network(photoUrl, fit: BoxFit.contain),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.download, color: Colors.white),
                        onPressed: () async {
                          await _downloadImage(photoUrl);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _downloadImage(String url) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savePath = '${dir.path}/$fileName';

      await Dio().download(url, savePath);

      const platform = MethodChannel('app.channel.documents');
      try {
        final displayName = fileName;
        final out = await platform.invokeMethod<String>(
          'saveFileToDownloads',
          {'path': savePath, 'displayName': displayName},
        );

        if (!mounted) return;
        if (out != null) {
          try {
            final tmp = File(savePath);
            if (await tmp.exists()) await tmp.delete();
          } catch (_) {}
          if(!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imagen guardada en: $out')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imagen descargada (temporal): $savePath')),
          );
        }
      } on PlatformException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Descargado en: $savePath (no se guardó en Downloads): ${e.message}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al descargar: $e')),
      );
    }
  }

  String _obtenerTiempoTranscurrido(String fecha) {
    if (fecha.isEmpty) return '';
    try {
      final DateTime orderDate = parsearFecha(fecha);
      final Duration diff = DateTime.now().difference(orderDate);
      if (diff.isNegative) return '0m';

      final int hours = diff.inHours;
      final int minutes = diff.inMinutes.remainder(60);

      if (hours > 0) {
        return '${hours}h ${minutes}m';
      } else {
        return '${minutes}m';
      }
    } catch (e) {
      return '';
    }
  }

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
               Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#${widget.pedido.id}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (_obtenerTiempoTranscurrido(widget.pedido.fecha).isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[600],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _obtenerTiempoTranscurrido(widget.pedido.fecha),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    obtenerEstado(int.tryParse(widget.pedido.estado) ?? 0),
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: obtenerColorEstado(int.tryParse(widget.pedido.estado) ?? 0),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.pedido.cliente,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 4),
            Divider(color: colorScheme.surfaceContainerHighest),

            infoRow(
              context,
              Icons.location_on,
              widget.pedido.direccionEntrega,
              color: Colors.indigo,
            ),
            infoRow(context, Icons.phone, widget.pedido.celular, color: Colors.green),
            infoRow(context, Icons.person, widget.pedido.cliente, color: Colors.orange),
            if (widget.pedido.motorizado.isNotEmpty)
              infoRow(
                context,
                Icons.delivery_dining_rounded,
                'Driver: ${widget.pedido.motorizado} ${widget.pedido.celularMotorizado.isNotEmpty ? "(${widget.pedido.celularMotorizado})" : ""}',
                color: Colors.deepOrange,
              ),
            infoRow(context, Icons.timer, '${widget.pedido.tiempo} min', color: Colors.orange),
            infoRow(context, Icons.article_sharp, widget.pedido.nota, color: Colors.blue),

            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    getMetodoPagoImage(widget.pedido.tipoPago),
                    const SizedBox(width: 6),
                    Text(
                      widget.pedido.tipoPago,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (widget.pedido.fotoPago.isNotEmpty &&
                    widget.pedido.fotoPago != 'null' &&
                    widget.pedido.fotoPago != '(Null)')
                  TextButton.icon(
                    onPressed: () => _showPhotoDialog(widget.pedido.fotoPago),
                    icon: const Icon(Icons.remove_red_eye, size: 20),
                    label: const Text('Ver pago'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (widget.pedido.tipoComprobante.isNotEmpty &&
                widget.pedido.documento.isNotEmpty)
              infoRow(
                context,
                Icons.receipt_long_rounded,
                "${widget.pedido.tipoComprobante}: ${widget.pedido.documento}",
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
            infoRow(
              context,
              Icons.radio_button_checked_rounded,
              "Tipo de entrega: ${widget.pedido.tipoPedido == 0 ? 'Delivery' : 'Recojo en local'}",
              color: Colors.redAccent,
            ),
            const SizedBox(height: 10),
            Text(
              '🛒 Productos:',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.pedido.productos,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                widget.pedido.requiereConfirmacionLocal == true
                    ? ElevatedButton.icon(
                      onPressed: () async {
                        if (widget.pedido.fotoPago.isEmpty ||
                            widget.pedido.fotoPago == 'null') {
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('No hay foto'),
                                  content: const Text('No se ha cargado una foto del pago.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Get.back(),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                          );
                          return;
                        }

                        showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder:
                              (context) => Dialog(
                                insetPadding: const EdgeInsets.all(20),
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: const BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            topRight: Radius.circular(12),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Foto del pago',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () async {
                                                await _downloadImage(widget.pedido.fotoPago);
                                              },
                                              icon: const Icon(Icons.download, color: Colors.white),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          child: Image.network(
                                            widget.pedido.fotoPago,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) => const Text('Error al cargar la imagen'),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          children: [
                                            const Text('¿Deseas verificar este pago?', style: TextStyle(fontSize: 16)),
                                            const SizedBox(height: 16),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                              children: [
                                                TextButton(
                                                  onPressed: () => Get.back(),
                                                  child: const Text('Cancelar'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () async {
                                                    Get.back();
                                                    PedidosHelper.verificarPago(
                                                      pedidoId: widget.pedido.id,
                                                      onUpdate: () => widget.onUpdate(),
                                                      bloquearBoton: widget.bloquearBoton,
                                                    );
                                                  },
                                                  child: const Text('Verificar'),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700]),
                      icon: const Icon(Icons.verified, color: Colors.white),
                      label: const Text('Verificar pago', style: TextStyle(color: Colors.white)),
                    )
                    : ElevatedButton.icon(
                      onPressed:
                          (int.tryParse(widget.pedido.estado) ?? 0) > 1 ||
                          (int.tryParse(widget.pedido.estado) ?? 0) == 0 ||
                          widget.bloqueoBotones[widget.pedido.id] == true
                              ? null // Se deshabilita la acción de botón porque ya fue aceptado o está bloqueado
                              : () {
                                PedidosHelper.actualizarEstadoPedido(
                                  context: context,
                                  pedido: widget.pedido,
                                  nuevoEstado: 2,
                                  onUpdate: () => widget.onUpdate(),
                                  bloquearBoton: widget.bloquearBoton,
                                );
                              },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      icon: const Icon(Icons.check_circle, color: Colors.white),
                      label: Text(
                        (int.tryParse(widget.pedido.estado) ?? 0) == 0 ||
                                (int.tryParse(widget.pedido.estado) ?? 0) == 1
                            ? 'Aceptar'
                            : 'En Proceso', // Cambiado de 'Ver Pedido' a 'En Proceso' para evitar confusión
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                Tooltip(
                  message: (int.tryParse(widget.pedido.estado) ?? 0) == 0 ? 'El pedido ya está cancelado' : 'Cancelar pedido',
                  child: ElevatedButton.icon(
                    onPressed:
                        _debeDeshabilitarBotonCancelar()
                            ? null
                            : () async {
                                final confirmar = await PedidosHelper.mostrarAlertaConfirmacion(context, 0);
                                if (!confirmar) return;
                                
                                 if (!context.mounted) return;
                                PedidosHelper.actualizarEstadoPedido(
                                  context: context,
                                  pedido: widget.pedido,
                                  nuevoEstado: 0,
                                  onUpdate: () => widget.onUpdate(),
                                  bloquearBoton: widget.bloquearBoton,
                                );
                              },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    icon: const Icon(Icons.cancel, color: Colors.white),
                    label: const Text('Cancelar', style: TextStyle(color: Colors.white)),
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
    final estado = int.tryParse(widget.pedido.estado) ?? 0;
    final bloqueado = widget.bloqueoBotones[widget.pedido.id] == true;
    if (estado == 0 || estado >= 8) return true;
    if (bloqueado) return true;
    return false;
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
