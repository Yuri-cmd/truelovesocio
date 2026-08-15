class Adicional {
  final int id;
  final int? menuId;
  final int empresaId;
  final String titulo;
  final String descripcion;
  final String? foto;
  final String precio;
  String status;
  DateTime? agotadoHasta;

  Adicional({
    required this.id,
    this.menuId,
    required this.empresaId,
    required this.titulo,
    required this.descripcion,
    this.foto,
    required this.precio,
    required this.status,
    this.agotadoHasta,
  });

  bool get isAgotado => status == 'out-of-stock';

  factory Adicional.fromJson(Map<String, dynamic> json) {
    return Adicional(
      id: json['id'],
      menuId: json['menu_id'] != null ? int.tryParse(json['menu_id'].toString()) : null,
      empresaId: int.tryParse(json['empresa_id']?.toString() ?? '') ?? 0,
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      foto: json['foto'],
      precio: json['precio']?.toString() ?? '0',
      status: json['status'] ?? 'active',
      agotadoHasta: json['agotado_hasta'] != null ? DateTime.tryParse(json['agotado_hasta']) : null,
    );
  }
}

/// Un adicional dentro de un grupo, incluye el precio propio del grupo (pivot)
class GrupoAdicionalItem {
  final int id;
  final String titulo;
  final String descripcion;
  final String precio;
  String status;
  final int? menuId;
  final double precioGrupo;

  GrupoAdicionalItem({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.precio,
    required this.status,
    this.menuId,
    required this.precioGrupo,
  });

  factory GrupoAdicionalItem.fromJson(Map<String, dynamic> json) {
    final pivot = json['pivot'] as Map<String, dynamic>?;
    final precioGrupoRaw = pivot?['precio'] ?? json['precio'];
    return GrupoAdicionalItem(
      id: json['id'],
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      precio: json['precio']?.toString() ?? '0',
      status: json['status'] ?? 'active',
      menuId: json['menu_id'] != null ? int.tryParse(json['menu_id'].toString()) : null,
      precioGrupo: double.tryParse(precioGrupoRaw?.toString() ?? '0') ?? 0,
    );
  }
}

class GrupoAdicional {
  final int id;
  final int empresaId;
  final String nombre;
  final int minimo;
  final int maximo;
  final String estado;
  final int orden;
  final List<GrupoAdicionalItem> items;

  GrupoAdicional({
    required this.id,
    required this.empresaId,
    required this.nombre,
    required this.minimo,
    required this.maximo,
    required this.estado,
    required this.orden,
    required this.items,
  });

  factory GrupoAdicional.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return GrupoAdicional(
      id: json['id'],
      empresaId: int.tryParse(json['empresa_id']?.toString() ?? '') ?? 0,
      nombre: json['nombre'] ?? '',
      minimo: int.tryParse(json['minimo']?.toString() ?? '0') ?? 0,
      maximo: int.tryParse(json['maximo']?.toString() ?? '1') ?? 1,
      estado: json['estado'] ?? 'active',
      orden: int.tryParse(json['orden']?.toString() ?? '0') ?? 0,
      items: itemsJson.map((e) => GrupoAdicionalItem.fromJson(e)).toList(),
    );
  }
}

/// Duraciones disponibles para marcar un producto/opción como agotado temporalmente
class DuracionAgotado {
  final String key;
  final String label;

  const DuracionAgotado(this.key, this.label);

  static const List<DuracionAgotado> opciones = [
    DuracionAgotado('medianoche', 'La medianoche'),
    DuracionAgotado('1_dia', '1 día'),
    DuracionAgotado('2_dias', '2 días'),
    DuracionAgotado('3_dias', '3 días'),
    DuracionAgotado('1_semana', '1 semana'),
  ];
}
