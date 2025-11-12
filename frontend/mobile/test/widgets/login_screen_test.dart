import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:busalert/screens/login_screen.dart';
import 'package:busalert/providers/auth_provider.dart';

@GenerateMocks([AuthProvider])
import 'login_screen_test.mocks.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    late MockAuthProvider mockAuthProvider;

    setUp(() {
      mockAuthProvider = MockAuthProvider();
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.error).thenReturn(null);
    });

    testWidgets('should display phone number input field', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: mockAuthProvider,
            child: const LoginScreen(),
          ),
        ),
      );

      // Assert
      expect(find.byType(TextField), findsAtLeastNWidgets(1));
      expect(find.text('מספר טלפון'), findsOneWidget);
    });

    testWidgets('should display login button', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: mockAuthProvider,
            child: const LoginScreen(),
          ),
        ),
      );

      // Assert
      expect(find.text('התחבר'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsAtLeastNWidgets(1));
    });

    testWidgets('should call register when login button tapped', (tester) async {
      // Arrange
      when(mockAuthProvider.register(any, any)).thenAnswer((_) async => true);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: mockAuthProvider,
            child: const LoginScreen(),
          ),
        ),
      );

      // Act
      final phoneField = find.byType(TextField).first;
      await tester.enterText(phoneField, '0501234567');
      await tester.tap(find.text('התחבר'));
      await tester.pump();

      // Assert
      verify(mockAuthProvider.register('0501234567', any)).called(1);
    });

    testWidgets('should show error message on failed login', (tester) async {
      // Arrange
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.error).thenReturn('Invalid phone number');

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: mockAuthProvider,
            child: const LoginScreen(),
          ),
        ),
      );

      // Assert
      expect(find.text('Invalid phone number'), findsOneWidget);
    });

    testWidgets('should show loading indicator during login', (tester) async {
      // Arrange
      when(mockAuthProvider.isLoading).thenReturn(true);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: mockAuthProvider,
            child: const LoginScreen(),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should validate phone number format', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: mockAuthProvider,
            child: const LoginScreen(),
          ),
        ),
      );

      // Act - Enter invalid phone number
      final phoneField = find.byType(TextField).first;
      await tester.enterText(phoneField, '123');
      await tester.tap(find.text('התחבר'));
      await tester.pump();

      // Assert - Should show validation error
      expect(find.text('מספר טלפון לא תקין'), findsOneWidget);
    });
  });
}
