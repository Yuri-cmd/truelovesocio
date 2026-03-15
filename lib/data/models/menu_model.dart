import 'package:truelovesocio/core/utils/url_helper.dart';

class Menu {
  final int id;
  final String titulo;
  final String descripcion;
  final String foto;
  final String precio;
  final int? categoriaId;
  String status;

  Menu({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.foto,
    required this.precio,
    this.categoriaId,
    required this.status,
  });

  factory Menu.fromJson(Map<String, dynamic> json) {
    return Menu(
      id: json['id'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      foto: UrlHelper.fixUrl(json['foto']),
      precio: json['precio'],
      categoriaId: json['categoria_id'] != null ? int.tryParse(json['categoria_id'].toString()) : null,
      status: json['status'],
    );
  }
}
