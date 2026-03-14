import 'package:truelovesocio/core/utils/url_helper.dart';

class Menu {
  final int id;
  final String titulo;
  final String descripcion;
  final String foto;
  final String precio;
  String status;

  Menu({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.foto,
    required this.precio,
    required this.status,
  });

  factory Menu.fromJson(Map<String, dynamic> json) {
    return Menu(
      id: json['id'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      foto: UrlHelper.fixUrl(json['foto']),
      precio: json['precio'],
      status: json['status'],
    );
  }
}
