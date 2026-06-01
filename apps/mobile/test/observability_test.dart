import 'package:flutter_test/flutter_test.dart';
import 'package:khatir_mobile/core/observability/logger.dart';
import 'package:khatir_mobile/core/observability/sentry_init.dart';

void main() {
  group('maskPii', () {
    test('masks NID keeping last four digits', () {
      final masked = maskPii('nid=1990123456788');
      expect(masked.contains('1990123456788'), isFalse);
      expect(masked.endsWith('6788'), isTrue);
      expect(masked.contains('****'), isTrue);
    });

    test('masks bearer token', () {
      final masked = maskPii('Authorization: Bearer abc.def.ghijkl');
      expect(masked.contains('abc.def.ghijkl'), isFalse);
      expect(masked.contains('****'), isTrue);
    });

    test('masks otp and token fields', () {
      final masked = maskPii('{"otp": "123456", "token": "eyJabc"}');
      expect(masked.contains('123456'), isFalse);
      expect(masked.contains('eyJabc'), isFalse);
    });

    test('masks bKash trx id', () {
      final masked = maskPii('trxid=8N7A1B2C3D');
      expect(masked.contains('8N7A1B2C3D'), isFalse);
      expect(masked.contains('****'), isTrue);
    });

    test('is idempotent', () {
      final once = maskPii('nid=1990123456788 token=abcdef');
      expect(maskPii(once), once);
    });
  });

  test('sentry disabled by default (no DSN baked in)', () {
    expect(sentryEnabled, isFalse);
  });
}
