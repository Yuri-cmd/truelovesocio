class CategorySchedule {
  final String day;
  final String? startTime;
  final String? endTime;
  final bool isActive;

  CategorySchedule({
    required this.day,
    this.startTime,
    this.endTime,
    this.isActive = true,
  });

  factory CategorySchedule.fromJson(Map<String, dynamic> json) {
    return CategorySchedule(
      day: json['dia'],
      startTime: json['hora_inicio'],
      endTime: json['hora_fin'],
      isActive: json['activo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dia': day,
      'hora_inicio': startTime,
      'hora_fin': endTime,
      'activo': isActive,
    };
  }
}

class Category {
  final int id;
  final String name;
  final int idEmpresa; // Campo id_empresa
  int estado; // 1 activo, 0 desactivado
  final List<CategorySchedule> horarios;

  Category({
    required this.id,
    required this.name,
    required this.idEmpresa,
    required this.estado,
    required this.horarios,
  });

  // Convertir JSON a modelo
  factory Category.fromJson(Map<String, dynamic> json) {
    var list = json['horarios'] as List? ?? [];
    List<CategorySchedule> schedulesList =
        list.map((i) => CategorySchedule.fromJson(i)).toList();

    return Category(
      id: json['id'],
      name: json['nombre'],
      idEmpresa: json['empresa_id'], // Leer el campo id_empresa
      estado: json['estado'] ?? 1,
      horarios: schedulesList,
    );
  }

  // Convertir modelo a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': name,
      'empresa_id': idEmpresa,
      'estado': estado,
      // 'hora_inicio' and 'hora_fin' are removed as they are now in 'horarios'
      'horarios': horarios.map((v) => v.toJson()).toList(),
    };
  }
}
