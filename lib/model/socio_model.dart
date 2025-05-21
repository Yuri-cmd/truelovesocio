class Socio {
  final int id;
  final String documentType;
  final String documentNumber;
  final String name;
  final String lastName;
  final String businessType;
  final String phone;
  final String email;
  final String verificationCode;
  final String? emailVerifiedAt;
  final int estado;
  final String? createdAt;
  final String? updatedAt;
  final int userId;
  final bool aprobado;
  int activo;

  Socio({
    required this.id,
    required this.documentType,
    required this.documentNumber,
    required this.name,
    required this.lastName,
    required this.businessType,
    required this.phone,
    required this.email,
    required this.verificationCode,
    this.emailVerifiedAt,
    required this.estado,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    required this.aprobado,
    required this.activo,
  });

  factory Socio.fromJson(Map<String, dynamic> json) {
    return Socio(
      id: json['id'],
      documentType:
          json['documentType'].toString(), // Convertir a String si es int
      documentNumber: json['documentNumber'].toString(),
      name: json['name'] ?? '',
      lastName: json['lastName'] ?? '',
      businessType: json['businessType'].toString(),
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      verificationCode: json['verification_code'] ?? '',
      emailVerifiedAt: json['email_verified_at'],
      estado: json['estado'] ?? 0,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      userId: json['user_id'] ?? 0,
      aprobado: json['aprobado'] ?? false,
      activo: json['activo'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'documentType': documentType,
      'documentNumber': documentNumber,
      'name': name,
      'lastName': lastName,
      'businessType': businessType,
      'phone': phone,
      'email': email,
      'verification_code': verificationCode,
      'email_verified_at': emailVerifiedAt,
      'estado': estado,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'user_id': userId,
      'activo': activo,
    };
  }
}
