# Flutter client

Talks to the backend over one WebSocket per session (`/ws/blog`), streaming
node-progress and review prompts, and rendering the final blog as markdown.

## Setup

### Firebase Hosting

Build and deploy the web client from this directory:

```bash
flutter build web --release \
  --dart-define=BACKEND_WS_URL=wss://your-backend.example.com
firebase deploy --only hosting
```

The Firebase project configured in `.firebaserc` is `blog-multiagent`. The
backend must be deployed separately and supplied as a secure `wss://` URL;
the default `ws://localhost:8000` is for local development only.

This repository contains a complete Flutter project. If recreating the
platform folders from source, use:

```bash
flutter create --org com.yourcompany --project-name blog_multiagent_app .
# this generates android/, ios/, web/, etc. and a default pubspec.yaml -
# then copy this pubspec.yaml and lib/ back over the generated ones.

flutter pub get

Firebase Auth is configured for web, iOS, and Android with Google sign-in.
Enable **Google** under Firebase Console → Authentication → Sign-in method and
add `blog-multiagent.web.app` under Authorized domains. Production requires
`REQUIRE_AUTH=true` and Firebase Admin credentials on the backend.

## Pointing at your backend

`lib/screens/session_screen.dart` reads `BACKEND_WS_URL` from `--dart-define`.
Use `ws://localhost:8000` for local development and the deployed `wss://`
Render URL for Firebase Hosting.

## Validation

```bash
flutter analyze
flutter build web --release \
  --dart-define=BACKEND_WS_URL=wss://blog-multiagent-api.onrender.com
```

Run `flutter pub outdated` periodically to review dependency updates.

## Current Limitations

- Reconnect is intentionally rejected by the backend. A dropped session shows
  an error and the user starts a new session.
- Google authentication and Firestore history are enabled. Firestore rules
  scope each user's posts to their Firebase UID.
