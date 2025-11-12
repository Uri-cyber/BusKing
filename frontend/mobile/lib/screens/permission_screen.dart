import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  final LocationService _locationService = LocationService();
  final NotificationService _notificationService = NotificationService();

  bool _locationGranted = false;
  bool _notificationGranted = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    // Check location permission
    final locationPermission = await _locationService.checkPermission();
    setState(() {
      _locationGranted = locationPermission == LocationPermission.whileInUse ||
          locationPermission == LocationPermission.always;
    });

    // Check notification permission
    final notificationSettings =
        await FirebaseMessaging.instance.getNotificationSettings();
    setState(() {
      _notificationGranted =
          notificationSettings.authorizationStatus == AuthorizationStatus.authorized;
    });
  }

  Future<void> _requestLocationPermission() async {
    setState(() => _isLoading = true);

    try {
      await _locationService.requestPermission();
      await _checkPermissions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('הרשאת מיקום אושרה ✓'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestNotificationPermission() async {
    setState(() => _isLoading = true);

    try {
      await _notificationService.initialize();
      await _checkPermissions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('הרשאת התרעות אושרה ✓'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _continueToApp() {
    if (_locationGranted && _notificationGranted) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('יש לאשר את כל הגישות כדי להמשיך'),
          backgroundColor: AppTheme.warning,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allGranted = _locationGranted && _notificationGranted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('הרשאות נדרשות'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Icon(
                Icons.security,
                size: 80,
                color: AppTheme.primary,
              ),
              const SizedBox(height: 20),
              const Text(
                'הרשאות נדרשות',
                style: AppTheme.headline1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'BusAlert זקוק להרשאות הבאות כדי לספק לך את השירות הטוב ביותר',
                style: AppTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Location Permission
              _buildPermissionCard(
                icon: Icons.location_on,
                title: 'גישה למיקום',
                description: 'נדרש כדי לעקוב אחר האוטובוס ולשלוח התרעות בזמן',
                isGranted: _locationGranted,
                onRequest: _requestLocationPermission,
              ),
              const SizedBox(height: 16),

              // Notification Permission
              _buildPermissionCard(
                icon: Icons.notifications,
                title: 'התרעות',
                description: 'נדרש כדי לשלוח התרעות על הגעת האוטובוס',
                isGranted: _notificationGranted,
                onRequest: _requestNotificationPermission,
              ),

              const Spacer(),

              // Continue Button
              if (allGranted)
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _continueToApp,
                  icon: const Icon(Icons.check_circle),
                  label: const Text(
                    'המשך',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                )
              else
                const Text(
                  'אנא אשר את כל ההרשאות כדי להמשיך',
                  style: AppTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 16),

              // Skip Button
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: const Text('דלג לעת עתה'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onRequest,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isGranted
                    ? AppTheme.success.withOpacity(0.1)
                    : AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isGranted ? AppTheme.success : AppTheme.primary,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (isGranted)
              const Icon(
                Icons.check_circle,
                color: AppTheme.success,
                size: 32,
              )
            else
              IconButton(
                onPressed: _isLoading ? null : onRequest,
                icon: const Icon(Icons.arrow_circle_left),
                color: AppTheme.primary,
                iconSize: 32,
              ),
          ],
        ),
      ),
    );
  }
}
