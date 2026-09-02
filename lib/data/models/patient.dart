import 'package:flutter/foundation.dart';

/// Immutable domain model representing a clinical patient.
@immutable
class Patient {
  const Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    this.phoneNumber,
    this.medicalHistory,
    required this.createdAt,
  });

  final String id;
  final String name;
  final int age;
  final String gender;
  final String? phoneNumber;
  final String? medicalHistory;
  final DateTime createdAt;

  Patient copyWith({
    String? id,
    String? name,
    int? age,
    String? gender,
    String? phoneNumber,
    String? medicalHistory,
    DateTime? createdAt,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'phoneNumber': phoneNumber,
      'medicalHistory': medicalHistory,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'] as String,
      name: map['name'] as String,
      age: (map['age'] as num).toInt(),
      gender: map['gender'] as String,
      phoneNumber: map['phoneNumber'] as String?,
      medicalHistory: map['medicalHistory'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Patient &&
        other.id == id &&
        other.name == name &&
        other.age == age &&
        other.gender == gender &&
        other.phoneNumber == phoneNumber &&
        other.medicalHistory == medicalHistory &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        age,
        gender,
        phoneNumber,
        medicalHistory,
        createdAt,
      );

  @override
  String toString() {
    return 'Patient(id: $id, name: $name, age: $age, gender: $gender, phoneNumber: $phoneNumber, medicalHistory: $medicalHistory, createdAt: $createdAt)';
  }
}
