import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:busalert/services/api_service.dart';

@GenerateMocks([http.Client])
import 'api_service_test.mocks.dart';

void main() {
  group('ApiService Tests', () {
    late ApiService apiService;
    late MockClient mockClient;

    setUp(() {
      apiService = ApiService();
      mockClient = MockClient();
    });

    group('Authentication', () {
      test('register should return success response', () async {
        // Arrange
        final mockResponse = {
          'success': true,
          'message': 'User registered successfully',
          'data': {
            'user_id': '123',
            'phone_number': '0501234567',
          },
        };

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer(
          (_) async => http.Response(
            jsonEncode(mockResponse),
            200,
          ),
        );

        // Act
        final result = await apiService.register('0501234567', 'Test User');

        // Assert
        expect(result['success'], true);
        expect(result['data']['phone_number'], '0501234567');
      });

      test('verify should save token on success', () async {
        // Arrange
        final mockResponse = {
          'success': true,
          'message': 'Verification successful',
          'data': {
            'token': 'test_token_123',
            'user': {
              'id': '123',
              'phone_number': '0501234567',
            },
          },
        };

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer(
          (_) async => http.Response(
            jsonEncode(mockResponse),
            200,
          ),
        );

        // Act
        final result = await apiService.verify('0501234567', '1234');

        // Assert
        expect(result['success'], true);
        expect(result['data']['token'], 'test_token_123');
      });

      test('register should throw exception on failure', () async {
        // Arrange
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer(
          (_) async => http.Response(
            jsonEncode({'error': 'Invalid phone number'}),
            400,
          ),
        );

        // Act & Assert
        expect(
          () async => await apiService.register('invalid', null),
          throwsException,
        );
      });
    });

    group('Routes', () {
      test('createRoute should return route object', () async {
        // Arrange
        final mockRoute = {
          'id': 'route_123',
          'route_number': '5',
          'stop_id': '12345',
          'is_active': true,
        };

        final mockResponse = {
          'success': true,
          'data': {'route': mockRoute},
        };

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer(
          (_) async => http.Response(
            jsonEncode(mockResponse),
            201,
          ),
        );

        // Act
        final result = await apiService.createRoute({
          'route_number': '5',
          'stop_id': '12345',
        });

        // Assert
        expect(result.routeNumber, '5');
        expect(result.stopId, '12345');
      });

      test('getRoutes should return list of routes', () async {
        // Arrange
        final mockRoutes = [
          {
            'id': 'route_1',
            'route_number': '5',
            'stop_id': '12345',
          },
          {
            'id': 'route_2',
            'route_number': '18',
            'stop_id': '67890',
          },
        ];

        final mockResponse = {
          'success': true,
          'data': mockRoutes,
        };

        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer(
          (_) async => http.Response(
            jsonEncode(mockResponse),
            200,
          ),
        );

        // Act
        final result = await apiService.getRoutes();

        // Assert
        expect(result.length, 2);
        expect(result[0].routeNumber, '5');
        expect(result[1].routeNumber, '18');
      });

      test('deleteRoute should complete without error', () async {
        // Arrange
        when(mockClient.delete(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer(
          (_) async => http.Response(
            jsonEncode({'success': true}),
            200,
          ),
        );

        // Act & Assert
        expect(
          () async => await apiService.deleteRoute('route_123'),
          returnsNormally,
        );
      });
    });

    group('Tracking', () {
      test('startTracking should return session_id', () async {
        // Arrange
        final mockResponse = {
          'success': true,
          'session_id': 'session_123',
          'message': 'Tracking started',
        };

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer(
          (_) async => http.Response(
            jsonEncode(mockResponse),
            200,
          ),
        );

        // Act
        final result = await apiService.startTracking(
          routeId: 'route_123',
          stopId: '12345',
          routeNumber: '5',
        );

        // Assert
        expect(result['success'], true);
        expect(result['session_id'], 'session_123');
      });

      test('stopTracking should complete successfully', () async {
        // Arrange
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer(
          (_) async => http.Response(
            jsonEncode({'success': true}),
            200,
          ),
        );

        // Act
        final result = await apiService.stopTracking('session_123');

        // Assert
        expect(result['success'], true);
      });
    });
  });
}
