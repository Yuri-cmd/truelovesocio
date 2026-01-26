class Category {
  final int id;
  final String name;
  final int idEmpresa; // Campo id_empresa
  int estado; // 1 activo, 0 desactivado

  Category({required this.id, required this.name, required this.idEmpresa, required this.estado});

  // Convertir JSON a modelo
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['nombre'],
      idEmpresa: json['empresa_id'], // Leer el campo id_empresa
      estado: json['estado'] ?? 1,
    );
  }

  // Convertir modelo a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': name,
      'empresa_id': idEmpresa,
      'estado': estado,
    };
  }
}
