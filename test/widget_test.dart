import 'package:deepfitness/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> _launch(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: DeepFitnessApp()));

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1500));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('DeepFitness launches to login', (tester) async {
    await _launch(tester);

    expect(find.text('Welcome Back'), findsOneWidget);
  });

  testWidgets('login offers phone first, with email as the fallback', (
    tester,
  ) async {
    // Phone OTP is the primary method per the developer guide, so the phone
    // step is what a member sees before touching anything.
    await _launch(tester);

    expect(find.text('Mobile Number'), findsOneWidget);
    expect(find.text('Send Code'), findsOneWidget);
    expect(find.text('Log In'), findsNothing);
    expect(find.text('Password'), findsNothing);
  });

  testWidgets('switching to email shows the password form', (tester) async {
    await _launch(tester);

    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();

    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text('Mobile Number'), findsNothing);
  });
}
