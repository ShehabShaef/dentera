import 'package:flutter/foundation.dart';

/// Immutable domain model representing a scheduled clinical appointment.
@immutable
class Appointment {
  const Appointment({
    required this.id,
    required this.patientId,
    required this.clinicId,
    required this.scheduledDate,
    this.status = 'Scheduled',
    this.procedureDescription,
  });

  final String id;
  final String patientId;
  final String clinicId;
  final DateTime scheduledDate;
  final String status;
  final String? procedureDescription;

  Appointment copyWith({
    String? id,
    String? patientId,
    String? clinicId,
    DateTime? scheduledDate,
    String? status,
    String? procedureDescription,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      clinicId: clinicId ?? this.clinicId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      status: status ?? this.status,
      procedureDescription: procedureDescription ?? this.procedureDescription,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'patientId': patientId,
      'clinicId': clinicId,
      'scheduledDate': scheduledDate.toIso8601String(),
      'status': status,
      'procedureDescription': procedureDescription,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'] as String,
      patientId: map['patientId'] as String,
      clinicId: map['clinicId'] as String,
      scheduledDate: DateTime.parse(map['scheduledDate'] as String),
      status: map['status'] as String? ?? 'Scheduled',
      procedureDescription: map['procedureDescription'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Appointment &&
        other.id == id &&
        other.patientId == patientId &&
        other.clinicId == clinicId &&
        other.scheduledDate == scheduledDate &&
        other.status == status &&
        other.procedureDescription == procedureDescription;
  }

  @override
  int get hashCode => Object.hash(
        id,
        patientId,
        clinicId,
        scheduledDate,
        status,
        procedureDescription,
      );

  @override
  String toString() {
    return 'Appointment(id: $id, patientId: $patientId, clinicId: $clinicId, scheduledDate: $scheduledDate, status: $status, procedureDescription: $procedureDescription)';
  }
}
