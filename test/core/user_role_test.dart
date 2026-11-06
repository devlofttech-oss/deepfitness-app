import 'package:deepfitness/core/models/member.dart';
import 'package:deepfitness/core/models/app_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('roles', () {
    test('an admin counts as staff', () {
      // Every "trainer or better" gate reads isStaff, so an admin must pass
      // it without being given a second role.
      expect(UserRole.admin.isStaff, isTrue);
      expect(UserRole.trainer.isStaff, isTrue);
      expect(UserRole.member.isStaff, isFalse);
    });

    test('only an admin is an admin', () {
      expect(UserRole.admin.isAdmin, isTrue);
      expect(UserRole.trainer.isAdmin, isFalse);
      expect(UserRole.member.isAdmin, isFalse);
    });

    test('the stored role name matches the custom claim', () {
      // These strings are the contract with setUserRole and with
      // firestore.rules; a rename on either side silently grants or denies
      // the wrong people.
      expect(UserRole.member.name, 'member');
      expect(UserRole.trainer.name, 'trainer');
      expect(UserRole.admin.name, 'admin');
    });
  });

  group('member documents', () {
    test('an admin document is no longer flattened to trainer', () {
      // It used to be: both mapped to UserRole.trainer, so the dashboard had
      // no way to tell them apart.
      expect(_roleFromStored('admin'), UserRole.admin);
      expect(_roleFromStored('trainer'), UserRole.trainer);
      expect(_roleFromStored('member'), UserRole.member);
    });

    test('an unknown stored role is the least privileged one', () {
      expect(_roleFromStored('superuser'), UserRole.member);
      expect(_roleFromStored(null), UserRole.member);
    });
  });

  group('membership status', () {
    test('only active can train', () {
      expect(MembershipStatus.active.canTrain, isTrue);
      expect(MembershipStatus.lapsed.canTrain, isFalse);
      expect(MembershipStatus.suspended.canTrain, isFalse);
    });

    test('the status name matches what the scheduled job writes', () {
      expect(MembershipStatus.active.name, 'active');
      expect(MembershipStatus.lapsed.name, 'lapsed');
    });
  });
}

/// Mirrors the switch in `Member.fromFirestore`, which cannot be called here
/// without a Firestore snapshot.
UserRole _roleFromStored(Object? value) => switch (value) {
  'admin' => UserRole.admin,
  'trainer' => UserRole.trainer,
  _ => UserRole.member,
};
