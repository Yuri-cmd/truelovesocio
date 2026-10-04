import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:truelovesocio/core/utils/helpers.dart';
import 'package:truelovesocio/data/models/pedido_model.dart';

/// Error con un mensaje listo para mostrarle al socio.
class ImpresoraException implements Exception {
  final String mensaje;

  const ImpresoraException(this.mensaje);

  @override
  String toString() => mensaje;
}

/// Impresora elegida por el socio, que se recuerda entre sesiones.
class ImpresoraGuardada {
  final String nombre;
  final String mac;

  /// Ancho del papel en mm: 58 u 80.
  final int papelMm;

  const ImpresoraGuardada({required this.nombre, required this.mac, required this.papelMm});
}

/// Imprime el ticket de un pedido en una ticketera Bluetooth usando ESC/POS
/// (el lenguaje que entienden casi todas las térmicas), sin pasar por el
/// servicio de impresión de Android: éste reconvertía el PDF y el ticket salía
/// con bandas y el logo roto.
class TicketPrinterService {
  static const _kMac = 'impresora_mac';
  static const _kNombre = 'impresora_nombre';
  static const _kPapel = 'impresora_papel_mm';

  String? _macConectada;

  Future<ImpresoraGuardada?> obtenerGuardada() async {
    final prefs = await SharedPreferences.getInstance();
    final mac = prefs.getString(_kMac);
    if (mac == null || mac.isEmpty) return null;
    return ImpresoraGuardada(
      nombre: prefs.getString(_kNombre) ?? mac,
      mac: mac,
      papelMm: prefs.getInt(_kPapel) ?? 80,
    );
  }

  Future<void> guardar(ImpresoraGuardada impresora) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMac, impresora.mac);
    await prefs.setString(_kNombre, impresora.nombre);
    await prefs.setInt(_kPapel, impresora.papelMm);
    _macConectada = null;
  }

  /// Impresoras Bluetooth ya emparejadas con el teléfono.
  Future<List<BluetoothInfo>> impresorasEmparejadas() async {
    await _asegurarBluetooth();
    return PrintBluetoothThermal.pairedBluetooths;
  }

  Future<void> imprimir(Pedido pedido, ImpresoraGuardada impresora) async {
    await _asegurarBluetooth();
    final bytes = await _armarTicket(pedido, impresora.papelMm);

    await _conectar(impresora);
    var ok = await PrintBluetoothThermal.writeBytes(bytes);
    if (!ok) {
      // La conexión pudo haberse caído (impresora dormida o apagada): se
      // reconecta y se reintenta una vez.
      _macConectada = null;
      await PrintBluetoothThermal.disconnect;
      await _conectar(impresora);
      ok = await PrintBluetoothThermal.writeBytes(bytes);
    }
    if (!ok) {
      throw const ImpresoraException('No se pudo enviar el ticket a la impresora. Revisa que esté encendida y cerca.');
    }
  }

  Future<void> _asegurarBluetooth() async {
    if (!await PrintBluetoothThermal.isPermissionBluetoothGranted) {
      throw const ImpresoraException('Falta el permiso de Bluetooth. Actívalo en los ajustes de la aplicación.');
    }
    if (!await PrintBluetoothThermal.bluetoothEnabled) {
      throw const ImpresoraException('Activa el Bluetooth del teléfono para imprimir.');
    }
  }

  Future<void> _conectar(ImpresoraGuardada impresora) async {
    if (_macConectada == impresora.mac && await PrintBluetoothThermal.connectionStatus) return;

    await PrintBluetoothThermal.disconnect;
    final conectado = await PrintBluetoothThermal.connect(macPrinterAddress: impresora.mac);
    if (!conectado) {
      throw ImpresoraException(
        'No se pudo conectar con "${impresora.nombre}". Revisa que esté encendida, cerca y emparejada.',
      );
    }
    _macConectada = impresora.mac;
  }

  /// Arma el ticket con los mismos datos que el comprobante del backend.
  Future<List<int>> _armarTicket(Pedido p, int papelMm) async {
    final perfil = await CapabilityProfile.load();
    final g = Generator(papelMm == 58 ? PaperSize.mm58 : PaperSize.mm80, perfil);

    const centrado = PosStyles(align: PosAlign.center, bold: true);
    const derecha = PosStyles(align: PosAlign.right);
    const derechaNegrita = PosStyles(align: PosAlign.right, bold: true);
    const negrita = PosStyles(bold: true);

    final detalles = p.detalleArray;
    final subtotal = detalles.fold<double>(0, (suma, d) => suma + (double.tryParse(d.precio) ?? 0) * d.cantidad);
    final descuento = double.tryParse(p.descuento) ?? 0;
    final total = subtotal - descuento;
    final esDelivery = p.tipoPedido == 0;
    final nota = p.nota.trim();

    final b = <int>[];
    b.addAll(g.reset());

    b.addAll(g.text('TRUELOVE DELIVERY', styles: centrado.copyWith(height: PosTextSize.size2, width: PosTextSize.size2)));
    if (p.local.isNotEmpty) {
      b.addAll(g.text(_ascii(p.local), styles: centrado.copyWith(height: PosTextSize.size2)));
    }
    b.addAll(g.hr(ch: '='));
    b.addAll(g.text('PEDIDO No ${p.id}', styles: centrado.copyWith(height: PosTextSize.size2, width: PosTextSize.size2)));
    b.addAll(g.hr(ch: '='));

    b.addAll(g.text('Fecha: ${formatearFecha(p.fecha)}'));
    b.addAll(g.text('Cliente: ${_ascii(p.cliente)}'));
    if (p.celular.isNotEmpty) b.addAll(g.text('Telefono: ${p.celular}'));
    if (esDelivery && p.direccionEntrega.isNotEmpty) {
      b.addAll(g.text('Direccion: ${_ascii(p.direccionEntrega)}'));
    }
    b.addAll(g.text('Tipo: ${esDelivery ? 'DELIVERY' : 'RECOJO EN TIENDA'}'));
    b.addAll(g.text('Forma de pago: ${_ascii(p.tipoPago.isEmpty ? 'EFECTIVO' : p.tipoPago.toUpperCase())}'));
    b.addAll(g.hr());

    b.addAll(g.row([
      PosColumn(text: 'CANT', width: 2, styles: negrita),
      PosColumn(text: 'DESCRIPCION', width: 5, styles: negrita),
      PosColumn(text: 'P.UNIT', width: 2, styles: derechaNegrita),
      PosColumn(text: 'TOTAL', width: 3, styles: derechaNegrita),
    ]));
    for (final d in detalles) {
      final precio = double.tryParse(d.precio) ?? 0;
      final nombre = d.tipo == 'adicional' ? '${d.nombre} (Adic.)' : d.nombre;
      b.addAll(g.row([
        PosColumn(text: '${d.cantidad}', width: 2),
        PosColumn(text: _ascii(nombre), width: 5),
        PosColumn(text: precio.toStringAsFixed(2), width: 2, styles: derecha),
        PosColumn(text: (precio * d.cantidad).toStringAsFixed(2), width: 3, styles: derecha),
      ]));
    }
    b.addAll(g.hr());

    if (descuento > 0) {
      b.addAll(g.row([
        PosColumn(text: 'Descuento:', width: 7, styles: derecha),
        PosColumn(text: '-S/ ${descuento.toStringAsFixed(2)}', width: 5, styles: derecha),
      ]));
    }
    b.addAll(g.row([
      PosColumn(text: 'TOTAL', width: 5, styles: negrita.copyWith(height: PosTextSize.size2)),
      PosColumn(
        text: 'S/ ${total.toStringAsFixed(2)}',
        width: 7,
        styles: derechaNegrita.copyWith(height: PosTextSize.size2),
      ),
    ]));

    if (p.motorizado.isNotEmpty) {
      b.addAll(g.text('Motorizado: ${_ascii(p.motorizado)}'));
    }
    if (nota.isNotEmpty && nota != 'Sin nota') {
      b.addAll(g.hr());
      b.addAll(g.text('Observaciones: ${_ascii(nota)}', styles: negrita));
    }

    b.addAll(g.hr());
    b.addAll(g.text('Gracias por su preferencia!', styles: centrado));
    b.addAll(g.text('TRUELOVE DELIVERY', styles: const PosStyles(align: PosAlign.center)));
    b.addAll(g.feed(3));
    b.addAll(g.cut());
    return b;
  }

  /// Pasa el texto a ASCII (sin tildes ni eñes ni emojis). Cada ticketera usa
  /// una tabla de caracteres distinta y con tildes algunas imprimen símbolos
  /// raros; así sale bien en cualquier modelo.
  static String _ascii(String texto) {
    const mapa = {
      'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n',
      'Á': 'A', 'É': 'E', 'Í': 'I', 'Ó': 'O', 'Ú': 'U', 'Ü': 'U', 'Ñ': 'N',
      'à': 'a', 'è': 'e', 'ì': 'i', 'ò': 'o', 'ù': 'u',
      '°': 'o', 'º': 'o', 'ª': 'a', '¿': '?', '¡': '!',
      '“': '"', '”': '"', '‘': "'", '’': "'", '–': '-', '—': '-',
    };
    final sb = StringBuffer();
    for (final c in texto.split('')) {
      final r = mapa[c] ?? c;
      final codigo = r.codeUnitAt(0);
      if (codigo == 10 || codigo == 13) {
        sb.write(' ');
      } else if (codigo >= 32 && codigo < 127) {
        sb.write(r);
      }
      // Cualquier otro carácter (emojis, símbolos) se descarta.
    }
    return sb.toString().trim();
  }
}
