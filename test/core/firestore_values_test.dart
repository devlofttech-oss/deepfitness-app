import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deepfitness/core/models/member.dart';
import 'package:deepfitness/core/utils/firestore_values.dart';
import 'package:deepfitness/features/auth/data/auth_repository.dart';
import 'package:deepfitness/shared/models/deepfitness_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('defensive reads', () {
    // The app is live, so documents written by older builds are missing fields
    // newer builds read. None of these may throw.
    test('numbers survive the wrong type', () {
      expect(Val.toInt('12'), 12);
      expect(Val.toInt(12.6), 13);
      expect(Val.toInt(null), 0);
      expect(Val.toInt('nonsense', fallback: 7), 7);
      expect(Val.toDouble('1.5'), 1.5);
      expect(Val.toNullableInt(null), isNull);
      expect(Val.toNullableDouble('x'), isNull);
    });

    test('booleans accept the shapes Firestore stores', () {
      expect(Val.toBool(true), isTrue);
      expect(Val.toBool('true'), isTrue);
      expect(Val.toBool('false'), isFalse);
      expect(Val.toBool(1), isTrue);
      expect(Val.toBool(null), isFalse);
      expect(Val.toBool(null, fallback: true), isTrue);
      // An unrecognised value must take the fallback, not flip it.
      expect(Val.toBool('maybe', fallback: true), isTrue);
    });

    test('text falls back when the field is missing or empty', () {
      expect(Val.toText(null, fallback: 'Member'), 'Member');
      expect(Val.toText('', fallback: 'Member'), 'Member');
      expect(Val.toText('Alex'), 'Alex');
      expect(Val.toNullableText('   '), isNull);
      expect(Val.toNullableText('Alex'), 'Alex');
    });

    test('dates accept a Timestamp, a string or epoch millis', () {
      final when = DateTime(2026, 11, 6, 8, 30);

      expect(Val.toNullableDate(Timestamp.fromDate(when)), when);
      expect(Val.toNullableDate(when.toIso8601String()), when);
      expect(
        Val.toNullableDate(when.millisecondsSinceEpoch),
        when,
      );
      expect(Val.toNullableDate(null), isNull);
      expect(Val.toNullableDate('not a date'), isNull);
    });

    test('lists tolerate nulls, blanks and a bare string', () {
      expect(Val.toTextList(['a', null, '', 'b']), ['a', 'b']);
      expect(Val.toTextList('solo'), ['solo']);
      expect(Val.toTextList(null), isEmpty);
      expect(Val.toMapList(null), isEmpty);
      expect(Val.toMapList([
        {'a': 1},
        'skip me',
      ]), [
        {'a': 1},
      ]);
    });
  });

  group('day keys', () {
    test('pads month and day', () {
      expect(Val.dayKey(DateTime(2026, 1, 5)), '2026-01-05');
      expect(Val.dayKey(DateTime(2026, 11, 6)), '2026-11-06');
    });

    test('a day key is stable across times on the same day', () {
      expect(
        Val.dayKey(DateTime(2026, 11, 6, 0, 1)),
        Val.dayKey(DateTime(2026, 11, 6, 23, 59)),
      );
    });

    test('start and end of day bracket the whole day', () {
      final start = Val.startOfDay(DateTime(2026, 11, 6, 14));
      final end = Val.endOfDay(DateTime(2026, 11, 6, 14));

      expect(start, DateTime(2026, 11, 6));
      expect(end, DateTime(2026, 11, 7));
      expect(end.difference(start).inHours, 24);
    });
  });

  group('phone normalisation', () {
    test('adds the default country code', () {
      expect(AuthRepository.normalizePhone('9876543210'), '+919876543210');
    });

    test('keeps an explicit country code', () {
      expect(AuthRepository.normalizePhone('+449876543210'), '+449876543210');
    });

    test('drops a leading trunk zero', () {
      expect(AuthRepository.normalizePhone('09876543210'), '+919876543210');
    });

    test('strips spaces, brackets and dashes', () {
      expect(
        AuthRepository.normalizePhone('(98765) 43-210'),
        '+919876543210',
      );
    });

    test('an email is recognised as one', () {
      expect(AuthRepository.looksLikeEmail('a@b.com'), isTrue);
      expect(AuthRepository.looksLikeEmail('9876543210'), isFalse);
    });
  });

  group('membership state', () {
    Member member({
      MembershipStatus status = MembershipStatus.active,
      DateTime? expiry,
    }) {
      return Member(
        id: 'm1',
        name: 'Alex',
        email: 'alex@example.com',
        phone: null,
        role: UserRole.member,
        membershipStatus: status,
        joinedAt: DateTime(2026, 1, 1),
        expiryDate: expiry,
      );
    }

    test('an active membership with a future expiry is not lapsed', () {
      final future = DateTime.now().add(const Duration(days: 30));
      expect(member(expiry: future).isLapsed, isFalse);
    });

    test('an expiry in the past lapses even while the status says active', () {
      // The scheduled job that flips the status may not have run yet, so the
      // date has to be checked on the client too.
      final past = DateTime.now().subtract(const Duration(days: 1));
      expect(member(expiry: past).isLapsed, isTrue);
    });

    test('a suspended membership is lapsed whatever the date says', () {
      final future = DateTime.now().add(const Duration(days: 30));
      expect(
        member(status: MembershipStatus.suspended, expiry: future).isLapsed,
        isTrue,
      );
    });

    test('no expiry date means no expiry', () {
      expect(member().isLapsed, isFalse);
      expect(member().daysUntilExpiry, isNull);
    });

    test('an unknown stored status falls back to active', () {
      expect(MembershipStatus.fromName('nonsense'), MembershipStatus.active);
    });
  });
}