import 'package:flutter/material.dart';
import 'package:truelovesocio/data/models/adicional_model.dart';

/// Bottom sheet para elegir hasta cuándo se agota un producto/opción.
/// Devuelve la clave de la duración elegida ('medianoche', '1_dia', etc.) o null si se canceló.
Future<String?> showAgotarHastaSheet(BuildContext context, {required String titulo}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                ),
              ),
              Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 16),
              ...DuracionAgotado.opciones.map(
                (opcion) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(opcion.key),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide.none,
                      ),
                      child: Text(opcion.label.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
