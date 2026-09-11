import 'package:flutter/foundation.dart';

enum SessionPhase {
  idle,
  connecting,
  running, // a node is actively executing (researcher_node, writer_node, ...)
  awaitingResearchReview,
  awaitingDraftReview,
  done,
  error,
}

/// Holds everything the UI needs to render the current step of a blog
/// session. Updated as messages arrive over the WebSocket - see
/// [BlogWsService].
class BlogSession extends ChangeNotifier {
  SessionPhase phase = SessionPhase.idle;

  String? threadId;
  String? activeNode;

  String? reviewText; // the research outline or draft currently under review
  String? reviewInstructions;

  String? finalBlog;
  String? errorMessage;

  void reset() {
    phase = SessionPhase.idle;
    threadId = null;
    activeNode = null;
    reviewText = null;
    reviewInstructions = null;
    finalBlog = null;
    errorMessage = null;
    notifyListeners();
  }

  void handleServerMessage(Map<String, dynamic> message) {
    switch (message['type']) {
      case 'started':
        threadId = message['thread_id'] as String?;
        phase = SessionPhase.running;
        break;

      case 'node_update':
        activeNode = message['node'] as String?;
        phase = SessionPhase.running;
        break;

      case 'interrupt':
        reviewText = (message['research'] ?? message['draft']) as String?;
        reviewInstructions = message['instructions'] as String?;
        phase = message['stage'] == 'research_review'
            ? SessionPhase.awaitingResearchReview
            : SessionPhase.awaitingDraftReview;
        break;

      case 'final':
        finalBlog = message['blog'] as String?;
        phase = SessionPhase.done;
        break;

      case 'error':
        errorMessage = message['message'] as String?;
        phase = SessionPhase.error;
        break;
    }
    notifyListeners();
  }

  void setConnecting() {
    phase = SessionPhase.connecting;
    notifyListeners();
  }

  void setError(String message) {
    errorMessage = message;
    phase = SessionPhase.error;
    notifyListeners();
  }
}
