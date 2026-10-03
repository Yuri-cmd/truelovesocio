import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:truelovesocio/data/services/order_service.dart';

/// Resolución típica de una ticketera térmica (203 dpi): 80 mm ≈ 640 px.
const double _kDpiTicketera = 203;

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
  String? _error;
  bool _cargado = false;

  /// PDF original del backend. Se usa tal cual si no se puede convertir a imagen.
  Uint8List? _pdfOriginal;

  /// Páginas del ticket convertidas a imagen (PNG a 203 dpi).
  final List<_PaginaTicket> _paginas = [];

  /// Tamaño real del ticket (80 mm de ancho) para la vista previa. Para
  /// imprimir, el tamaño lo define Android según la impresora elegida y el PDF
  /// se arma de nuevo a ese ancho (ver [_armarPdf]).
  PdfPageFormat _formato = PdfPageFormat.roll80;

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
      final pdf = Uint8List.fromList(data);
      await _rasterizar(pdf);
      if (!mounted) return;
      setState(() {
        _pdfOriginal = pdf;
        _cargado = true;
      });
    } catch (e) {
      setState(() => _error = 'Error al cargar el comprobante: $e');
    }
  }

  /// Convierte cada página del PDF en una imagen. Los servicios de impresión
  /// de las ticketeras suelen reinterpretar el PDF (texto por un lado, imágenes
  /// por otro) y el comprobante sale distinto: logo gigante y rayado, bordes
  /// como "=====". Como imagen, sale igual que en la vista previa.
  /// Si la conversión falla, se imprime el PDF original.
  Future<void> _rasterizar(Uint8List pdf) async {
    _paginas.clear();
    try {
      await for (final page in Printing.raster(pdf, dpi: _kDpiTicketera)) {
        _paginas.add(_PaginaTicket(await page.toPng(), page.width, page.height));
      }
      if (_paginas.isNotEmpty) {
        final p = _paginas.first;
        _formato = PdfPageFormat(
          p.ancho * PdfPageFormat.inch / _kDpiTicketera,
          p.alto * PdfPageFormat.inch / _kDpiTicketera,
          marginAll: 0,
        );
      }
    } catch (e) {
      debugPrint('No se pudo convertir el comprobante a imagen: $e');
      _paginas.clear();
    }
  }

  /// Arma el PDF con las imágenes del ticket al ancho útil del papel que pide
  /// Android (el de la impresora elegida), así llena el papel sea cual sea
  /// su tamaño en vez de quedar chico dentro de una hoja Letter.
  Future<Uint8List> _armarPdf(PdfPageFormat format) async {
    if (_paginas.isEmpty) return _pdfOriginal!;

    var ancho = format.availableWidth;
    if (!ancho.isFinite || ancho <= 0) ancho = _formato.width;

    final doc = pw.Document();
    for (final p in _paginas) {
      final alto = ancho * p.alto / p.ancho;
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(
            format.marginLeft + ancho + format.marginRight,
            format.marginTop + alto + format.marginBottom,
            marginLeft: format.marginLeft,
            marginTop: format.marginTop,
            marginRight: format.marginRight,
            marginBottom: format.marginBottom,
          ),
          margin: pw.EdgeInsets.fromLTRB(
            format.marginLeft,
            format.marginTop,
            format.marginRight,
            format.marginBottom,
          ),
          build: (_) => pw.Image(pw.MemoryImage(p.png), width: ancho, height: alto, fit: pw.BoxFit.fill),
        ),
      );
    }
    return doc.save();
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

    if (!_cargado) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }

    return PdfPreview(
      build: _armarPdf,
      initialPageFormat: _formato,
      pageFormats: {'Ticket 80 mm': _formato},
      canChangePageFormat: false,
      canDebug: false,
      pdfFileName: 'ticket-pedido-${widget.pedidoId}.pdf',
    );
  }
}

class _PaginaTicket {
  final Uint8List png;
  final int ancho;
  final int alto;

  const _PaginaTicket(this.png, this.ancho, this.alto);
}
