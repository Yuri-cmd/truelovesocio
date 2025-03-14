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
  final String createdAt;
  final String updatedAt;
  final int userId;
  final bool aprobado;

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
  });

  factory Socio.fromJson(Map<String, dynamic> json) {
    return Socio(
      id: json['socio']['id'],
      documentType: json['socio']['documentType'],
      documentNumber: json['socio']['documentNumber'],
      name: json['socio']['name'],
      lastName: json['socio']['lastName'],
      businessType: json['socio']['businessType'],
      phone: json['socio']['phone'],
      email: json['socio']['email'],
      verificationCode: json['socio']['verification_code'],
      emailVerifiedAt: json['socio']['email_verified_at'],
      estado: json['socio']['estado'],
      createdAt: json['socio']['created_at'],
      updatedAt: json['socio']['updated_at'],
      userId: json['socio']['user_id'],
      aprobado: json['socio']['aprobado'],
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
      'aprobado': aprobado,
    };
  }
}
