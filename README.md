# Blog Multi-Agent

A production-oriented blog writing workspace that combines a multi-agent AI pipeline with human review. A Researcher creates the outline, a Writer produces the draft, and an Editor polishes the final article. The user remains in control at two review checkpoints.

## Live Services

| Service | URL |
| --- | --- |
| Flutter web app | https://blog-multiagent.web.app |
| FastAPI backend | https://blog-multiagent-api.onrender.com |
| Backend health | https://blog-multiagent-api.onrender.com/health |

The hosted Flutter app connects to the backend through:

```text
wss://blog-multiagent-api.onrender.com/ws/blog
```

## Architecture

```text
Flutter Web / iOS / Android
        |
        | Firebase Auth ID token
        v
FastAPI WebSocket API on Render
        |
        | LangGraph state machine
        v
Researcher -> Human review -> Writer -> Human review -> Editor
        |
        +--> Groq LLM API
        +--> LangGraph checkpointer
        +--> Firestore user history
```

### Repository layout

```text
backend/
  app/
    agents.py               Groq-powered agent functions and prompts
    checkpointer_factory.py In-memory or Firestore checkpoint selection
    graph.py                LangGraph nodes, routing, and review interrupts
    main.py                 FastAPI app, WebSocket protocol, and auth
    state.py                Typed blog pipeline state
  Dockerfile                Render deployment image
  requirements.txt          Python dependencies

frontend/
  lib/
    main.dart               Firebase initialization and auth gate
    firebase_options.dart   Firebase web configuration
    screens/                Auth, writing, review, history, and result UI
    services/               WebSocket and Firestore history services
    models/                 Dart data models
    theme.dart              Shared visual system
  firebase.json              Firebase Hosting and Firestore configuration
  firestore.rules            Per-user Firestore access rules
  pubspec.yaml               Flutter dependencies
```

## Product Flow

1. The user signs in with Google through Firebase Authentication.
2. The user enters a topic and target audience.
3. The Researcher agent creates a structured outline.
4. The user approves the outline or requests a revision.
5. The Writer agent creates a Markdown draft.
6. The user approves the draft or requests a revision.
7. The Editor agent produces the final blog post.
8. The completed post is stored in Firestore under the authenticated user's UID.
9. The History tab displays only that user's saved posts.

## Local Development

### Backend

Use Python 3.11, matching the Docker image:

```bash
cd backend
python3.11 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
```

Set a Groq key in `.env` and use local settings:

```text
GROQ_API_KEY=your_groq_key
CHECKPOINT_BACKEND=memory
REQUIRE_AUTH=false
CORS_ORIGINS=*
```

Start the API:

```bash
uvicorn app.main:app --reload --port 8000
```

Health check:

```bash
curl http://localhost:8000/health
```

### Flutter client

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

For local development, the client uses `ws://localhost:8000` by default. Firebase must still be configured if using the Google sign-in flow locally.

## Production Deployment

### Backend on Render

Configure the Render Web Service with:

```text
Root Directory: backend
Dockerfile Path: Dockerfile
Docker Build Context Directory: .
Health Check Path: /health
```

Set these Render environment variables:

```text
CHECKPOINT_BACKEND=memory
REQUIRE_AUTH=true
GCP_PROJECT_ID=blog-multiagent
GOOGLE_APPLICATION_CREDENTIALS=/etc/secrets/firebase-admin.json
CORS_ORIGINS=https://blog-multiagent.web.app
GROQ_API_KEY=your_current_groq_key
```

Add a Render Secret File:

```text
Filename: firebase-admin.json
```

The file must contain a Firebase Admin service-account JSON for the `blog-multiagent` project. Never commit it to Git or expose it in screenshots, logs, or chat.

### Flutter web on Firebase Hosting

```bash
cd frontend
flutter build web --release \
  --dart-define=BACKEND_WS_URL=wss://blog-multiagent-api.onrender.com
firebase deploy --only firestore:rules,hosting --project blog-multiagent
```

Use `wss://` for the production WebSocket URL. Do not use `localhost` in a hosted build.

## Firebase Setup

Enable these Firebase services for the `blog-multiagent` project:

- Authentication: Google provider
- Firestore Database: Native mode
- Hosting

Add the Hosting domain to Firebase Authentication authorized domains:

```text
blog-multiagent.web.app
blog-multiagent.firebaseapp.com
```

Firestore rules scope history to the signed-in user:

```text
users/{uid}/blogs/{blogId}
```

## WebSocket Protocol

The client starts a session with:

```json
{
  "action": "start",
  "topic": "why sourdough starters die",
  "audience": "home bakers"
}
```

The server sends progress messages:

```json
{"type": "started", "thread_id": "..."}
{"type": "node_update", "node": "researcher_node"}
```

At a human checkpoint it sends an interrupt:

```json
{
  "type": "interrupt",
  "stage": "research_review",
  "research": "...",
  "instructions": "..."
}
```

The client resumes with either:

```json
{"action": "resume", "decision": {"action": "approve"}}
```

or:

```json
{"action": "resume", "decision": {"action": "revise", "feedback": "Add a section on hydration ratios."}}
```

The final response is:

```json
{"type": "final", "blog": "..."}
```

Authenticated clients pass the Firebase ID token as a query parameter:

```text
wss://backend.example.com/ws/blog?token=<firebase-id-token>
```

## Environment Variables

| Variable | Purpose |
| --- | --- |
| `GROQ_API_KEY` | Authenticates requests to the Groq LLM API. |
| `CHECKPOINT_BACKEND` | Selects `memory` for local use or `firestore` for persistent checkpoints. |
| `GCP_PROJECT_ID` | Firebase/Google Cloud project ID used by Admin SDK and Firestore. |
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to the mounted Firebase Admin service-account JSON. |
| `CHECKPOINT_COLLECTION` | Firestore collection name for LangGraph checkpoints. |
| `REQUIRE_AUTH` | Requires Firebase ID-token verification when `true`. |
| `CORS_ORIGINS` | Comma-separated browser origins allowed by the API. |
| `BACKEND_WS_URL` | Flutter compile-time WebSocket endpoint supplied with `--dart-define`. |

## Key Terms

- **Agent:** A focused LLM-powered component with a specific responsibility, such as research or editing.
- **LangGraph:** The orchestration framework that models the blog workflow as a state graph.
- **Node:** A LangGraph execution step, such as `researcher_node` or `editor_node`.
- **State:** The typed `BlogState` object carrying topic, research, draft, feedback, identity, and final output through the graph.
- **Human-in-the-loop:** A workflow pattern where execution pauses for a user decision before continuing.
- **Interrupt:** LangGraph's pause mechanism used for research and draft review.
- **Resume:** A `Command` containing the user's approval or revision feedback that continues the paused graph.
- **Checkpointer:** Persistence used by LangGraph to save and restore graph state.
- **InMemorySaver:** The local, non-persistent checkpoint backend.
- **Firestore checkpointer:** The production checkpoint backend backed by Google Cloud Firestore.
- **Thread ID:** The identifier for one blog pipeline execution and its checkpoint history.
- **WebSocket:** A long-lived bidirectional connection used to stream progress and review messages.
- **Firebase Authentication:** The identity service issuing Firebase ID tokens after Google sign-in.
- **Firebase Admin SDK:** The backend SDK that verifies Firebase ID tokens securely.
- **UID:** The stable Firebase user identifier used to scope Firestore records.
- **Firestore:** Firebase's document database used for per-user blog history and optional checkpoints.
- **Firestore rules:** Server-enforced authorization rules that restrict documents to their owner's UID.
- **Groq:** The hosted LLM API used by the Researcher, Writer, and Editor agents.
- **FastAPI:** The Python web framework hosting the health endpoint and WebSocket API.
- **Render:** The platform hosting the containerized FastAPI backend.
- **Firebase Hosting:** The CDN-backed static hosting platform serving the Flutter web build.
- **CORS:** Browser origin policy configuration controlling which web clients may call the API.
- **Markdown:** The text format used for drafts and final blog content.
- **Docker:** The container technology used to package and run the backend consistently.

## Security Notes

- Never commit `.env`, Groq keys, Firebase Admin JSON files, or private keys.
- Rotate any credential that appears in Git history, logs, screenshots, or chat.
- Keep `REQUIRE_AUTH=true` and a specific `CORS_ORIGINS` value in production.
- Do not use the Firebase web API key as a backend credential.
- The Render service must use the Firebase Admin service-account JSON through a secret file.

## Validation

```bash
cd backend
.venv/bin/python -m pip check
.venv/bin/python -m compileall -q app

cd ../frontend
flutter analyze
flutter build web --release \
  --dart-define=BACKEND_WS_URL=wss://blog-multiagent-api.onrender.com
```
