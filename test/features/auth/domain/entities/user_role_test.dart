// test/features/auth/domain/entities/user_role_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';

void main() {
  group('UserRole enum tests', () {
    test('All 6 roles have valid labels and apiValues', () {
      expect(UserRole.values.length, 6);

      expect(UserRole.admin.label, 'Admin');
      expect(UserRole.pemohon.label, 'Pemohon');
      expect(UserRole.operator.label, 'Operator');
      expect(UserRole.kabagAset.label, 'Kabag Aset');
      expect(UserRole.kadiv.label, 'Kadiv');
      expect(UserRole.staffAset.label, 'Staff Aset');
    });

    test('fromApiValue parses strings correctly', () {
      expect(UserRole.fromApiValue('ADMIN'), UserRole.admin);
      expect(UserRole.fromApiValue('pemohon'), UserRole.pemohon);
      expect(UserRole.fromApiValue('operator'), UserRole.operator);
      expect(UserRole.fromApiValue('kabag_aset'), UserRole.kabagAset);
      expect(UserRole.fromApiValue('kadiv'), UserRole.kadiv);
      expect(UserRole.fromApiValue('staff_aset'), UserRole.staffAset);
    });

    test('fromApiValue returns null for unknown string', () {
      expect(UserRole.fromApiValue('unknown_role'), isNull);
      expect(UserRole.fromApiValue(null), isNull);
    });
  });
}
