// web_transports.dart (정확한 해결버전)
import 'package:web/web.dart' as web;
import '../transport.dart';

class Transports {
  static List<String> upgradesTo(String from) {
    return ['websocket'];
  }

  static Transport newInstance(String name, options) {
    switch (name) {
      case 'websocket':
        return WebSocketTransport(options);
      default:
        throw UnsupportedError('Unsupported transport: $name');
    }
  }
}

class WebSocketTransport extends Transport {
  late web.WebSocket _ws; // 이름 충돌 방지를 위해 private으로 변경.

  WebSocketTransport(opts) : super(opts);

  @override
  String get name => 'websocket';

  @override
  void doOpen() {
    final uri = _uriString(); // uriString()이 아닌 _uriString() 으로 변경
    _ws = web.WebSocket(uri);

    _ws.onOpen.listen((_) => onOpen());
    _ws.onMessage.listen((e) => onData(e.data));
    _ws.onClose.listen((_) => onClose());
    _ws.onError.listen((e) => onError(e));
  }

  @override
  void write(List packets) {
    for (var packet in packets) {
      _ws.send(packet);
    }
  }

  @override
  void doClose() {
    _ws.close();
  }

  // uriString 메서드 직접 구현 (기존 Transport에 없는 경우 필수)
  String _uriString() {
    final schema = opts['secure'] ? 'wss' : 'ws';
    final host = opts['hostname'];
    final port = opts['port'];
    final path = opts['path'];
    final query = encodeQuery(opts['query']);
    final portStr = (port != null && port != 80 && port != 443) ? ':$port' : '';

    return '$schema://$host$portStr$path?$query';
  }

  // encodeQuery 구현 (기존 parseqs.dart에 있을 가능성 높음)
  String encodeQuery(Map? query) {
    if (query == null) return '';
    return query.entries
        .map((entry) =>
            '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value.toString())}')
        .join('&');
  }
}
