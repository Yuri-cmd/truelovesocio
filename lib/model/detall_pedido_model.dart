class DetallePedido {
  final int id;
  final int pedidoId;
  final String nombre;
  final int cantidad;
  final String precio;
  final String tipo;
  
  DetallePedido({
    required this.id,
    required this.pedidoId,
    required this.nombre,
    required this.cantidad,
    required this.precio,
    required this.tipo,
  });

  factory DetallePedido.fromJson(Map<String, dynamic> json) {
    return DetallePedido(
      id: json['id'],
      pedidoId: json['pedido_id'],
      nombre: json['nombre'] ?? '',
      cantidad: json['cantidad'] ?? 0,
      precio: json['precio'] ?? '0.00',
      tipo: json['tipo'] ?? '',
    );
  }
}
