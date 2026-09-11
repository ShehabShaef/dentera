import 'package:flutter/foundation.dart';

/// Academic dental care phases for organizing patient treatment staging.
enum TreatmentPhase {
  emergency(
    1,
    'Phase 1: Emergency',
    'Urgent relief of acute pain, infection, or trauma',
  ),
  preventivePerio(
    2,
    'Phase 2: Preventive / Perio',
    'Oral hygiene, scaling, prophylaxis, periodontal therapy',
  ),
  restorative(
    3,
    'Phase 3: Restorative',
    'Endodontics, operative fillings, prosthodontic rehabilitation',
  ),
  maintenance(
    4,
    'Phase 4: Maintenance',
    'Periodic recall, evaluation, and preventive follow-ups',
  );

  const TreatmentPhase(this.value, this.label, this.description);

  final int value;
  final String label;
  final String description;

  /// Resolves a [TreatmentPhase] from an integer phase value.
  static TreatmentPhase fromValue(int val) {
    return TreatmentPhase.values.firstWhere(
      (e) => e.value == val,
      orElse: () => TreatmentPhase.emergency,
    );
  }
}

/// Immutable domain entity representing a planned, staged clinical treatment procedure.
@immutable
class TreatmentPlan {
  const TreatmentPlan({
    required this.id,
    required this.patientId,
    required this.phase,
    required this.title,
    this.status = statusProposed,
    this.targetClinicId,
    this.notes,
    required this.createdAt,
  });

  static const String statusProposed = 'Proposed';
  static const String statusApproved = 'Approved';
  static const String statusConverted = 'Converted';
  static const String statusCompleted = 'Completed';

  final String id;
  final String patientId;
  final int phase;
  final String title;
  final String status;
  final String? targetClinicId;
  final String? notes;
  final DateTime createdAt;

  /// Convenience getter resolving the strongly-typed [TreatmentPhase].
  TreatmentPhase get treatmentPhase => TreatmentPhase.fromValue(phase);

  TreatmentPlan copyWith({
    String? id,
    String? patientId,
    int? phase,
    String? title,
    String? status,
    String? targetClinicId,
    String? notes,
    DateTime? createdAt,
  }) {
    return TreatmentPlan(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      phase: phase ?? this.phase,
      title: title ?? this.title,
      status: status ?? this.status,
      targetClinicId: targetClinicId ?? this.targetClinicId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'patientId': patientId,
      'phase': phase,
      'title': title,
      'status': status,
      'targetClinicId': targetClinicId,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TreatmentPlan.fromMap(Map<String, dynamic> map) {
    return TreatmentPlan(
      id: map['id'] as String,
      patientId: map['patientId'] as String,
      phase: map['phase'] as int,
      title: map['title'] as String,
      status: map['status'] as String? ?? statusProposed,
      targetClinicId: map['targetClinicId'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TreatmentPlan &&
        other.id == id &&
        other.patientId == patientId &&
        other.phase == phase &&
        other.title == title &&
        other.status == status &&
        other.targetClinicId == targetClinicId &&
        other.notes == notes &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        patientId,
        phase,
        title,
        status,
        targetClinicId,
        notes,
        createdAt,
      );

  @override
  String toString() {
    return 'TreatmentPlan(id: $id, patientId: $patientId, phase: $phase, title: $title, status: $status, targetClinicId: $targetClinicId, notes: $notes, createdAt: $createdAt)';
  }
}
