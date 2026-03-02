class CuotaActiva {
  final int id;
  final String periodicidad;
  final String tipoCuota;
  final String montoCuota;
  final String? porcentajeComision;
  final int? minimoPedidos;
  final bool exonerarSiMenosPedidos;
  final String? montoMinimo;
  final String? montoMaximo;
  final String? montoUsoApp;
  final String? numeroCuenta;
  final String? tipoCuenta;
  final String? banco;
  final List<String> metodosPagoDisponibles;
  final String? numeroYape;
  final String? titularYape;
  final String estado;
  final String? descripcion;
  final String? createdAt;
  final String? updatedAt;
  final int diaPago;
  final String? diaPagoNota;

  CuotaActiva({
    required this.id,
    required this.periodicidad,
    required this.tipoCuota,
    required this.montoCuota,
    this.porcentajeComision,
    this.minimoPedidos,
    required this.exonerarSiMenosPedidos,
    this.montoMinimo,
    this.montoMaximo,
    this.montoUsoApp,
    this.numeroCuenta,
    this.tipoCuenta,
    this.banco,
    required this.metodosPagoDisponibles,
    this.numeroYape,
    this.titularYape,
    required this.estado,
    this.descripcion,
    this.createdAt,
    this.updatedAt,
    required this.diaPago,
    this.diaPagoNota,
  });

  factory CuotaActiva.fromJson(Map<String, dynamic> json) {
    return CuotaActiva(
      id: json['id'],
      periodicidad: json['periodicidad']?.toString() ?? '',
      tipoCuota: json['tipo_cuota']?.toString() ?? '',
      montoCuota: json['monto_cuota']?.toString() ?? '0.00',
      porcentajeComision: json['porcentaje_comision']?.toString(),
      minimoPedidos: json['minimo_pedidos'],
      exonerarSiMenosPedidos: json['exonerar_si_menos_pedidos'] == 1 || json['exonerar_si_menos_pedidos'] == true,
      montoMinimo: json['monto_minimo']?.toString(),
      montoMaximo: json['monto_maximo']?.toString(),
      montoUsoApp: json['monto_uso_app']?.toString(),
      numeroCuenta: json['numero_cuenta']?.toString(),
      tipoCuenta: json['tipo_cuenta']?.toString(),
      banco: json['banco']?.toString(),
      metodosPagoDisponibles: (json['metodos_pago_disponibles'] as List?)?.map((e) => e.toString()).toList() ?? [],
      numeroYape: json['numero_yape']?.toString(),
      titularYape: json['titular_yape']?.toString(),
      estado: json['estado']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      diaPago: int.tryParse(json['dia_pago']?.toString() ?? '0') ?? 0,
      diaPagoNota: json['dia_pago_nota']?.toString(),
    );
  }
}

class PeriodoCuota {
  final int id;
  final int cuotaSocioId;
  final int socioId;
  final DateTime periodoInicio;
  final DateTime periodoFin;
  final String montoEsperado;
  final String totalVentas;
  final int cantidadPedidos;
  final String montoCalculado;
  final DateTime? fechaCalculo;
  final String estado;
  final int? pagoId;
  final DateTime fechaVencimiento;
  final bool notificadoVencimiento;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? diasParaVencer;
  final bool estaVencido;
  final int? numeroPeriodo;
  final PagoCuota? pago;

  PeriodoCuota({
    required this.id,
    required this.cuotaSocioId,
    required this.socioId,
    required this.periodoInicio,
    required this.periodoFin,
    required this.montoEsperado,
    required this.totalVentas,
    required this.cantidadPedidos,
    required this.montoCalculado,
    this.fechaCalculo,
    required this.estado,
    this.pagoId,
    required this.fechaVencimiento,
    required this.notificadoVencimiento,
    this.createdAt,
    this.updatedAt,
    this.diasParaVencer,
    required this.estaVencido,
    this.numeroPeriodo,
    this.pago,
  });

  factory PeriodoCuota.fromJson(Map<String, dynamic> json) {
    return PeriodoCuota(
      id: json['id'],
      cuotaSocioId: json['cuota_socio_id'],
      socioId: json['socio_id'],
      periodoInicio: DateTime.parse(json['periodo_inicio']),
      periodoFin: DateTime.parse(json['periodo_fin']),
      montoEsperado: json['monto_esperado']?.toString() ?? '0.00',
      totalVentas: json['total_ventas']?.toString() ?? '0.00',
      cantidadPedidos: int.tryParse(json['cantidad_pedidos']?.toString() ?? '0') ?? 0,
      montoCalculado: json['monto_calculado']?.toString() ?? '0.00',
      fechaCalculo: json['fecha_calculo'] != null ? DateTime.parse(json['fecha_calculo']) : null,
      estado: json['estado']?.toString() ?? '',
      pagoId: json['pago_id'],
      fechaVencimiento: DateTime.parse(json['fecha_vencimiento']),
      notificadoVencimiento: json['notificado_vencimiento'] == 1 || json['notificado_vencimiento'] == true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      diasParaVencer: int.tryParse(json['dias_para_vencer']?.toString() ?? '0'),
      estaVencido: json['esta_vencido'] == 1 || json['esta_vencido'] == true,
      numeroPeriodo: int.tryParse(json['numero_periodo']?.toString() ?? '0'),
      pago: json['pago'] != null ? PagoCuota.fromJson(json['pago']) : null,
    );
  }
}

class PagoCuota {
  final int id;
  final int cuotaSocioId;
  final int socioId;
  final String comprobantePago;
  final String estadoPago;
  final DateTime fechaPago;
  final String montoPagado;
  final String metodoPago;
  final String? numeroOperacion;
  final String? observaciones;
  final DateTime? fechaAprobacion;
  final String? aprobadoPor;
  final String? motivoRechazo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PagoCuota({
    required this.id,
    required this.cuotaSocioId,
    required this.socioId,
    required this.comprobantePago,
    required this.estadoPago,
    required this.fechaPago,
    required this.montoPagado,
    required this.metodoPago,
    this.numeroOperacion,
    this.observaciones,
    this.fechaAprobacion,
    this.aprobadoPor,
    this.motivoRechazo,
    this.createdAt,
    this.updatedAt,
  });

  factory PagoCuota.fromJson(Map<String, dynamic> json) {
    return PagoCuota(
      id: json['id'],
      cuotaSocioId: json['cuota_socio_id'],
      socioId: json['socio_id'],
      comprobantePago: json['comprobante_pago']?.toString() ?? '',
      estadoPago: json['estado_pago']?.toString() ?? '',
      fechaPago: DateTime.parse(json['fecha_pago']),
      montoPagado: json['monto_pagado']?.toString() ?? '0.00',
      metodoPago: json['metodo_pago']?.toString() ?? '',
      numeroOperacion: json['numero_operacion']?.toString(),
      observaciones: json['observaciones']?.toString(),
      fechaAprobacion: json['fecha_aprobacion'] != null ? DateTime.parse(json['fecha_aprobacion']) : null,
      aprobadoPor: json['aprobado_por']?.toString(),
      motivoRechazo: json['motivo_rechazo']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }
}

class PedidoPeriodo {
  final int id;
  final String? codigo;
  final String cliente;
  final String fecha;
  final double subtotal;
  final double descuento;
  final double comision;
  final double neto;
  final int numProductos;

  PedidoPeriodo({
    required this.id,
    this.codigo,
    required this.cliente,
    required this.fecha,
    required this.subtotal,
    required this.descuento,
    required this.comision,
    required this.neto,
    required this.numProductos,
  });

  factory PedidoPeriodo.fromJson(Map<String, dynamic> json) {
    return PedidoPeriodo(
      id: json['id'],
      codigo: json['codigo']?.toString(),
      cliente: json['cliente']?.toString() ?? '',
      fecha: json['fecha']?.toString() ?? '',
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      descuento: double.tryParse(json['descuento']?.toString() ?? '0') ?? 0.0,
      comision: double.tryParse(json['comision']?.toString() ?? '0') ?? 0.0,
      neto: double.tryParse(json['neto']?.toString() ?? '0') ?? 0.0,
      numProductos: int.tryParse(json['num_productos']?.toString() ?? '0') ?? 0,
    );
  }
}
