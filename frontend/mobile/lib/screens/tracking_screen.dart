import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';
import '../config/app_theme.dart';
import '../config/app_config.dart';
import '../models/route.dart';

class TrackingScreen extends StatefulWidget {
  final UserRoute route;
  final String sessionId;

  const TrackingScreen({
    super.key,
    required this.route,
    required this.sessionId,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  GoogleMapController? _mapController;
  IO.Socket? _socket;

  // Tracking state
  LatLng? _busLocation;
  LatLng? _stopLocation;
  int? _etaMinutes;
  double? _distanceKm;
  String _status = 'מתחבר...';
  bool _isTracking = true;

  // Map markers
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _initializeTracking() {
    // Initialize WebSocket connection
    _socket = IO.io(
      AppConfig.apiBaseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    _socket?.onConnect((_) {
      print('🔌 Connected to tracking server');
      setState(() => _status = 'מחובר');

      // Join tracking session
      _socket?.emit('join_tracking', {
        'session_id': widget.sessionId,
      });
    });

    _socket?.onDisconnect((_) {
      print('❌ Disconnected from tracking server');
      setState(() => _status = 'מנותק');
    });

    // Listen for bus location updates
    _socket?.on('bus_location_update', (data) {
      _handleLocationUpdate(data);
    });

    // Listen for ETA updates
    _socket?.on('eta_update', (data) {
      _handleEtaUpdate(data);
    });

    // Listen for tracking completion
    _socket?.on('tracking_complete', (data) {
      _handleTrackingComplete(data);
    });

    // Listen for errors
    _socket?.on('tracking_error', (data) {
      _handleTrackingError(data);
    });

    _socket?.connect();
  }

  void _handleLocationUpdate(dynamic data) {
    if (data == null) return;

    setState(() {
      if (data['bus_lat'] != null && data['bus_lng'] != null) {
        _busLocation = LatLng(data['bus_lat'], data['bus_lng']);
        _updateBusMarker();
      }

      if (data['stop_lat'] != null && data['stop_lng'] != null) {
        _stopLocation = LatLng(data['stop_lat'], data['stop_lng']);
        _updateStopMarker();
      }

      if (data['distance_km'] != null) {
        _distanceKm = data['distance_km'].toDouble();
      }

      _updateRoutePolyline();
      _centerMapOnBus();
    });
  }

  void _handleEtaUpdate(dynamic data) {
    if (data == null) return;

    setState(() {
      if (data['eta_minutes'] != null) {
        _etaMinutes = data['eta_minutes'];
      }
      _status = 'עוקב';
    });
  }

  void _handleTrackingComplete(dynamic data) {
    setState(() {
      _status = 'הושלם';
      _isTracking = false;
    });

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.success, size: 32),
            SizedBox(width: 12),
            Text('הגעת ליעד!'),
          ],
        ),
        content: Text(data['message'] ?? 'המעקב הושלם בהצלחה'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to home
            },
            child: const Text('סגור'),
          ),
        ],
      ),
    );
  }

  void _handleTrackingError(dynamic data) {
    setState(() {
      _status = 'שגיאה';
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(data['message'] ?? 'שגיאה במעקב'),
        backgroundColor: AppTheme.error,
      ),
    );
  }

  void _updateBusMarker() {
    if (_busLocation == null) return;

    _markers.removeWhere((m) => m.markerId.value == 'bus');
    _markers.add(
      Marker(
        markerId: const MarkerId('bus'),
        position: _busLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: 'אוטובוס ${widget.route.routeNumber}',
          snippet: _etaMinutes != null ? 'ETA: $_etaMinutes דקות' : null,
        ),
      ),
    );
  }

  void _updateStopMarker() {
    if (_stopLocation == null) return;

    _markers.removeWhere((m) => m.markerId.value == 'stop');
    _markers.add(
      Marker(
        markerId: const MarkerId('stop'),
        position: _stopLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: widget.route.stopName ?? 'תחנה',
          snippet: 'היעד שלך',
        ),
      ),
    );
  }

  void _updateRoutePolyline() {
    if (_busLocation == null || _stopLocation == null) return;

    _polylines.clear();
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: [_busLocation!, _stopLocation!],
        color: AppTheme.primary,
        width: 4,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    );
  }

  void _centerMapOnBus() {
    if (_busLocation == null || _mapController == null) return;

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _busLocation!,
          zoom: 15,
        ),
      ),
    );
  }

  Future<void> _stopTracking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('עצור מעקב'),
        content: const Text('האם אתה בטוח שברצונך לעצור את המעקב?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.error,
            ),
            child: const Text('עצור'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _socket?.emit('stop_tracking', {
        'session_id': widget.sessionId,
      });

      setState(() {
        _isTracking = false;
        _status = 'הופסק';
      });

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Color _getStatusColor() {
    switch (_status) {
      case 'מחובר':
      case 'עוקב':
        return AppTheme.success;
      case 'מנותק':
      case 'שגיאה':
      case 'הופסק':
        return AppTheme.error;
      case 'הושלם':
        return AppTheme.info;
      default:
        return AppTheme.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('מעקב קו ${widget.route.routeNumber}'),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _getStatusColor()),
            ),
            child: Text(
              _status,
              style: TextStyle(
                color: _getStatusColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _busLocation ?? const LatLng(32.0853, 34.7818), // Tel Aviv default
              zoom: 13,
            ),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            compassEnabled: true,
            mapToolbarEnabled: false,
          ),

          // Info Card
          Positioned(
            top: 16,
            right: 16,
            left: 16,
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Route Info
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.route.routeNumber,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.route.routeName != null)
                                Text(
                                  widget.route.routeName!,
                                  style: AppTheme.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              if (widget.route.stopName != null)
                                Text(
                                  widget.route.stopName!,
                                  style: AppTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 24),

                    // ETA Display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoItem(
                          icon: Icons.access_time,
                          label: 'זמן הגעה משוער',
                          value: _etaMinutes != null
                              ? '$_etaMinutes דקות'
                              : '--',
                          color: _etaMinutes != null && _etaMinutes! <= 5
                              ? AppTheme.error
                              : AppTheme.primary,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppTheme.divider,
                        ),
                        _buildInfoItem(
                          icon: Icons.straighten,
                          label: 'מרחק',
                          value: _distanceKm != null
                              ? '${_distanceKm!.toStringAsFixed(1)} ק״מ'
                              : '--',
                          color: AppTheme.info,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Stop Button
          if (_isTracking)
            Positioned(
              bottom: 32,
              right: 16,
              left: 16,
              child: ElevatedButton.icon(
                onPressed: _stopTracking,
                icon: const Icon(Icons.stop_circle),
                label: const Text(
                  'עצור מעקב',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 8,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.headline3.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
