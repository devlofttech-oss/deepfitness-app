import 'package:deepfitness/core/models/base_fields.dart';
import 'package:deepfitness/core/models/member.dart';
import 'package:deepfitness/core/repositories/repository_failure.dart';
import 'package:deepfitness/core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizePhone', () {
    test('leaves an international number alone', () {
      expect(normalizePhone('+447700900123'), '+447700900123');
    });

    test('adds the default country code to a national number', () {
      expect(normalizePhone('9876543210'), '+919876543210');
    });

    test('drops the trunk zero before adding the country code', () {
      expect(normalizePhone('09876543210'), '+919876543210');
    });

    test('strips spaces, brackets and dashes', () {
      expect(normalizePhone('(098) 7654-3210'), '+919876543210');
    });
  });

  group('Member.isLapsed', () {
    Member member({
      MembershipStatus status = MembershipStatus.active,
      DateTime? expiry,
    }) {
      return Member(
        base: const BaseFields(id: 'uid-1'),
        name: 'Test',
        membershipStatus: status,
        expiryDate: expiry,
      );
    }

    test('an active membership with a future expiry has not lapsed', () {
      final future = DateTime.now().add(const Duration(days: 30));
      expect(member(expiry: future).isLapsed, isFalse);
    });

    test('an active membership whose date has passed counts as lapsed', () {
      // The scheduled function has not run yet, so the date is the more
      // truthful of the two.
      final past = DateTime.now().subtract(const Duration(days: 1));
      expect(member(expiry: past).isLapsed, isTrue);
    });

    test('a suspended membership has lapsed whatever the date says', () {
      final future = DateTime.now().add(const Duration(days: 30));
      expect(
        member(status: MembershipStatus.suspended, expiry: future).isLapsed,
        isTrue,
      );
    });

    test('no expiry date on an active membership is not lapsed', () {
      expect(member().isLapsed, isFalse);
    });
  });

  group('RepositoryFailure.fromAuth', () {
    test('a wrong code is invalid input, not an unknown error', () {
      final failure = RepositoryFailure.fromAuth(
        FirebaseAuthException(code: 'invalid-verification-code'),
      );
      expect(failure.kind, FailureKind.invalidInput);
    });

    test('an unrecognised code still produces a showable message', () {
      final failure = RepositoryFailure.fromAuth(
        FirebaseAuthException(code: 'something-new'),
      );
      expect(failure.kind, FailureKind.unknown);
      expect(failure.message, isNotEmpty);
    });
  });
}
