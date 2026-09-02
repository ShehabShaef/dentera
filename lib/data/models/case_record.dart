import 'package:flutter/foundation.dart';

/// Immutable domain model representing a clinical procedure case record.
@immutable
class CaseRecord {
  const CaseRecord({
    required this.id,
    required this.patientId,
    required this.requirementId,
    this.status = 'In Progress',
    this.notes,
    required this.dateStarted,
    this.dateCompleted,
  });

  final String id;
  final String patientId;
  final String requirementId;
  final String status;
  final String? notes;
  final DateTime dateStarted;
  final DateTime? dateCompleted;

  CaseRecord copyWith({
    String? id,
    String? patientId,
    String? requirementId,
    String? status,
    String? notes,
    DateTime? dateStarted,
    DateTime? dateCompleted,
  }) {
    return CaseRecord(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      requirementId: requirementId ?? this.requirementId,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      dateStarted: dateStarted ?? this.dateStarted,
      dateCompleted: dateCompleted ?? this.dateCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'patientId': patientId,
      'requirementId': requirementId,
      'status': status,
      'notes': notes,
      'dateStarted': dateStarted.toIso8601String(),
      'dateCompleted': dateCompleted?.toIso8601String(),
    };
  }

  factory CaseRecord.fromMap(Map<String, dynamic> map) {
    return CaseRecord(
      id: map['id'] as String,
      patientId: map['patientId'] as String,
      requirementId: map['requirementId'] as String,
      status: map['status'] as String? ?? 'In Progress',
      notes: map['notes'] as String?,
      dateStarted: DateTime.parse(map['dateStarted'] as String),
      dateCompleted: map['dateCompleted'] != null
          ? DateTime.parse(map['dateCompleted'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CaseRecord &&
        other.id == id &&
        other.patientId == patientId &&
        other.requirementId == requirementId &&
        other.status == status &&
        other.notes == notes &&
        other.dateStarted == dateStarted &&
        other.dateCompleted == dateCompleted;
  }

  @override
  int get hashCode => Object.hash(
        id,
        patientId,
        requirementId,
        status,
        notes,
        dateStarted,
        dateCompleted,
      );

  @override
  String toString() {
    return 'CaseRecord(id: $id, patientId: $patientId, requirementId: $requirementId, status: $status, notes: $notes, dateStarted: $dateStarted, dateCompleted: $dateCompleted)';
  }
}
