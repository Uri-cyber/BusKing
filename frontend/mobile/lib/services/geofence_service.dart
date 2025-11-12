import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'location_service.dart';

enum GeofenceEvent {
  enter,
  exit,
  dwell,
}

class Geofence {
  final String id;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final Map<String, dynamic>? metadata;

  Geofence({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.metadata,
  });

  bool contains(double lat, double lng) {
    final distance = Geolocator.distanceBetween(
      latitude,
      longitude,
      lat,
      lng,
    );
    return distance <= radiusMeters;
  }

  double distanceFrom(double lat, double lng) {
    return Geolocator.distanceBetween(
      latitude,
      longitude,
      lat,
      lng,
    );
  }
}

class GeofenceService {
  static final GeofenceService _instance = GeofenceService._internal();
  factory GeofenceService() => _instance;
  GeofenceService._internal();

  final LocationService _locationService = LocationService();
  final Map<String, Geofence> _geofences = {};
  final Map<String, bool> _insideGeofences = {};
  final Map<String, DateTime> _enterTimes = {};

  StreamSubscription<Position>? _locationSubscription;
  bool _isMonitoring = false;

  // Callbacks
  Function(Geofence, GeofenceEvent, Position)? onGeofenceEvent;

  bool get isMonitoring => _isMonitoring;
  List<Geofence> get geofences => _geofences.values.toList();

  /// Add a geofence
  void addGeofence(Geofence geofence) {
    _geofences[geofence.id] = geofence;
    _insideGeofences[geofence.id] = false;
    debugPrint('✅ Geofence added: ${geofence.id} (${geofence.radiusMeters}m radius)');
  }

  /// Remove a geofence
  void removeGeofence(String geofenceId) {
    _geofences.remove(geofenceId);
    _insideGeofences.remove(geofenceId);
    _enterTimes.remove(geofenceId);
    debugPrint('🗑️ Geofence removed: $geofenceId');
  }

  /// Clear all geofences
  void clearAllGeofences() {
    _geofences.clear();
    _insideGeofences.clear();
    _enterTimes.clear();
    debugPrint('🗑️ All geofences cleared');
  }

  /// Start monitoring geofences
  Future<void> startMonitoring({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilterMeters = 10,
  }) async {
    if (_isMonitoring) {
      debugPrint('⚠️ Already monitoring geofences');
      return;
    }

    try {
      // Ensure location is ready
      await _locationService.ensureLocationReady();

      // Get initial position
      final initialPosition = await _locationService.getCurrentPosition();
      _checkGeofences(initialPosition);

      // Start listening to location updates
      _locationSubscription = _locationService.startLocationTracking(
        accuracy: accuracy,
        distanceFilterMeters: distanceFilterMeters,
      ).listen(
        (Position position) {
          _checkGeofences(position);
        },
        onError: (error) {
          debugPrint('❌ Geofence monitoring error: $error');
        },
      );

      _isMonitoring = true;
      debugPrint('✅ Geofence monitoring started');
    } catch (e) {
      debugPrint('❌ Failed to start geofence monitoring: $e');
      rethrow;
    }
  }

  /// Stop monitoring geofences
  void stopMonitoring() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _isMonitoring = false;
    debugPrint('🛑 Geofence monitoring stopped');
  }

  /// Check all geofences for the current position
  void _checkGeofences(Position position) {
    for (final geofence in _geofences.values) {
      final wasInside = _insideGeofences[geofence.id] ?? false;
      final isInside = geofence.contains(position.latitude, position.longitude);

      if (isInside && !wasInside) {
        // Enter event
        _insideGeofences[geofence.id] = true;
        _enterTimes[geofence.id] = DateTime.now();
        onGeofenceEvent?.call(geofence, GeofenceEvent.enter, position);
        debugPrint('🚶 Entered geofence: ${geofence.id}');
      } else if (!isInside && wasInside) {
        // Exit event
        _insideGeofences[geofence.id] = false;
        _enterTimes.remove(geofence.id);
        onGeofenceEvent?.call(geofence, GeofenceEvent.exit, position);
        debugPrint('🚶 Exited geofence: ${geofence.id}');
      } else if (isInside && wasInside) {
        // Dwell event (inside for certain duration)
        final enterTime = _enterTimes[geofence.id];
        if (enterTime != null) {
          final dwellDuration = DateTime.now().difference(enterTime);
          if (dwellDuration.inSeconds % 30 == 0) {
            // Fire dwell event every 30 seconds
            onGeofenceEvent?.call(geofence, GeofenceEvent.dwell, position);
            debugPrint('⏱️ Dwelling in geofence: ${geofence.id} (${dwellDuration.inSeconds}s)');
          }
        }
      }
    }
  }

  /// Get distance to a specific geofence
  Future<double?> getDistanceToGeofence(String geofenceId) async {
    final geofence = _geofences[geofenceId];
    if (geofence == null) return null;

    try {
      final position = await _locationService.getCurrentPosition();
      return geofence.distanceFrom(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('❌ Failed to get distance to geofence: $e');
      return null;
    }
  }

  /// Check if currently inside a geofence
  bool isInsideGeofence(String geofenceId) {
    return _insideGeofences[geofenceId] ?? false;
  }

  /// Get all active geofences (user is currently inside)
  List<Geofence> getActiveGeofences() {
    return _geofences.values
        .where((geofence) => _insideGeofences[geofence.id] == true)
        .toList();
  }

  /// Create a geofence for a bus stop
  Geofence createBusStopGeofence({
    required String stopId,
    required String stopName,
    required double latitude,
    required double longitude,
    double radiusMeters = 100,
  }) {
    return Geofence(
      id: 'stop_$stopId',
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      metadata: {
        'type': 'bus_stop',
        'stop_id': stopId,
        'stop_name': stopName,
      },
    );
  }

  /// Create a geofence for bus tracking
  Geofence createBusGeofence({
    required String sessionId,
    required String routeNumber,
    required double latitude,
    required double longitude,
    double radiusMeters = 200,
  }) {
    return Geofence(
      id: 'bus_$sessionId',
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      metadata: {
        'type': 'bus',
        'session_id': sessionId,
        'route_number': routeNumber,
      },
    );
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    clearAllGeofences();
  }
}
