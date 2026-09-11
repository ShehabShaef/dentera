import 'package:flutter/foundation.dart';

/// Immutable domain model representing an individual milestone visit within a multi-visit [CaseRecord].
@immutable
class CaseVisit {
  const CaseVisit({
    required this.id,
    required this.caseRecordId,
    required this.visitNumber,
    required this.title,
    this.status = 'Pending',
    this.notes,
    this.dateScheduled,
    this.dateCompleted,
  });

  final String id;
  final String caseRecordId;
  final int visitNumber;
  final String title;
  final String status;
  final String? notes;
  final DateTime? dateScheduled;
  final DateTime? dateCompleted;

  CaseVisit copyWith({
    String? id,
    String? caseRecordId,
    int? visitNumber,
    String? title,
    String? status,
    String? notes,
    DateTime? dateScheduled,
    DateTime? dateCompleted,
  }) {
    return CaseVisit(
      id: id ?? this.id,
      caseRecordId: caseRecordId ?? this.caseRecordId,
      visitNumber: visitNumber ?? this.visitNumber,
      title: title ?? this.title,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      dateScheduled: dateScheduled ?? this.dateScheduled,
      dateCompleted: dateCompleted ?? this.dateCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'caseRecordId': caseRecordId,
      'visitNumber': visitNumber,
      'title': title,
      'status': status,
      'notes': notes,
      'dateScheduled': dateScheduled?.toIso8601String(),
      'dateCompleted': dateCompleted?.toIso8601String(),
    };
  }

  factory CaseVisit.fromMap(Map<String, dynamic> map) {
    return CaseVisit(
      id: map['id'] as String,
      caseRecordId: map['caseRecordId'] as String,
      visitNumber: (map['visitNumber'] as num).toInt(),
      title: map['title'] as String,
      status: map['status'] as String? ?? 'Pending',
      notes: map['notes'] as String?,
      dateScheduled: map['dateScheduled'] != null
          ? DateTime.parse(map['dateScheduled'] as String)
          : null,
      dateCompleted: map['dateCompleted'] != null
          ? DateTime.parse(map['dateCompleted'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CaseVisit &&
        other.id == id &&
        other.caseRecordId == caseRecordId &&
        other.visitNumber == visitNumber &&
        other.title == title &&
        other.status == status &&
        other.notes == notes &&
        other.dateScheduled == dateScheduled &&
        other.dateCompleted == dateCompleted;
  }

  @override
  int get hashCode => Object.hash(
        id,
        caseRecordId,
        visitNumber,
        title,
        status,
        notes,
        dateScheduled,
        dateCompleted,
      );

  @override
  String toString() {
    return 'CaseVisit(id: $id, caseRecordId: $caseRecordId, visitNumber: $visitNumber, title: $title, status: $status, notes: $notes, dateScheduled: $dateScheduled, dateCompleted: $dateCompleted)';
  }
}
