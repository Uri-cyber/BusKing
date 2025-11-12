import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:busalert/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('BusAlert Integration Tests', () {
    testWidgets('Complete user flow: Login -> Add Route -> Track', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Should show splash screen initially
      expect(find.text('BusAlert'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should navigate to login screen (if not logged in)
      expect(find.text('התחבר'), findsOneWidget);

      // Enter phone number
      final phoneField = find.byType(TextField).first;
      await tester.enterText(phoneField, '0501234567');
      await tester.pumpAndSettle();

      // Tap login button
      await tester.tap(find.text('התחבר'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should show verification code screen
      expect(find.text('קוד אימות'), findsOneWidget);

      // Enter verification code
      final codeFields = find.byType(TextField);
      for (var i = 0; i < 4; i++) {
        await tester.enterText(codeFields.at(i), '1');
        await tester.pumpAndSettle();
      }

      // Tap verify button
      await tester.tap(find.text('אמת'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should navigate to home screen
      expect(find.text('המסלולים שלי'), findsOneWidget);

      // Tap add route button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Should show add route screen
      expect(find.text('הוסף מסלול'), findsOneWidget);

      // Fill in route details
      final stopIdField = find.widgetWithText(TextField, 'מספר תחנה');
      await tester.enterText(stopIdField, '12345');
      await tester.pumpAndSettle();

      final routeNumberField = find.widgetWithText(TextField, 'מספר קו');
      await tester.enterText(routeNumberField, '5');
      await tester.pumpAndSettle();

      // Select days
      await tester.tap(find.text('א'));
      await tester.tap(find.text('ב'));
      await tester.tap(find.text('ג'));
      await tester.pumpAndSettle();

      // Tap save button
      await tester.tap(find.text('שמור'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should return to home screen with new route
      expect(find.text('קו 5'), findsOneWidget);

      // Tap "Track Now" button
      await tester.tap(find.text('עקוב עכשיו'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should navigate to tracking screen
      expect(find.text('מעקב קו 5'), findsOneWidget);

      // Verify map is displayed
      expect(find.byType(GoogleMap), findsOneWidget);

      // Verify stop button exists
      expect(find.text('עצור מעקב'), findsOneWidget);
    });

    testWidgets('Checklist flow: View -> Add -> Delete', (tester) async {
      // Start the app (assuming already logged in from previous test)
      app.main();
      await tester.pumpAndSettle();

      // Navigate to checklist screen
      await tester.tap(find.byIcon(Icons.checklist));
      await tester.pumpAndSettle();

      // Should show checklist screen
      expect(find.text('צ\'קליסט שלי'), findsOneWidget);

      // Tap add button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Should show add dialog
      expect(find.text('הוסף פריט'), findsOneWidget);

      // Enter item details
      final nameField = find.widgetWithText(TextField, 'שם הפריט');
      await tester.enterText(nameField, 'מפתחות');
      await tester.pumpAndSettle();

      final emojiField = find.widgetWithText(TextField, 'אמוג\'י (אופציונלי)');
      await tester.enterText(emojiField, '🔑');
      await tester.pumpAndSettle();

      // Tap add button
      await tester.tap(find.text('הוסף'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should show new item in list
      expect(find.text('מפתחות'), findsOneWidget);
      expect(find.text('🔑'), findsOneWidget);

      // Tap delete button
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.text('מחק פריט'), findsOneWidget);

      // Confirm deletion
      await tester.tap(find.text('מחק'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Item should be removed
      expect(find.text('מפתחות'), findsNothing);
    });

    testWidgets('Settings flow: Update preferences', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Should show settings screen
      expect(find.text('הגדרות'), findsOneWidget);

      // Toggle quiet mode
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      // Should update switch state
      final switchWidget = tester.widget<Switch>(find.byType(Switch).first);
      expect(switchWidget.value, isTrue);

      // Tap notification settings
      await tester.tap(find.text('התרעות'));
      await tester.pumpAndSettle();

      // Should navigate to notification settings
      expect(find.text('הגדרות התרעות'), findsOneWidget);
    });

    testWidgets('Logout flow', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Scroll to bottom
      await tester.dragUntilVisible(
        find.text('התנתק'),
        find.byType(ListView),
        const Offset(0, -200),
      );

      // Tap logout
      await tester.tap(find.text('התנתק'));
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.text('התנתקות'), findsOneWidget);

      // Confirm logout
      await tester.tap(find.text('התנתק'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should navigate back to login screen
      expect(find.text('התחבר'), findsOneWidget);
    });
  });
}
