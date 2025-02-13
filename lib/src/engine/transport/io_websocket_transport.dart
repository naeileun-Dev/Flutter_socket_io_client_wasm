// Copyright (C) 2019 Potix Corporation. All Rights Reserved
// History: 2019-01-21 12:13
// Author: jumperchen<jumperchen@potix.com>

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:logging/logging.dart';
import 'package:socket_io_client/src/engine/transport.dart';
import 'package:socket_io_common/src/engine/parser/parser.dart';

class IOWebSocketTransport extends Transport {
  static final Logger _logger =
      Logger('socket_io_client:transport.IOWebSocketTransport');

  @override
  String? name = 'websocket';
  dynamic protocols;

  Map? perMessageDeflate;
  Map<String, dynamic>? extraHeaders;
  WebSocket? ws;

  IOWebSocketTransport(Map opts) : super(opts) {
    var forceBase64 = opts['forceBase64'] ?? false;
    supportsBinary = !forceBase64;
    perMessageDeflate = opts['perMessageDeflate'];
    protocols = opts['protocols'];
    extraHeaders = opts['extraHeaders'];
  }

  @override
  void doOpen() async {
    var uri = this.uri();
    var protocols = this.protocols;

    try {
      ws = await WebSocket.connect(uri,
          protocols: protocols, headers: extraHeaders);
    } catch (err) {
      return emit('error', err);
    }

//    if (this.ws?.binaryType == null) {
//      this.supportsBinary = false;
//    }
//
//    this.ws?.binaryType = 'arraybuffer';

    addEventListeners();
  }

  /// Adds event listeners to the socket
  ///
  /// @api private
  void addEventListeners() {
    var isOpen = false;
    ws?.listen((data) {
      if (isOpen != true) {
        onOpen();
        isOpen = true;
      }
      onData(data);
    }, onDone: () => onClose(), onError: (_) => onError('websocket error'));
  }

  /// Writes data to socket.
  ///
  /// @param {Array} array of packets.
  /// @api private
  @override
  void write(List packets) {
    writable = false;

    var total = packets.length;
    // encodePacket efficient as it uses WS framing
    // no need for encodePayload
    for (var packet in packets) {
      PacketParser.encodePacket(packet,
          supportsBinary: supportsBinary!, fromClient: true, callback: (data) {
        // Sometimes the websocket has already been closed but the browser didn't
        // have a chance of informing us about it yet, in that case send will
        // throw an error
        try {
          // TypeError is thrown when passing the second argument on Safari
          if (data is ByteBuffer) {
            ws?.add(data.asUint8List());
          } else {
            ws?.add(data);
          }
        } catch (e) {
          _logger.fine('websocket closed before onclose event');
        }

        if (--total == 0) {
          // fake drain
          // defer to next tick to allow Socket to clear writeBuffer
          Timer.run(() {
            writable = true;
            emitReserved('drain');
          });
        }
      });
    }
  }

  ///
  /// Closes socket.
  ///
  /// @api private
  @override
  void doClose() {
    ws?.close();
    ws = null;
  }

  ///
  /// Generates uri for connection.
  ///
  /// @api private
  String uri() {
    var query = this.query ?? {};
    var schema = opts['secure'] ? 'wss' : 'ws';
    // append timestamp to URI
    if (opts['timestampRequests'] == true) {
      query[opts['timestampParam']] =
          DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    }

    // communicate binary support capabilities
    if (supportsBinary == false) {
      query['b64'] = 1;
    }
    return createUri(schema, query);
  }
}
