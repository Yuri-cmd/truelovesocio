import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:truelovesocio/model/pedido_model.dart';
import 'package:truelovesocio/service/api_service.dart';
import 'package:truelovesocio/theme/app_theme.dart';
import 'package:truelovesocio/utils/helpers.dart';
import 'package:url_launcher/url_launcher.dart';
class HistoricoPedidosScreen extends StatefulWidget {
  const HistoricoPedidosScreen({super.key});

  @override
  State<HistoricoPedidosScreen> createState() => _HistoricoPedidosScreenState();
}

class _HistoricoPedidosScreenState extends State<HistoricoPedidosScreen> {
  final ApiService _apiService = ApiService();
  List<Pedido> _pedidos = [];
  bool _isLoading = true;
  String _selectedFecha = 'todas';
  String _selectedTipo = 'todos';
  final Set<int> _expanded = {};

  @override
  void initState() {
    super.initState();
    _loadPedidos();
  }

  Future<void> _loadPedidos() async {
    try {
      setState(() => _isLoading = true);
      final pedidos = await _apiService.fetchPedidosConFiltros(
        fecha: _selectedFecha,
        tipo: _selectedTipo,
      );
      setState(() {
        _pedidos = pedidos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if(!mounted) return;  
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar pedidos: $e')),
      );
    }
  }

  String _formatDate(String? fecha) {
    if (fecha == null || fecha.isEmpty) return 'Sin fecha';
    try {
      final dt = DateTime.parse(fecha);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return fecha;
    }
  }

  String? _getPhotoUrl(dynamic pedido) {
    final v1 = pedido.fotoPago;
    if (v1 == null) return null;
    if (v1 is String && v1.isNotEmpty) return v1;
    return null;
  }

  Future<void> _showPhotoDialog(String photoUrl) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: true, // Permitir cerrar el diálogo al hacer clic fuera
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: Image.network(photoUrl, fit: BoxFit.contain),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                // Usar el context del builder para cerrar correctamente el diálogo
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

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

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    }
    return 0.0;
  }

  Future<void> _llamar(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    await launchUrl(launchUri);
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primary;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Histórico de pedidos'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedFecha,
                    decoration: InputDecoration(
                      labelText: 'Fecha',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'todas', child: Text('Todas')),
                      DropdownMenuItem(value: 'hoy', child: Text('Hoy')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _selectedFecha = v);
                        _loadPedidos();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedTipo,
                    decoration: InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'todos', child: Text('Todos')),
                      DropdownMenuItem(value: 'finalizados', child: Text('Finalizados')),
                      DropdownMenuItem(value: 'activos', child: Text('Activos')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _selectedTipo = v);
                        _loadPedidos();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // Lista
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _pedidos.isEmpty
                    ? const Center(child: Text('No hay pedidos disponibles'))
                    : RefreshIndicator(
                        onRefresh: _loadPedidos,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _pedidos.length,
                          itemBuilder: (context, idx) {
                            final pedido = _pedidos[idx];
                            final photoUrl = _getPhotoUrl(pedido);
                            final estadoText = obtenerEstado(int.parse(pedido.estado));
                            final estadoColor = obtenerColorEstado(int.parse(pedido.estado));

                            final subtotal = _toDouble(pedido.subtotal);
                            final delivery = _toDouble(pedido.precioDelivery);
                            final descuento = _toDouble(pedido.descuento);
                            final total = subtotal + delivery - descuento;
                            final isExpanded = _expanded.contains(pedido.id);

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withAlpha(25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Pedido #${pedido.id}',
                                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                              Text(pedido.cliente,
                                                  style: const TextStyle(color: Colors.black54)),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: estadoColor.withAlpha(38),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            estadoText,
                                            style: TextStyle(color: estadoColor, fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),
                                    Text('Dirección: ${pedido.direccionEntrega}',
                                        style: const TextStyle(color: Colors.grey)),
                                    GestureDetector(
                                      onTap: () => _llamar(pedido.celular),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.phone, color: Colors.green, size: 16),
                                          const SizedBox(width: 4),
                                          Text('Cliente: ${pedido.celular}',
                                              style: const TextStyle(color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: () => _llamar(pedido.celularMotorizado),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.phone, color: Colors.green, size: 16),
                                          const SizedBox(width: 4),
                                          Text('Motorizado: ${pedido.celularMotorizado}',
                                              style: const TextStyle(color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Fecha: ${_formatDate(pedido.fecha)}',
                                        style: const TextStyle(color: Colors.grey)),
                                    const Divider(height: 20),

                                    if (isExpanded)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Productos:', style: TextStyle(fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 8),
                                          ...(pedido.detalleArray).map((d) => Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 2),
                                                child: Row(
                                                  children: [
                                                    Expanded(child: Text('${d.cantidad}x ${d.nombre}')),
                                                    Text('S/. ${d.precio}'),
                                                  ],
                                                ),
                                              )),
                                          const Divider(),
                                        ],
                                      ),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Total: S/. ${total.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold, color: Colors.black87)),
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              if (isExpanded) {
                                                _expanded.remove(pedido.id);
                                              } else {
                                                _expanded.add(pedido.id);
                                              }
                                            });
                                          },
                                          child: Text(isExpanded ? 'Ver menos' : 'Ver más'),
                                        ),
                                      ],
                                    ),

                                    if (photoUrl != null)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          ElevatedButton.icon(
                                            onPressed: () => _showPhotoDialog(photoUrl),
                                            icon: const Icon(Icons.remove_red_eye, size: 16),
                                            label: const Text('Ver pago'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            onPressed: () => _downloadImage(photoUrl),
                                            icon: const Icon(Icons.download),
                                            tooltip: 'Descargar comprobante',
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}