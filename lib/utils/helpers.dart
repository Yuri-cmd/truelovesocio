import 'package:flutter/material.dart';

String obtenerEstado(int estado) {
  switch (estado) {
    case 0:
      return 'Cancelado';
    case 1:
      return 'Pendiente';
    case 2:
      return 'Preparando pedido';
    case 3:
      return 'Pedido listo';
    case 4:
      return 'Motorizado aceptó';
    case 5:
      return 'Motorizado en restaurante';
    case 6:
      return 'Motorizado en camino';
    case 7:
      return 'Motorizado llegó al domicilio';
    case 8:
      return 'Pedido entregado';
    default:
      return 'Desconocido';
  }
}

Color obtenerColorEstado(int estado) {
  switch (estado) {
    case 0:
      return Colors.redAccent;
    case 1:
      return Colors.amber;
    case 2:
      return Colors.green;
    case 3:
    case 4:
    case 5:
    case 6:
      return Colors.blueAccent;
    case 7:
      return Colors.teal;
    default:
      return Colors.grey;
  }
}

Widget getMetodoPagoImage(String? tipoPago) {
  String imageName;

  switch (tipoPago?.toLowerCase()) {
    case 'yape':
      imageName = 'yape.png';
      break;
    case 'plin':
      imageName = 'plin.png';
      break;
    case 'efectivo':
      imageName = 'efectivo.png';
      break;
    case 'pos tarjeta credito':
    case 'pos':
      imageName = 'pos.png';
      break;
    default:
      return const SizedBox(); // No imagen si no se reconoce
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(
      12,
    ), // Mitad del ancho/alto para que sea circular
    child: Image.asset(
      'images/$imageName',
      width: 24,
      height: 24,
      fit: BoxFit.cover,
    ),
  );
}
