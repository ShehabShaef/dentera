import 'package:flutter/foundation.dart';

/// Immutable domain model representing an academic clinical quota requirement.
@immutable
class Requirement {
  const Requirement({
    required this.id,
    required this.clinicId,
    required this.title,
    required this.targetCount,
    this.completedCount = 0,
  });

  final String id;
  final String clinicId;
  final String title;
  final int targetCount;
  final int completedCount;

  Requirement copyWith({
    String? id,
    String? clinicId,
    String? title,
    int? targetCount,
    int? completedCount,
  }) {
    return Requirement(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      title: title ?? this.title,
      targetCount: targetCount ?? this.targetCount,
      completedCount: completedCount ?? this.completedCount,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'clinicId': clinicId,
      'title': title,
      'targetCount': targetCount,
      'completedCount': completedCount,
    };
  }

  factory Requirement.fromMap(Map<String, dynamic> map) {
    return Requirement(
      id: map['id'] as String,
      clinicId: map['clinicId'] as String,
      title: map['title'] as String,
      targetCount: (map['targetCount'] as num).toInt(),
      completedCount: (map['completedCount'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Requirement &&
        other.id == id &&
        other.clinicId == clinicId &&
        other.title == title &&
        other.targetCount == targetCount &&
        other.completedCount == completedCount;
  }

  @override
  int get hashCode => Object.hash(
        id,
        clinicId,
        title,
        targetCount,
        completedCount,
      );

  @override
  String toString() {
    return 'Requirement(id: $id, clinicId: $clinicId, title: $title, targetCount: $targetCount, completedCount: $completedCount)';
  }
}
