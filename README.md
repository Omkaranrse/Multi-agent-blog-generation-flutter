# Blog Multi-Agent (research -> write -> human review -> edit)

```
backend/    FastAPI + LangGraph pipeline, WebSocket API, Firestore checkpointing
frontend/   Flutter client (web, iOS, Android) - source files only, see frontend/README.md
```

## Start here

1. `backend/README.md` - get the API running locally in ~5 minutes with
   `CHECKPOINT_BACKEND=memory` (no GCP account needed to start).
2. Confirm the pipeline works end to end with a raw WebSocket client before
   touching Flutter - it isolates backend bugs from frontend bugs.
3. `frontend/README.md` - turn the Flutter source into a runnable project
   and point it at your backend.
4. Once both work locally, switch the backend to `CHECKPOINT_BACKEND=firestore`
   and `REQUIRE_AUTH=true`, and deploy per the Cloud Run section of the
   backend README.

## What changed from what you had

- `agents.py`: fixed the `ChatPromptTemplate` message format (tuples, not
  dicts), fixed a bug where `revision_hints` was undefined whenever feedback
  was non-empty (this would have thrown `NameError` on every revision), and
  cleaned up prompt text that had stray literal quote characters baked in.
- `state.py`: `revision_count` was `0.` (a float) typed as `int`.
- `graph.py`: added a cap on the research-review loop (only the draft loop
  had one before) and wired the checkpointer as a parameter instead of
  hardcoding `InMemorySaver`.
- New: `checkpointer_factory.py`, `main.py` (FastAPI + WebSocket), auth
  verification, Dockerfile, and the whole `frontend/` directory.

## Honest status

The backend logic (agents, graph, routing) is code I'm confident in. The
WebSocket protocol and Flutter client are new code built to a spec, not
run against each other - I don't have a Flutter SDK or a live Groq/Firestore
setup in this environment to execute them end to end. Treat "it compiles and
the logic is sound" as the starting point, not "it's been tested." The
biggest single risk is the reconnect path, which is explicitly stubbed out
on both sides - fine to ship without it for a first pass, not fine to assume
it works.
