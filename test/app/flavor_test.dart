import 'package:deepfitness/app/flavor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('flavors', () {
    test('defaults to dev when no FLAVOR is passed', () {
      // Forgetting the define has to be harmless, never dangerous: the
      // default must be the one that cannot touch live gym data.
      expect(Flavor.current, Flavor.dev);
    });

    test('each flavor names its own Firebase project', () {
      expect(Flavor.dev.projectId, 'deepfitness-dev');
      expect(Flavor.prod.projectId, 'deepfitness-prod');
      expect(Flavor.dev.projectId, isNot(Flavor.prod.projectId));
    });

    test('only prod is prod', () {
      expect(Flavor.prod.isProd, isTrue);
      expect(Flavor.dev.isProd, isFalse);
    });

    test('a dev build is visibly named so on the home screen', () {
      expect(Flavor.dev.appName, contains('Dev'));
      expect(Flavor.prod.appName, 'Deep Fitness');
    });

    test('a dev-flavoured debug build starts without complaint', () {
      // These tests run unflavoured, so this is the dev path.
      expect(Flavor.assertSafeForBuildMode, returnsNormally);
    });
  });
}
