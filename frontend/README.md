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

For local web development, Firebase is not required. Set `REQUIRE_AUTH=false`
in the backend `.env`; the web client connects without an auth token. The iOS
credential is already included at `ios/Runner/GoogleService-Info.plist` and is
used when running on iOS.

Firebase authentication can be added later for a production deployment by
adding `firebase_core` and `firebase_auth`, running `flutterfire configure`,
and passing the generated options to `Firebase.initializeApp`.
line and pass it to `Firebase.initializeApp`.

## Pointing at your backend

`lib/screens/session_screen.dart` has a `_backendWsUrl` constant -
`ws://localhost:8000` for local dev against `uvicorn --reload`, or
`wss://your-service-xyz.run.app` once deployed to Cloud Run. This is a
placeholder constant, not real config management - if you're shipping to
more than one environment, move it to `--dart-define` or a config file
before this grows.

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
- Anonymous auth only. Fine for a prototype, not for anything where a
  person's blog history should survive a reinstall.
