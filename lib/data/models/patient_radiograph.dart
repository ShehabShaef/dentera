import 'package:flutter/foundation.dart';

/// Clinical radiograph projection types categorized for dental case sheet documentation.
enum RadiographType {
  periapical('Periapical', 'Intraoral periapical view focused on tooth apex and supporting bone'),
  bitewing('Bitewing', 'Intraoral bitewing image for interproximal caries and alveolar crest detection'),
  panoramic('Panoramic', 'Extraoral panoramic tomograph (OPG) covering maxilla, mandible, and TMJ'),
  other('Other', 'Occlusal, lateral cephalometric, or cone-beam computed tomography');

  const RadiographType(this.label, this.description);

  final String label;
  final String description;

  /// Resolves a [RadiographType] from string representation.
  static RadiographType fromString(String val) {
    return RadiographType.values.firstWhere(
      (e) => e.label.toLowerCase() == val.toLowerCase() || e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => RadiographType.periapical,
    );
  }
}

/// Immutable domain entity representing an attached dental radiograph (X-ray).
@immutable
class PatientRadiograph {
  const PatientRadiograph({
    required this.id,
    required this.patientId,
    required this.filePath,
    required this.type,
    this.notes,
    required this.captureDate,
    required this.createdAt,
  });

  static const String typePeriapical = 'Periapical';
  static const String typeBitewing = 'Bitewing';
  static const String typePanoramic = 'Panoramic';
  static const String typeOther = 'Other';

  final String id;
  final String patientId;
  final String filePath;
  final String type;
  final String? notes;
  final DateTime captureDate;
  final DateTime createdAt;

  RadiographType get radiographType => RadiographType.fromString(type);

  PatientRadiograph copyWith({
    String? id,
    String? patientId,
    String? filePath,
    String? type,
    String? notes,
    DateTime? captureDate,
    DateTime? createdAt,
  }) {
    return PatientRadiograph(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      filePath: filePath ?? this.filePath,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      captureDate: captureDate ?? this.captureDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'patientId': patientId,
      'filePath': filePath,
      'type': type,
      'notes': notes,
      'captureDate': captureDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PatientRadiograph.fromMap(Map<String, dynamic> map) {
    return PatientRadiograph(
      id: map['id'] as String,
      patientId: map['patientId'] as String,
      filePath: map['filePath'] as String,
      type: map['type'] as String,
      notes: map['notes'] as String?,
      captureDate: DateTime.parse(map['captureDate'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatientRadiograph &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          patientId == other.patientId &&
          filePath == other.filePath &&
          type == other.type &&
          notes == other.notes &&
          captureDate == other.captureDate &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      patientId.hashCode ^
      filePath.hashCode ^
      type.hashCode ^
      notes.hashCode ^
      captureDate.hashCode ^
      createdAt.hashCode;
}
