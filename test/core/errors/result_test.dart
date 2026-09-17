// test/core/errors/result_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/core/errors/failures.dart';
import 'package:mutasiku/core/errors/result.dart';

void main() {
  group('Result pattern tests', () {
    test('Success returns data and isSuccess is true', () {
      const result = Result<String>.success('Hello');

      expect(result.isSuccess, true);
      expect(result.isFailure, false);
      expect(result.dataOrNull, 'Hello');
      expect(result.failureOrNull, isNull);
    });

    test('Failure returns failure and isFailure is true', () {
      const failure = NetworkFailure(message: 'No internet');
      const result = Result<String>.failure(failure);

      expect(result.isSuccess, false);
      expect(result.isFailure, true);
      expect(result.dataOrNull, isNull);
      expect(result.failureOrNull, failure);
    });

    test('when executes correct callbacks', () {
      const successResult = Result<int>.success(42);
      int val = 0;
      successResult.when(
        onSuccess: (data) => val = data * 2,
        onFailure: (_) => val = 0,
      );
      expect(val, 84);

      const failureResult = Result<int>.failure(NetworkFailure(message: 'Error'));
      int errVal = 0;
      failureResult.when(
        onSuccess: (data) => errVal = data * 2,
        onFailure: (f) => errVal = -1,
      );
      expect(errVal, -1);
    });

    test('map transforms success value correctly', () {
      const result = Result<int>.success(5);
      final mapped = result.map((data) => 'Value: $data');

      expect(mapped.isSuccess, true);
      expect(mapped.dataOrNull, 'Value: 5');
    });
  });
}
