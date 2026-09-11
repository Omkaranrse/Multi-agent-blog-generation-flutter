"""
FastAPI entrypoint.

One WebSocket connection drives one blog-writing session end to end:

  client -> {"action": "start", "topic": ..., "audience": ...}
  server -> {"type": "started", "thread_id": "..."}
  server -> {"type": "node_update", "node": "researcher_node"}
  server -> {"type": "interrupt", "stage": "research_review", "research": "...", "instructions": "..."}
  client -> {"action": "resume", "decision": {"action": "approve"}}
        or {"action": "resume", "decision": {"action": "revise", "feedback": "..."}}
  ... repeats through draft_review ...
  server -> {"type": "final", "blog": "..."}

Reconnecting mid-session: send {"action": "start", "thread_id": "<existing id>"}
and the server will fetch the current state via checkpointer instead of
starting the graph over. (Reconnect handling below is intentionally minimal -
see the TODO in `blog_ws`. Test this path before relying on it; it is the
least-exercised part of this file.)
"""

import os
import uuid
import logging

from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from langgraph.types import Command
from dotenv import load_dotenv

from .checkpointer_factory import get_checkpointer
from .graph import build_blog_graph

load_dotenv()
logger = logging.getLogger(__name__)

app = FastAPI(title="Blog Multi-Agent API")

# Tighten this to your actual Flutter web origin(s) before shipping.
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.environ.get("CORS_ORIGINS", "*").split(","),
    allow_methods=["*"],
    allow_headers=["*"],
)

_checkpointer = get_checkpointer()
_graph = build_blog_graph(_checkpointer)

_REQUIRE_AUTH = os.environ.get("REQUIRE_AUTH", "true").lower() != "false"


def _get_firebase_auth():
    """Lazy import + init so local dev with REQUIRE_AUTH=false needs no
    firebase_admin credentials at all."""
    import firebase_admin
    from firebase_admin import auth as fb_auth

    if not firebase_admin._apps:
        firebase_admin.initialize_app()  # uses Application Default Credentials
    return fb_auth


async def _authenticate(websocket: WebSocket) -> str:
    """Returns the authenticated user's uid, or 'anonymous-dev' if auth is
    disabled. Closes the socket and raises if a token is required but
    missing/invalid."""
    if not _REQUIRE_AUTH:
        return "anonymous-dev"

    token = websocket.query_params.get("token")
    if not token:
        await websocket.close(code=4401, reason="Missing auth token")
        raise WebSocketDisconnect(code=4401)

    try:
        fb_auth = _get_firebase_auth()
    except Exception:
        logger.exception("Firebase Admin initialization failed")
        await websocket.close(code=1011, reason="Firebase Admin is not configured")
        raise WebSocketDisconnect(code=1011)

    try:
        decoded = fb_auth.verify_id_token(token)
        return decoded["uid"]
    except Exception:
        logger.exception("Firebase ID token verification failed")
        await websocket.close(code=4401, reason="Invalid auth token")
        raise WebSocketDisconnect(code=4401)


def _serialize_interrupt(chunk: dict) -> dict:
    interrupt_obj = chunk["__interrupt__"][0]
    payload = dict(interrupt_obj.value)
    payload["type"] = "interrupt"
    return payload


async def _drain_stream(websocket: WebSocket, stream, thread_id: str, config: dict) -> None:
    try:
        async for chunk in stream:
            if "__interrupt__" in chunk:
                await websocket.send_json(_serialize_interrupt(chunk))
                return  # pause; wait for the client's next "resume" message
            for node_name in chunk:
                await websocket.send_json({"type": "node_update", "node": node_name})

        # Stream ended with no interrupt -> the graph reached END.
        snapshot = await _graph.aget_state(config)
        await websocket.send_json({
            "type": "final",
            "blog": snapshot.values.get("final_blog", ""),
        })
    except Exception:
        logger.exception("Blog graph execution failed")
        await websocket.send_json({
            "type": "error",
            "message": "The blog agent failed while processing this step. Check the backend logs.",
        })


@app.websocket("/ws/blog")
async def blog_ws(websocket: WebSocket):
    await websocket.accept()
    uid = await _authenticate(websocket)

    try:
        first_message = await websocket.receive_json()
        if first_message.get("action") != "start":
            await websocket.send_json({
                "type": "error",
                "message": "First message must be {'action': 'start', 'topic': ..., 'audience': ...}",
            })
            await websocket.close()
            return

        thread_id = first_message.get("thread_id") or str(uuid.uuid4())
        config = {"configurable": {"thread_id": thread_id}}
        await websocket.send_json({"type": "started", "thread_id": thread_id})

        existing = await _graph.aget_state(config)
        if existing.values.get("topic"):
            # TODO: reconnect path. We have prior state for this thread_id;
            # a full implementation should re-send the last interrupt payload
            # here instead of falling through, so the client can redraw the
            # review screen after a dropped connection. Untested - verify
            # before depending on it.
            pass
        else:
            if "topic" not in first_message:
                await websocket.send_json({"type": "error", "message": "Missing 'topic'"})
                await websocket.close()
                return
            initial_input = {
                "user_id": uid,
                "topic": first_message["topic"],
                "audience": first_message.get("audience", "general readers"),
            }
            stream = _graph.astream(initial_input, config=config, stream_mode="updates")
            await _drain_stream(websocket, stream, thread_id, config)

        while True:
            message = await websocket.receive_json()
            if message.get("action") != "resume":
                await websocket.send_json({
                    "type": "error",
                    "message": "Expected {'action': 'resume', 'decision': {...}}",
                })
                continue
            decision = message.get("decision", {})
            stream = _graph.astream(Command(resume=decision), config=config, stream_mode="updates")
            await _drain_stream(websocket, stream, thread_id, config)

    except WebSocketDisconnect:
        # Session state already lives in Firestore via the checkpointer - the
        # client can reconnect with the same thread_id and pick up from here
        # once the TODO above is filled in.
        pass


@app.get("/health")
async def health():
    return {"status": "ok"}
