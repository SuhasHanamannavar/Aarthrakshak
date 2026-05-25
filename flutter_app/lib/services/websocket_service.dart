import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final StreamController<String> _streamController =
      StreamController<String>.broadcast();

  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  bool _shouldReconnect = true;

  Stream<String> get transactionStream => _streamController.stream;

  void connect() {
    _shouldReconnect = true;
    _reconnectAttempts = 0;
    _doConnect();
  }

  void _doConnect() {
    if (!_shouldReconnect || _reconnectAttempts >= _maxReconnectAttempts) return;
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('wss://aarthrakshak-backend.onrender.com/ws'),
      );
      // Immediately subscribe or wait for server implementation
      _subscription = _channel!.stream.listen(
        (data) => _streamController.add(data as String),
        onError: (_) => _onDisconnected(),
        onDone: () => _onDisconnected(),
        cancelOnError: false,
      );
    } catch (_) {
      _onDisconnected();
    }
  }

  void _onDisconnected() {
    _subscription?.cancel();
    _channel?.sink.close();
    _reconnectAttempts++;
    if (_shouldReconnect && _reconnectAttempts < _maxReconnectAttempts) {
      Future.delayed(_reconnectDelay, _doConnect);
    }
  }

  void disconnect() {
    _shouldReconnect = false;
    _subscription?.cancel();
    _channel?.sink.close();
    _streamController.close();
  }
}
