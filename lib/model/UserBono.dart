 

import 'package:Frutia/model/Bonos.dart';

class UserBono {
  final int id;
  final int userId;
  final int bonoId;
  final DateTime fechaCompra;
  final DateTime fechaVencimiento;
  final String codigoReferencia;
  final String? paymentId;
  final String estado;
  final int? usosDisponibles;
  final int? usosTotales;
  final Map<String, dynamic>? restriccionesHorarias;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Bono? bono;

  UserBono({
    required this.id,
    required this.userId,
    required this.bonoId,
    required this.fechaCompra,
    required this.fechaVencimiento,
    required this.codigoReferencia,
    required this.estado,
    this.paymentId,
    this.usosDisponibles,
    this.usosTotales,
    this.restriccionesHorarias,
    this.createdAt,
    this.updatedAt,
    this.bono,
  });

  factory UserBono.fromJson(Map<String, dynamic> json) {
    return UserBono(
      id: json['id'],
      userId: json['user_id'],
      bonoId: json['bono_id'],
      fechaCompra: DateTime.parse(json['fecha_compra']),
      fechaVencimiento: DateTime.parse(json['fecha_vencimiento']),
      codigoReferencia: json['codigo_referencia'],
      estado: json['estado'],
      paymentId: json['payment_id'],
      usosDisponibles: json['usos_disponibles'],
      usosTotales: json['usos_totales'],
      restriccionesHorarias: json['restricciones_horarias'] != null 
          ? Map<String, dynamic>.from(json['restricciones_horarias']) 
          : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      bono: json['bono'] != null ? Bono.fromJson(json['bono']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'bono_id': bonoId,
      'fecha_compra': fechaCompra.toIso8601String(),
      'fecha_vencimiento': fechaVencimiento.toIso8601String(),
      'codigo_referencia': codigoReferencia,
      'payment_id': paymentId,
      'estado': estado,
      'usos_disponibles': usosDisponibles,
      'usos_totales': usosTotales,
      'restricciones_horarias': restriccionesHorarias,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'bono': bono?.toJson(),
    };
  }

  // Calcular días restantes
  int get diasRestantes {
    final now = DateTime.now();
    return fechaVencimiento.difference(now).inDays;
  }

  // Calcular porcentaje de tiempo restante
  double get porcentajeTiempoRestante {
    final now = DateTime.now();
    final totalDias = fechaVencimiento.difference(fechaCompra).inDays;
    final diasTranscurridos = now.difference(fechaCompra).inDays;
    final diasRestantesCalc = totalDias - diasTranscurridos;
    
    if (totalDias <= 0) return 0;
    return diasRestantesCalc / totalDias;
  }

  // Verificar si el bono está activo
  bool get estaActivo {
    final now = DateTime.now();
    return estado == 'activo' && fechaVencimiento.isAfter(now);
  }
}