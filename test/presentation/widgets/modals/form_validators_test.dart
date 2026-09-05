import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/presentation/widgets/modals/add_patient_modal.dart';
import 'package:dentera/presentation/widgets/modals/add_requirement_modal.dart';
import 'package:dentera/presentation/widgets/modals/schedule_appointment_modal.dart';

void main() {
  group('Modal Form Synchronous Validators Unit Tests', () {
    group('AddPatientModal.validateAge', () {
      test('rejects empty or null age input', () {
        expect(AddPatientModal.validateAge(null), 'Enter age');
        expect(AddPatientModal.validateAge(''), 'Enter age');
        expect(AddPatientModal.validateAge('   '), 'Enter age');
      });

      test('rejects non-integer strings', () {
        expect(AddPatientModal.validateAge('abc'), 'Invalid');
        expect(AddPatientModal.validateAge('12.5'), 'Invalid');
        expect(AddPatientModal.validateAge('twenty'), 'Invalid');
      });

      test('rejects negative integers and logs warning', () {
        expect(AddPatientModal.validateAge('-1'), 'Cannot be negative');
        expect(AddPatientModal.validateAge('-45'), 'Cannot be negative');
      });

      test('rejects unrealistic human age (> 130)', () {
        expect(AddPatientModal.validateAge('131'), 'Invalid age');
        expect(AddPatientModal.validateAge('999'), 'Invalid age');
      });

      test('accepts valid patient ages', () {
        expect(AddPatientModal.validateAge('0'), isNull);
        expect(AddPatientModal.validateAge('1'), isNull);
        expect(AddPatientModal.validateAge('28'), isNull);
        expect(AddPatientModal.validateAge('85'), isNull);
        expect(AddPatientModal.validateAge('120'), isNull);
      });
    });

    group('AddRequirementModal.validateQuota', () {
      test('rejects empty or null quota input', () {
        expect(AddRequirementModal.validateQuota(null), 'Please enter target quota');
        expect(AddRequirementModal.validateQuota(''), 'Please enter target quota');
        expect(AddRequirementModal.validateQuota('   '), 'Please enter target quota');
      });

      test('rejects non-integer strings', () {
        expect(AddRequirementModal.validateQuota('five'), 'Quota must be a valid number');
        expect(AddRequirementModal.validateQuota('3.14'), 'Quota must be a valid number');
      });

      test('rejects negative numbers and logs warning', () {
        expect(AddRequirementModal.validateQuota('-1'), 'Quota cannot be negative');
        expect(AddRequirementModal.validateQuota('-10'), 'Quota cannot be negative');
      });

      test('rejects zero as requirement quota must be positive', () {
        expect(AddRequirementModal.validateQuota('0'), 'Quota must be greater than 0');
      });

      test('rejects quota exceeding realistic maximum cap (> 999)', () {
        expect(AddRequirementModal.validateQuota('1000'), 'Quota count cannot exceed 999');
        expect(AddRequirementModal.validateQuota('5000'), 'Quota count cannot exceed 999');
      });

      test('accepts valid quota target counts', () {
        expect(AddRequirementModal.validateQuota('1'), isNull);
        expect(AddRequirementModal.validateQuota('5'), isNull);
        expect(AddRequirementModal.validateQuota('20'), isNull);
        expect(AddRequirementModal.validateQuota('999'), isNull);
      });
    });

    group('ScheduleAppointmentModal.validateAppointmentDateTime', () {
      final referenceTime = DateTime(2026, 9, 5, 14, 0);

      test('rejects appointment dates in the past and logs warning', () {
        final pastDate = DateTime(2026, 9, 4, 14, 0);
        expect(
          ScheduleAppointmentModal.validateAppointmentDateTime(pastDate, referenceTime),
          'Cannot schedule appointments in the past',
        );
      });

      test('rejects appointment time earlier today and logs warning', () {
        final earlierToday = DateTime(2026, 9, 5, 13, 30);
        expect(
          ScheduleAppointmentModal.validateAppointmentDateTime(earlierToday, referenceTime),
          'Cannot schedule appointments in the past',
        );
      });

      test('accepts future appointment time on the same date', () {
        final laterToday = DateTime(2026, 9, 5, 15, 30);
        expect(
          ScheduleAppointmentModal.validateAppointmentDateTime(laterToday, referenceTime),
          isNull,
        );
      });

      test('accepts future appointment dates', () {
        final futureDate = DateTime(2026, 9, 6, 10, 0);
        expect(
          ScheduleAppointmentModal.validateAppointmentDateTime(futureDate, referenceTime),
          isNull,
        );
      });
    });
  });
}
