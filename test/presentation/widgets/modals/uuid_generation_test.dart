import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('Collision-Free UUID v4 Generation Tests', () {
    const uuid = Uuid();
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );

    test('generates valid, non-null, 36-character canonical UUID v4 string', () {
      final id = uuid.v4();

      expect(id, isNotNull);
      expect(id.length, 36);
      expect(uuidRegex.hasMatch(id), isTrue);
    });

    test('generates collision-free IDs across 10,000 consecutive iterations', () {
      final generatedIds = <String>{};
      const iterations = 10000;

      for (int i = 0; i < iterations; i++) {
        final id = uuid.v4();
        expect(id.length, 36);
        expect(uuidRegex.hasMatch(id), isTrue);
        generatedIds.add(id);
      }

      // Assert zero collisions occurred
      expect(generatedIds.length, iterations);
    });
  });
}
