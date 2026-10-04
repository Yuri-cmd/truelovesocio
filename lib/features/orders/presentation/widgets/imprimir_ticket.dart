import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:truelovesocio/data/models/pedido_model.dart';
import 'package:truelovesocio/data/services/ticket_printer_service.dart';

final TicketPrinterService _impresoras = TicketPrinterService();

/// Imprime el ticket del pedido en la ticketera Bluetooth del socio. La primera
/// vez pide elegir la impresora y después la recuerda: un toque y sale.
Future<void> imprimirTicket(BuildContext context, Pedido pedido) async {
  var impresora = await _impresoras.obtenerGuardada();
  if (impresora == null) {
    if (!context.mounted) return;
    impresora = await elegirImpresora(context);
    if (impresora == null) return;
  }

  try {
    await _impresoras.imprimir(pedido, impresora);
    Get.snackbar(
      'Ticket enviado',
      'Pedido #${pedido.id} → ${impresora.nombre}',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  } on ImpresoraException catch (e) {
    if (context.mounted) _avisarError(context, e.mensaje);
  } catch (e) {
    if (context.mounted) _avisarError(context, 'No se pudo imprimir: $e');
  }
}

void _avisarError(BuildContext context, String mensaje) {
  Get.snackbar(
    'No se pudo imprimir',
    mensaje,
    snackPosition: SnackPosition.BOTTOM,
    duration: const Duration(seconds: 6),
    mainButton: TextButton(
      onPressed: () {
        Get.closeCurrentSnackbar();
        if (context.mounted) elegirImpresora(context);
      },
      child: const Text('Cambiar impresora'),
    ),
  );
}

/// Muestra las impresoras Bluetooth emparejadas para elegir una. Devuelve la
/// elegida (ya guardada) o `null` si el socio cierra el panel.
Future<ImpresoraGuardada?> elegirImpresora(BuildContext context) {
  return showModalBottomSheet<ImpresoraGuardada>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _ElegirImpresoraSheet(),
  );
}

class _ElegirImpresoraSheet extends StatefulWidget {
  const _ElegirImpresoraSheet();

  @override
  State<_ElegirImpresoraSheet> createState() => _ElegirImpresoraSheetState();
}

class _ElegirImpresoraSheetState extends State<_ElegirImpresoraSheet> {
  late Future<List<BluetoothInfo>> _dispositivos;
  int _papelMm = 80;

  @override
  void initState() {
    super.initState();
    _cargar();
    _impresoras.obtenerGuardada().then((g) {
      if (g != null && mounted) setState(() => _papelMm = g.papelMm);
    });
  }

  void _cargar() {
    _dispositivos = _impresoras.impresorasEmparejadas();
  }

  Future<void> _elegir(BluetoothInfo d) async {
    final impresora = ImpresoraGuardada(nombre: d.name, mac: d.macAdress, papelMm: _papelMm);
    await _impresoras.guardar(impresora);
    if (mounted) Navigator.of(context).pop(impresora);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Elige tu impresora', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                'Solo aparecen las impresoras ya emparejadas en el Bluetooth del teléfono.',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 12),
              const Text('Ancho del papel', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 58, label: Text('58 mm')),
                  ButtonSegment(value: 80, label: Text('80 mm')),
                ],
                selected: {_papelMm},
                onSelectionChanged: (s) => setState(() => _papelMm = s.first),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: FutureBuilder<List<BluetoothInfo>>(
                  future: _dispositivos,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator(color: Colors.red)),
                      );
                    }
                    if (snapshot.hasError) {
                      return _mensaje(snapshot.error is ImpresoraException
                          ? (snapshot.error as ImpresoraException).mensaje
                          : 'No se pudo leer el Bluetooth: ${snapshot.error}');
                    }
                    final lista = snapshot.data ?? [];
                    if (lista.isEmpty) {
                      return _mensaje(
                        'No hay impresoras emparejadas. Empareja la ticketera en Ajustes > Bluetooth del teléfono y vuelve a intentar.',
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: lista.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) => ListTile(
                        leading: const Icon(Icons.print_rounded),
                        title: Text(lista[i].name),
                        subtitle: Text(lista[i].macAdress),
                        onTap: () => _elegir(lista[i]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mensaje(String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(texto, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => setState(_cargar),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
