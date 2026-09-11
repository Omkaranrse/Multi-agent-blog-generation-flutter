# Blog multi-agent backend

FastAPI + LangGraph. One WebSocket (`/ws/blog`) drives the whole
researcher -> human review -> writer -> human review -> editor pipeline,
with LangGraph's `interrupt()` pausing execution at each human-review step.

## Local dev (fastest path, no GCP needed)

Use Python 3.11, matching the project Docker image.

```bash
cd backend
python3.11 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
# edit .env: set GROQ_API_KEY, leave CHECKPOINT_BACKEND=memory and REQUIRE_AUTH=false
uvicorn app.main:app --reload
```

Test it without Flutter first, with any WebSocket client (e.g. `wscat`,
`websocat`, or a browser console):

```bash
websocat ws://localhost:8000/ws/blog
```

Send:
```json
{"action": "start", "topic": "why sourdough starters die", "audience": "home bakers"}
```

You'll get `started`, then a `node_update` for `researcher_node`, then an
`interrupt` with the research outline. Reply:
```json
{"action": "resume", "decision": {"action": "approve"}}
```
or
```json
{"action": "resume", "decision": {"action": "revise", "feedback": "add a section on hydration ratios"}}
```

## Switching to Firestore + real auth

1. `gcloud auth application-default login` (or set
   `GOOGLE_APPLICATION_CREDENTIALS` to a service account key for CI/prod).
2. In `.env`: `CHECKPOINT_BACKEND=firestore`, `GCP_PROJECT_ID=<your project>`,
   `REQUIRE_AUTH=true`.
3. Firestore must be in **Native mode**, not Datastore mode. Collections are
   created automatically on first write.
4. Flutter needs to pass a Firebase Auth ID token as a query param:
   `wss://your-backend/ws/blog?token=<idToken>`.

For Render, set `REQUIRE_AUTH=true` and add a Firebase Admin service-account
JSON as a secret file. Set `GOOGLE_APPLICATION_CREDENTIALS` to the mounted
secret-file path, for example `/etc/secrets/firebase-admin.json`. Never use a
Firebase web config or client API key as backend credentials.

## Known gaps - read before you rely on this

- **The reconnect path in `main.py` is a stub.** If a client disconnects
  mid-interrupt and reconnects, the server currently doesn't re-send the
  pending interrupt payload (there's a `TODO` marking exactly where to add
  it). Session state itself is safe in Firestore either way - this only
  affects redrawing the UI after a dropped connection.
- **The Firestore checkpointer is a third-party package**
  (`langgraph-checkpoint-firestore`), not something Anthropic or the
  LangChain team maintains. It's real and published, but test your actual
  interrupt/resume flow against it before trusting it in production -
  checkpoint interfaces have changed across `langgraph` releases before, and
  a version mismatch here would fail in ways that are annoying to debug.
- **CORS is wide open (`*`) by default.** Fine for local dev, not for a
  public deploy - set `CORS_ORIGINS` once you have a real Flutter web
  origin.

## Deploying to Cloud Run

```bash
gcloud run deploy blog-multiagent \
  --source . \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars CHECKPOINT_BACKEND=firestore,GCP_PROJECT_ID=<your-project>,REQUIRE_AUTH=true \
  --set-secrets GROQ_API_KEY=groq-api-key:latest
```

Cloud Run supports WebSockets, but connections are capped at 60 minutes and
idle timeouts apply - fine for this use case (each session is a few LLM
calls plus human think-time), but worth knowing if you ever add long-running
steps.
