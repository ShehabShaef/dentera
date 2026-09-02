import 'package:flutter/foundation.dart';

/// Immutable domain model representing a dental clinic department (e.g. Prosthodontics, Endodontics).
@immutable
class Clinic {
  const Clinic({
    required this.id,
    required this.name,
    required this.academicYear,
    required this.colorHex,
  });

  final String id;
  final String name;
  final String academicYear;
  final String colorHex;

  Clinic copyWith({
    String? id,
    String? name,
    String? academicYear,
    String? colorHex,
  }) {
    return Clinic(
      id: id ?? this.id,
      name: name ?? this.name,
      academicYear: academicYear ?? this.academicYear,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'academicYear': academicYear,
      'colorHex': colorHex,
    };
  }

  factory Clinic.fromMap(Map<String, dynamic> map) {
    return Clinic(
      id: map['id'] as String,
      name: map['name'] as String,
      academicYear: map['academicYear'] as String,
      colorHex: map['colorHex'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Clinic &&
        other.id == id &&
        other.name == name &&
        other.academicYear == academicYear &&
        other.colorHex == colorHex;
  }

  @override
  int get hashCode => Object.hash(id, name, academicYear, colorHex);

  @override
  String toString() {
    return 'Clinic(id: $id, name: $name, academicYear: $academicYear, colorHex: $colorHex)';
  }
}
