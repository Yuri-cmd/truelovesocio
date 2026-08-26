import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';
import 'package:truelovesocio/data/services/order_service.dart';

/// Muestra el mismo comprobante (ticket térmico 80mm) que se ve en la web,
/// generado por el backend (`GET /pedido/{id}/ticket`). Permite verlo,
/// compartirlo o imprimirlo (según lo que soporte el dispositivo/SO).
class TicketPreviewScreen extends StatefulWidget {
  final int pedidoId;

  const TicketPreviewScreen({super.key, required this.pedidoId});

  @override
  State<TicketPreviewScreen> createState() => _TicketPreviewScreenState();
}

class _TicketPreviewScreenState extends State<TicketPreviewScreen> {
  final OrderService _orderService = Get.find<OrderService>();
  Uint8List? _bytes;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarTicket();
  }

  Future<void> _cargarTicket() async {
    try {
      final response = await _orderService.fetchTicketPdf(widget.pedidoId);
      final data = response.data;
      if (data == null) {
        setState(() => _error = 'No se pudo obtener el comprobante');
        return;
      }
      setState(() => _bytes = Uint8List.fromList(data));
    } catch (e) {
      setState(() => _error = 'Error al cargar el comprobante: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comprobante #${widget.pedidoId}'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => _error = null);
                  _cargarTicket();
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_bytes == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }

    return PdfPreview(
      build: (format) => _bytes!,
      canChangePageFormat: false,
      canDebug: false,
      pdfFileName: 'ticket-pedido-${widget.pedidoId}.pdf',
    );
  }
}
