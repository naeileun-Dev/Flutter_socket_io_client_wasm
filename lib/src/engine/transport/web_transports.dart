// web_transports.dart
import 'package:web/web.dart' as web;
import '../transport.dart';

class Transports {
  static Transport newInstance(String name, opts) {
    switch (name) {
      case 'websocket':
        return WebSocketTransport(opts);
      default:
        throw UnsupportedError('Unsupported transport: $name');
    }
  }
}

class WebSocketTransport extends Transport {
  late web.WebSocket socket;

  WebSocketTransport(opts) : super(opts) {
    final uri = uriString();
    socket = web.WebSocket(uri);

    socket.onOpen.listen((_) => onOpen());
    socket.onClose.listen((event) => onClose());
    socket.onError.listen((event) => onError(event));
    socket.onMessage.listen((event) => onData(event.data));
  }

  @override
  String get name => 'websocket';

  @override
  void doOpen() {
    // 이미 constructor에서 처리됨.
  }

  @override
  void write(List packets) {
    for (var packet in packets) {
      socket.send(packet);
    }
  }

  @override
  void doClose() {
    socket.close();
  }
}
