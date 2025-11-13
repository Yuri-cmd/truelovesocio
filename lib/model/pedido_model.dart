import 'package:truelovesocio/model/detall_pedido_model.dart';

class Pedido {
  final int id;
  final String local;
  final String direccionLocal;
  final String direccionEntrega;
  final String cliente;
  final String celular;
  final int tiempoEstimado;
  final String detalle;
  final String latLocal;
  final String lonLocal;
  final String latitud;
  final String longitud;
  final String productos;
  String estado;
  final String motorizado;
  final String celularMotorizado;
  final String nota;
  final String tipoPago;
  int tiempo;
  bool requiereConfirmacionLocal;
  final List<DetallePedido> detalleArray;
  final String tipoComprobante;
  final String documento;
  final String fotoPago;
  final int tipoPedido;
  final String fecha;
  final String subtotal;
  final String precioDelivery;
  final String descuento;

  Pedido({
    required this.id,
    required this.local,
    required this.direccionLocal,
    required this.direccionEntrega,
    required this.cliente,
    required this.celular,
    required this.tiempoEstimado,
    required this.detalle,
    required this.latLocal,
    required this.lonLocal,
    required this.latitud,
    required this.longitud,
    required this.productos,
    required this.estado,
    required this.detalleArray,
    required this.tiempo,
    required this.motorizado,
    required this.celularMotorizado,
    required this.nota,
    required this.tipoPago,
    required this.requiereConfirmacionLocal,
    required this.tipoComprobante,
    required this.documento,
    required this.fotoPago,
    required this.tipoPedido,
    required this.fecha,
    this.subtotal = '0.00',
    this.precioDelivery = '0.00',
    this.descuento = '0.00',
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      id: json['id'],
      local: json['local'] ?? '',
      direccionLocal: json['direccion_local'] ?? '',
      direccionEntrega: json['direccion_entrega'] ?? '',
      cliente: json['cliente'] ?? '',
      celular: json['celular'] ?? '',
      tiempoEstimado: json['tiempo_estimado'] ?? 0,
      detalle: json['detalle'] ?? '',
      latLocal: json['latitud'] ?? '',
      lonLocal: json['longitud'] ?? '',
      latitud: json['lat_local'] ?? '',
      longitud: json['lon_local'] ?? '',
      productos: json['detalle'] ?? '',
      estado: json['ultimo_estado_tracking'] ?? '',
      tiempo: json['tiempo'] ?? 0,
      motorizado: json['motorizado'] ?? '',
      celularMotorizado: json['celularMotorizado'] ?? '',
      nota: json['nota'] ?? '',
      tipoPago: json['tipo_pago'] ?? '',
      requiereConfirmacionLocal: json['requiere_confirmacion_local'] ?? false,
      tipoComprobante: json['tipo_comprobante'] ?? '',
      documento: json['documento'] ?? '',
      fotoPago: json['foto_pago'] ?? '',
      tipoPedido: json['tipo_pedido'],
      fecha: json['created_at'] ?? '',
      subtotal: json['subtotal']?.toString() ?? '0.00',
      precioDelivery: json['precio_delivery']?.toString() ?? '0.00',
      descuento: json['descuento']?.toString() ?? '0.00',
      detalleArray:
          (json['detalleArray'] as List<dynamic>?)
              ?.map((item) => DetallePedido.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'local': local,
      'direccion_local': direccionLocal,
      'direccion_entrega': direccionEntrega,
      'cliente': cliente,
      'celular': celular,
      'lat_local': latLocal,
      'lon_local': lonLocal,
      'latitud': latitud,
      'longitud': longitud,
      'tiempoEstimado': tiempoEstimado,
      'productos': productos,
      'estado': estado,
      'nota': nota,
      'tipo_pago': tipoPago,
      'requiere_confirmacion_local': requiereConfirmacionLocal,
      'tipo_pedido': tipoPedido,
      'created_at': fecha,
      'subtotal': subtotal,
      'precio_delivery': precioDelivery,
      'descuento': descuento,
    };
  }
}
