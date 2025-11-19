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
    case 9:
      return 'Pedido listo para recoger';
    default:
      return 'Desconocido';
  }
}

/// Paleta propuesta para cada estado con hex y un sentido semántico:
/// 0: error (rojo), 1: advertencia (ámbar), 2: en preparación (naranja),
/// 3: listo en local (índigo), 4: aceptado (azul), 5: en restaurante (azul claro),
/// 6: en camino (naranja/alerta), 7: llegó (teal), 8: entregado (éxito/verde),
/// 9: listo para recoger (púrpura).
Color obtenerColorEstado(int estado) {
  switch (estado) {
    case 0:
      return const Color(0xFFD32F2F); // Red 700 - #D32F2F (Cancelado)
    case 1:
      return const Color(0xFFFFA000); // Amber 700 - #FFA000 (Pendiente)
    case 2:
      return const Color(
        0xFFFB8C00,
      ); // Orange 600 - #FB8C00 (Preparando pedido)
    case 3:
      return const Color(0xFF3949AB); // Indigo 600 - #3949AB (Pedido listo)
    case 4:
      return const Color(0xFF1976D2); // Blue 700 - #1976D2 (Motorizado aceptó)
    case 5:
      return const Color(
        0xFF0288D1,
      ); // Light Blue 600 - #0288D1 (Motorizado en restaurante)
    case 6:
      return const Color(
        0xFFFF7043,
      ); // Deep Orange 400 - #FF7043 (Motorizado en camino)
    case 7:
      return const Color(
        0xFF00796B,
      ); // Teal 700 - #00796B (Motorizado llegó al domicilio)
    case 8:
      return const Color(0xFF2E7D32); // Green 700 - #2E7D32 (Pedido entregado)
    case 9:
      return const Color(
        0xFF8E24AA,
      ); // Purple 600 - #8E24AA (Pedido listo para recoger)
    default:
      return Colors.grey; // Desconocido
  }
}

/// Helper: devuelve color de texto (black/white) según contraste con el fondo.
Color textoContraste(Color background) {
  // computeLuminance devuelve 0 (oscuro) a 1 (claro). Umbral ~0.5 funciona bien.
  return background.computeLuminance() > 0.5 ? Colors.black : Colors.white;
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
