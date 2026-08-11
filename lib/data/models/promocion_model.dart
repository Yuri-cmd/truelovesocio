import 'package:truelovesocio/core/utils/url_helper.dart';

class Promocion {
  final int id;
  final String titulo;
  final String subtitulo;
  final String imagen;
  bool estado;

  Promocion({
    required this.id,
    required this.titulo,
    required this.subtitulo,
    required this.imagen,
    required this.estado,
  });

  factory Promocion.fromJson(Map<String, dynamic> json) {
    return Promocion(
      id: json['id'],
      titulo: json['titulo'] ?? '',
      subtitulo: json['subtitulo'] ?? '',
      imagen: UrlHelper.fixUrl(json['imagen']?.toString()),
      estado: json['estado'] == 1 || json['estado'] == true,
    );
  }
}
