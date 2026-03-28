import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:university_portal/features/auth/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen shows form fields and sign in button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    expect(find.text('University Portal'), findsOneWidget);
    expect(find.text('Sign in to your account'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('LoginScreen validates empty roll number', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    // Tap Sign In without entering anything
    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Roll number or email is required'), findsOneWidget);
  });

  testWidgets('LoginScreen validates empty password', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    // Enter roll number but not password
    await tester.enterText(
      find.byType(TextFormField).first,
      '2024CS001',
    );
    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('LoginScreen toggles password visibility', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    // Find the visibility toggle icon
    final visibilityIcon = find.byIcon(Icons.visibility_off);
    expect(visibilityIcon, findsOneWidget);

    // Tap to show password
    await tester.tap(visibilityIcon);
    await tester.pump();

    expect(find.byIcon(Icons.visibility), findsOneWidget);
  });
}
