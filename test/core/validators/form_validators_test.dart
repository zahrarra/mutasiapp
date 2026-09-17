// test/core/validators/form_validators_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/core/validators/form_validators.dart';

void main() {
  group('FormValidators tests', () {
    test('required validator', () {
      expect(FormValidators.required(null, 'Nama'), 'Nama tidak boleh kosong');
      expect(FormValidators.required('', 'Nama'), 'Nama tidak boleh kosong');
      expect(FormValidators.required('   ', 'Nama'), 'Nama tidak boleh kosong');
      expect(FormValidators.required('Budi', 'Nama'), isNull);
    });

    test('email validator', () {
      expect(FormValidators.email(null), 'Email tidak boleh kosong');
      expect(FormValidators.email('invalid_email'), 'Format email tidak valid');
      expect(FormValidators.email('user@example.com'), isNull);
    });

    test('minLength validator', () {
      expect(FormValidators.minLength('123', 6, 'Password'), 'Password minimal 6 karakter');
      expect(FormValidators.minLength('123456', 6, 'Password'), isNull);
    });
  });
}
