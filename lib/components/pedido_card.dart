import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:truelovesocio/model/pedido_model.dart';
import 'package:truelovesocio/service/api_service.dart';
import 'package:truelovesocio/utils/helpers.dart';
import 'package:truelovesocio/utils/pedidos_helper.dart';
import 'package:path_provider/path_provider.dart';

class PedidoCard extends StatefulWidget {
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
  State<PedidoCard> createState() => _PedidoCardState();
}

class _PedidoCardState extends State<PedidoCard> {

  Future<void> _downloadImage(String url) async {
    // NOTE
    // Writing into the app's documents directory does NOT require the
    // runtime storage permission. Requesting `Permission.storage` is often
    // denied on Android 11+ (API 30+) because scoped storage changed and
    // WRITE_EXTERNAL_STORAGE / MANAGE_EXTERNAL_STORAGE behave differently.
    // To avoid permission issues, save to the app's internal documents dir.
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savePath = '${dir.path}/$fileName';

      // Download directly to the app documents directory (temporary storage)
      await Dio().download(url, savePath);

      // Try to move the downloaded temp file into the public Downloads folder via platform channel
      const platform = MethodChannel('app.channel.documents');
      try {
        final displayName = fileName; // e.g. 163...jpg
        final out = await platform.invokeMethod<String>(
          'saveFileToDownloads',
          {'path': savePath, 'displayName': displayName},
        );

        if (!mounted) return;
        if (out != null) {
          // Delete temp file to avoid duplicate storage
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
        // If native saving fails, at least inform about local temp path
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
                    widget.pedido.cliente,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Chip(
                  label: Text(
                    obtenerEstado(int.parse(widget.pedido.estado)),
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: obtenerColorEstado(int.parse(widget.pedido.estado)),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Divider(color: colorScheme.surfaceContainerHighest),

            infoRow(
              context,
              Icons.location_on,
              widget.pedido.direccionEntrega,
              color: Colors.indigo,
            ),
            infoRow(context, Icons.phone, widget.pedido.celular, color: Colors.green),
            infoRow(
              context,
              Icons.person,
              widget.pedido.cliente,
              color: Colors.orange,
            ),
            infoRow(
              context,
              Icons.timer,
              '${widget.pedido.tiempo} min',
              color: Colors.orange,
            ),
            infoRow(
              context,
              Icons.article_sharp,
              widget.pedido.nota,
              color: Colors.blue,
            ),

            const SizedBox(height: 6),
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
                        // Verificar si hay foto de pago
                        if (widget.pedido.fotoPago.isEmpty ||
                            widget.pedido.fotoPago == 'null') {
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('No hay foto'),
                                  content: const Text(
                                    'No se ha cargado una foto del pago.',
                                  ),
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
                                      // Header del diálogo
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
                                              tooltip: 'Descargar imagen',
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Imagen
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          child: Image.network(
                                            widget.pedido.fotoPago,
                                            fit: BoxFit.contain,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return const Text(
                                                'Error al cargar la imagen',
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      // Pregunta y botones
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          children: [
                                            const Text(
                                              '¿Deseas verificar este pago?',
                                              style: TextStyle(fontSize: 16),
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                              children: [
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
                                                      pedido: widget.pedido,
                                                      apiService: widget.apiService,
                                                      onUpdate: () => widget.onUpdate(),
                                                    );

                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Pago verificado correctamente',
                                                          ),
                                                        ),
                                                      );
                                                    }
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
                      onPressed:
                          int.parse(widget.pedido.estado) == 0 ||
                                  widget.bloqueoBotones[widget.pedido.id] == true
                              ? null
                              : () {
                                PedidosHelper.actualizarEstadoPedido(
                                  context: context,
                                  pedido: widget.pedido,
                                  nuevoEstado: 2,
                                  apiService: widget.apiService,
                                  onUpdate: () => widget.onUpdate(),
                                  bloquearBoton: widget.bloquearBoton,
                                );
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      icon: const Icon(Icons.check_circle, color: Colors.white),
                      label: Text(
                        int.parse(widget.pedido.estado) == 0 ||
                                int.parse(widget.pedido.estado) == 1
                            ? 'Aceptar'
                            : 'Ver Pedido',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                ElevatedButton.icon(
                  onPressed:
                      _debeDeshabilitarBotonCancelar()
                          ? null
                          : () {
                            PedidosHelper.actualizarEstadoPedido(
                              context: context,
                              pedido: widget.pedido,
                              nuevoEstado: 0,
                              apiService: widget.apiService,
                              onUpdate: () => widget.onUpdate(),
                              bloquearBoton: widget.bloquearBoton,
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
    final estado = int.parse(widget.pedido.estado);
    return estado == 0 || estado >= 2 || widget.bloqueoBotones[widget.pedido.id] == true;
  }

  Widget infoRow(
    BuildContext context,
    IconData icon,
    String text, {
    Color color = Colors.black,
  }) {
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
