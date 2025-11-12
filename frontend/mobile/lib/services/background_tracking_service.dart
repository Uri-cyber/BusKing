import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'location_service.dart';
import 'geofence_service.dart';
import 'notification_service.dart';

class BackgroundTrackingService {
  static final BackgroundTrackingService _instance =
      BackgroundTrackingService._internal();
  factory BackgroundTrackingService() => _instance;
  BackgroundTrackingService._internal();

  final LocationService _locationService = LocationService();
  final GeofenceService _geofenceService = GeofenceService();
  final NotificationService _notificationService = NotificationService();

  bool _isTracking = false;
  String? _currentSessionId;
  Timer? _periodicUpdateTimer;

  bool get isTracking => _isTracking;
  String? get currentSessionId => _currentSessionId;

  /// Start background tracking
  Future<void> startTracking({
    required String sessionId,
    required String routeNumber,
    required String stopId,
    required double stopLat,
    required double stopLng,
    required Function(Position) onLocationUpdate,
  }) async {
    if (_isTracking) {
      debugPrint('⚠️ Already tracking');
      return;
    }

    try {
      _currentSessionId = sessionId;

      // Ensure location permissions
      await _locationService.ensureLocationReady();

      // Add geofence for the bus stop
      final stopGeofence = _geofenceService.createBusStopGeofence(
        stopId: stopId,
        stopName: 'תחנה $stopId',
        latitude: stopLat,
        longitude: stopLng,
        radiusMeters: 100,
      );
      _geofenceService.addGeofence(stopGeofence);

      // Set up geofence event handler
      _geofenceService.onGeofenceEvent = (geofence, event, position) {
        _handleGeofenceEvent(geofence, event, position, routeNumber);
      };

      // Start geofence monitoring
      await _geofenceService.startMonitoring(
        accuracy: LocationAccuracy.high,
        distanceFilterMeters: 10,
      );

      // Start location tracking
      _locationService.listenToLocationUpdates(
        onLocationUpdate: onLocationUpdate,
        accuracy: LocationAccuracy.high,
        distanceFilterMeters: 10,
      );

      // Periodic updates every 30 seconds
      _periodicUpdateTimer = Timer.periodic(
        const Duration(seconds: 30),
        (timer) {
          _sendPeriodicUpdate();
        },
      );

      _isTracking = true;
      debugPrint('✅ Background tracking started for session: $sessionId');
    } catch (e) {
      debugPrint('❌ Failed to start background tracking: $e');
      rethrow;
    }
  }

  /// Stop background tracking
  void stopTracking() {
    _locationService.stopLocationTracking();
    _geofenceService.stopMonitoring();
    _periodicUpdateTimer?.cancel();
    _periodicUpdateTimer = null;
    _isTracking = false;
    _currentSessionId = null;
    debugPrint('🛑 Background tracking stopped');
  }

  /// Handle geofence events
  void _handleGeofenceEvent(
    Geofence geofence,
    GeofenceEvent event,
    Position position,
    String routeNumber,
  ) {
    final metadata = geofence.metadata;
    if (metadata == null) return;

    switch (event) {
      case GeofenceEvent.enter:
        if (metadata['type'] == 'bus_stop') {
          // User entered the bus stop area
          _notificationService.showNotification(
            title: 'הגעת לתחנה! 🚏',
            body: 'אתה נמצא בקרבת התחנה של קו $routeNumber',
          );
        } else if (metadata['type'] == 'bus') {
          // Bus entered the tracking area
          _notificationService.showNotification(
            title: 'האוטובוס מתקרב! 🚌',
            body: 'קו $routeNumber נמצא בסביבה',
          );
        }
        break;

      case GeofenceEvent.exit:
        if (metadata['type'] == 'bus_stop') {
          // User left the bus stop area
          debugPrint('👋 User left the bus stop area');
        }
        break;

      case GeofenceEvent.dwell:
        // User is dwelling in the area
        debugPrint('⏱️ User dwelling in geofence: ${geofence.id}');
        break;
    }
  }

  /// Send periodic location updates
  void _sendPeriodicUpdate() {
    final position = _locationService.lastKnownPosition;
    if (position != null) {
      debugPrint(
        '📍 Periodic update - Lat: ${position.latitude}, Lng: ${position.longitude}',
      );
      // Here you can send the position to your backend if needed
    }
  }

  /// Add dynamic geofence for moving bus
  void updateBusGeofence({
    required double busLat,
    required double busLng,
    required String routeNumber,
  }) {
    if (_currentSessionId == null) return;

    // Remove old bus geofence
    _geofenceService.removeGeofence('bus_$_currentSessionId');

    // Add new bus geofence at updated location
    final busGeofence = _geofenceService.createBusGeofence(
      sessionId: _currentSessionId!,
      routeNumber: routeNumber,
      latitude: busLat,
      longitude: busLng,
      radiusMeters: 200,
    );
    _geofenceService.addGeofence(busGeofence);
  }

  /// Check if user is near the bus stop
  Future<bool> isNearBusStop(String stopId) async {
    return _geofenceService.isInsideGeofence('stop_$stopId');
  }

  /// Get distance to bus stop
  Future<double?> getDistanceToBusStop(String stopId) async {
    return await _geofenceService.getDistanceToGeofence('stop_$stopId');
  }

  /// Dispose resources
  void dispose() {
    stopTracking();
    _geofenceService.dispose();
    _locationService.dispose();
  }
}
