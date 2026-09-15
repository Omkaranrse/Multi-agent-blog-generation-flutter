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

  /// Timeout for the initial connection handshake.
  static const _connectTimeout = Duration(seconds: 15);

  Future<void> start({
    required BlogSession session,
    required String topic,
    required String audience,
  }) async {
    session.setConnecting();

    String? token;
    try {
      token = await FirebaseAuth.instance.currentUser
          ?.getIdToken()
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      session.setError('Could not retrieve auth token: $e');
      return;
    }

    final uri = Uri.parse('$baseWsUrl/ws/blog').replace(
      queryParameters: token != null ? {'token': token} : null,
    );

    try {
      _channel = WebSocketChannel.connect(uri);
      // Wait for the connection to be ready (or fail fast).
      await _channel!.ready.timeout(_connectTimeout);
    } on TimeoutException {
      session.setError(
          'Connection timed out. The server may be starting up — try again in a moment.');
      return;
    } catch (e) {
      session.setError('Could not connect to the server: $e');
      return;
    }

    _sub = _channel!.stream.listen(
      (raw) {
        try {
          session.handleServerMessage(
              jsonDecode(raw as String) as Map<String, dynamic>);
        } catch (e) {
          session.setError('Received an unexpected message from the server.');
        }
      },
      onError: (e) => session.setError('Connection error: $e'),
      onDone: () {
        if (session.phase != SessionPhase.done &&
            session.phase != SessionPhase.error) {
          final code = _channel?.closeCode;
          final reason = _channel?.closeReason;
          if (code == 4401) {
            session.setError(
                'Authentication failed. Please sign out and sign back in.');
          } else if (code == 4429) {
            session.setError(
                'Too many sessions. Please wait a minute before trying again.');
          } else {
            session.setError(
                'Connection closed${code == null ? '' : ' ($code)'}${reason == null || reason.isEmpty ? '' : ': $reason'}');
          }
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
