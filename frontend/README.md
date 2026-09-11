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

This isn't a `flutter create` scaffold - it's the `lib/` source and
`pubspec.yaml` only. To get a runnable project:

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

## What's genuinely untested here

I wrote this against the backend's WebSocket message shapes, but I have not
run `flutter analyze` or `flutter run` against it - there is no Flutter SDK
in the environment I built this in. Before you trust it:

```bash
flutter analyze
flutter run -d chrome   # fastest platform to iterate on
```

Package versions in `pubspec.yaml` (`web_socket_channel`, `flutter_markdown`,
`firebase_core`/`firebase_auth`) are pinned to what I believe are current
stable releases as of early 2026 - run `flutter pub outdated` and bump if
`flutter pub get` complains about version solving.

## Known gaps

- No reconnect handling - if the WebSocket drops mid-session, the UI shows
  an error rather than resuming. The backend's checkpointer preserves the
  session either way; wiring reconnect through is a matter of passing the
  saved `thread_id` back into `BlogWsService.start()` and handling the
  backend's reconnect path once that TODO (see backend README) is filled in.
- Google authentication and Firestore history are enabled. Firestore rules
  scope each user's posts to their Firebase UID.
