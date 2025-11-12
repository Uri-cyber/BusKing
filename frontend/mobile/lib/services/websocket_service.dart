import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/app_config.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  io.Socket? _socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  // Callbacks
  Function(Map<String, dynamic>)? onBusUpdate;
  Function(Map<String, dynamic>)? onAlertTriggered;
  Function(Map<String, dynamic>)? onTrackingStatus;

  void connect(String token) {
    if (_socket != null && _socket!.connected) {
      return;
    }

    _socket = io.io(
      AppConfig.wsUrl,
      io.OptionBuilder()
          .setPath('/ws')
          .setAuth({'token': token})
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      print('🔌 WebSocket connected');
      _isConnected = true;
    });

    _socket!.onDisconnect((_) {
      print('❌ WebSocket disconnected');
      _isConnected = false;
    });

    _socket!.onConnectError((error) {
      print('WebSocket connection error: $error');
      _isConnected = false;
    });

    // Listen to events
    _socket!.on('bus_update', (data) {
      print('📍 Bus update received');
      if (onBusUpdate != null) {
        onBusUpdate!(data as Map<String, dynamic>);
      }
    });

    _socket!.on('alert_triggered', (data) {
      print('🔔 Alert triggered');
      if (onAlertTriggered != null) {
        onAlertTriggered!(data as Map<String, dynamic>);
      }
    });

    _socket!.on('tracking_status', (data) {
      print('📡 Tracking status changed');
      if (onTrackingStatus != null) {
        onTrackingStatus!(data as Map<String, dynamic>);
      }
    });

    _socket!.connect();
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
    }
  }

  void emit(String event, [dynamic data]) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit(event, data);
    } else {
      print('⚠️  Cannot emit: WebSocket not connected');
    }
  }
}
