import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/blog_session.dart';

/// Wraps a single WebSocket connection to `/ws/blog` for the lifetime of one
/// blog-writing session. One instance per session - don't reuse across
/// sessions, create a new one.
class BlogWsService {
  BlogWsService({required this.baseWsUrl});

  /// e.g. "ws://localhost:8000" for local dev, "wss://your-service.run.app"
  /// once deployed. No trailing slash.
  final String baseWsUrl;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  Future<void> start({
    required BlogSession session,
    required String topic,
    required String audience,
  }) async {
    session.setConnecting();

    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    final uri = Uri.parse('$baseWsUrl/ws/blog').replace(
      queryParameters: token != null ? {'token': token} : null,
    );

    try {
      _channel = WebSocketChannel.connect(uri);
    } catch (e) {
      session.setError('Could not connect: $e');
      return;
    }

    _sub = _channel!.stream.listen(
      (raw) => session.handleServerMessage(
          jsonDecode(raw as String) as Map<String, dynamic>),
      onError: (e) => session.setError('Connection error: $e'),
      onDone: () {
        if (session.phase != SessionPhase.done) {
          final code = _channel?.closeCode;
          final reason = _channel?.closeReason;
          session.setError(
              'Connection closed${code == null ? '' : ' ($code)'}${reason == null ? '' : ': $reason'}');
        }
      },
    );

    _send({'action': 'start', 'topic': topic, 'audience': audience});
  }

  void approve() => _send({
        'action': 'resume',
        'decision': {'action': 'approve'},
      });

  void requestRevision(String feedback) => _send({
        'action': 'resume',
        'decision': {'action': 'revise', 'feedback': feedback},
      });

  void _send(Map<String, dynamic> message) {
    _channel?.sink.add(jsonEncode(message));
  }

  void dispose() {
    _sub?.cancel();
    _channel?.sink.close();
  }
}
