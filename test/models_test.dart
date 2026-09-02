import 'package:flutter_test/flutter_test.dart';
import 'package:dentera/data/models/models.dart';

void main() {
  group('Patient model', () {
    test('toMap and fromMap work correctly with null and non-null fields', () {
      final now = DateTime.parse('2026-09-01T12:00:00.000Z');
      final patient = Patient(
        id: 'patient-1',
        name: 'Sarah Connor',
        age: 28,
        gender: 'Female',
        phoneNumber: '+1234567890',
        medicalHistory: 'Penicillin allergy',
        createdAt: now,
      );

      final map = patient.toMap();
      expect(map['id'], 'patient-1');
      expect(map['name'], 'Sarah Connor');
      expect(map['age'], 28);
      expect(map['gender'], 'Female');
      expect(map['phoneNumber'], '+1234567890');
      expect(map['medicalHistory'], 'Penicillin allergy');
      expect(map['createdAt'], now.toIso8601String());

      final parsed = Patient.fromMap(map);
      expect(parsed, equals(patient));

      final updated = patient.copyWith(name: 'Sarah J. Connor', age: 29);
      expect(updated.name, 'Sarah J. Connor');
      expect(updated.age, 29);
      expect(updated.id, patient.id);
    });
  });

  group('Clinic model', () {
    test('toMap and fromMap work correctly', () {
      const clinic = Clinic(
        id: 'clinic-1',
        name: 'Prosthodontics',
        academicYear: 'Year 4',
        colorHex: '#003E6F',
      );

      final map = clinic.toMap();
      expect(map['id'], 'clinic-1');
      expect(map['name'], 'Prosthodontics');
      expect(map['academicYear'], 'Year 4');
      expect(map['colorHex'], '#003E6F');

      final parsed = Clinic.fromMap(map);
      expect(parsed, equals(clinic));

      final updated = clinic.copyWith(academicYear: 'Year 5');
      expect(updated.academicYear, 'Year 5');
    });
  });

  group('Requirement model', () {
    test('toMap and fromMap work correctly', () {
      const requirement = Requirement(
        id: 'req-1',
        clinicId: 'clinic-1',
        title: 'Complete Denture',
        targetCount: 5,
        completedCount: 2,
      );

      final map = requirement.toMap();
      expect(map['id'], 'req-1');
      expect(map['clinicId'], 'clinic-1');
      expect(map['title'], 'Complete Denture');
      expect(map['targetCount'], 5);
      expect(map['completedCount'], 2);

      final parsed = Requirement.fromMap(map);
      expect(parsed, equals(requirement));

      final updated = requirement.copyWith(completedCount: 3);
      expect(updated.completedCount, 3);
    });
  });

  group('CaseRecord model', () {
    test('toMap and fromMap work correctly', () {
      final started = DateTime.parse('2026-08-15T09:00:00.000Z');
      final completed = DateTime.parse('2026-08-20T11:00:00.000Z');
      final record = CaseRecord(
        id: 'case-1',
        patientId: 'patient-1',
        requirementId: 'req-1',
        status: 'Completed',
        notes: 'Upper and lower impression taken.',
        dateStarted: started,
        dateCompleted: completed,
      );

      final map = record.toMap();
      expect(map['id'], 'case-1');
      expect(map['patientId'], 'patient-1');
      expect(map['requirementId'], 'req-1');
      expect(map['status'], 'Completed');
      expect(map['notes'], 'Upper and lower impression taken.');
      expect(map['dateStarted'], started.toIso8601String());
      expect(map['dateCompleted'], completed.toIso8601String());

      final parsed = CaseRecord.fromMap(map);
      expect(parsed, equals(record));

      final updated = record.copyWith(status: 'Evaluated');
      expect(updated.status, 'Evaluated');
    });
  });

  group('Appointment model', () {
    test('toMap and fromMap work correctly', () {
      final scheduled = DateTime.parse('2026-09-10T14:30:00.000Z');
      final appointment = Appointment(
        id: 'apt-1',
        patientId: 'patient-1',
        clinicId: 'clinic-1',
        scheduledDate: scheduled,
        status: 'Scheduled',
        procedureDescription: 'Crown preparation',
      );

      final map = appointment.toMap();
      expect(map['id'], 'apt-1');
      expect(map['patientId'], 'patient-1');
      expect(map['clinicId'], 'clinic-1');
      expect(map['scheduledDate'], scheduled.toIso8601String());
      expect(map['status'], 'Scheduled');
      expect(map['procedureDescription'], 'Crown preparation');

      final parsed = Appointment.fromMap(map);
      expect(parsed, equals(appointment));

      final updated = appointment.copyWith(status: 'Completed');
      expect(updated.status, 'Completed');
    });
  });
}
