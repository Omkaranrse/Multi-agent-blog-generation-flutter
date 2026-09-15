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
import time
from collections import defaultdict, deque

from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from langgraph.types import Command
from dotenv import load_dotenv
from pydantic import BaseModel, ValidationError

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
MAX_TOPIC_LENGTH = 500
MAX_AUDIENCE_LENGTH = 200
MAX_FEEDBACK_LENGTH = 2_000
SESSION_WINDOW_SECONDS = 60
MAX_SESSIONS_PER_WINDOW = 5
_session_attempts: dict[str, deque[float]] = defaultdict(deque)


class StartMessage(BaseModel):
    action: str
    topic: str | None = None
    audience: str = "general readers"
    thread_id: str | None = None


class Decision(BaseModel):
    action: str = "approve"
    feedback: str = ""


class ResumeMessage(BaseModel):
    action: str
    decision: Decision = Decision()


def _validate_text(value: str, field: str, maximum: int) -> str:
    value = value.strip()
    if not value:
        raise ValueError(f"{field} cannot be empty")
    if len(value) > maximum:
        raise ValueError(f"{field} exceeds the {maximum}-character limit")
    return value


def _allow_session(uid: str) -> bool:
    now = time.monotonic()
    attempts = _session_attempts[uid]
    while attempts and now - attempts[0] > SESSION_WINDOW_SECONDS:
        attempts.popleft()
    if len(attempts) >= MAX_SESSIONS_PER_WINDOW:
        return False
    attempts.append(now)
    return True


def _get_firebase_auth():
    """Lazy import + init so local dev with REQUIRE_AUTH=false needs no
    firebase_admin credentials at all."""
    import firebase_admin
    from firebase_admin import auth as fb_auth

    if not firebase_admin._apps:
        project_id = (
            os.environ.get("GOOGLE_CLOUD_PROJECT")
            or os.environ.get("GCP_PROJECT_ID")
        )
        if not project_id:
            raise ValueError(
                "GCP_PROJECT_ID or GOOGLE_CLOUD_PROJECT must be set when auth is enabled"
            )
        firebase_admin.initialize_app(options={"projectId": project_id})
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
    except Exception as exc:
        logger.exception("Blog graph execution failed")
        # Surface actionable messages for common failure modes.
        error_msg = str(exc)
        if "invalid_api_key" in error_msg.lower() or "authentication" in error_msg.lower():
            user_msg = (
                "The Groq API key is invalid or expired. "
                "Please update GROQ_API_KEY in the server's .env file with a valid key "
                "from https://console.groq.com/keys"
            )
        elif "model" in error_msg.lower() and "not found" in error_msg.lower():
            user_msg = (
                "The configured LLM model was not found on Groq. "
                "Please check the model name in agents.py."
            )
        else:
            user_msg = "The blog agent failed while processing this step. Check the backend logs."
        await websocket.send_json({
            "type": "error",
            "message": user_msg,
        })


@app.websocket("/ws/blog")
async def blog_ws(websocket: WebSocket):
    await websocket.accept()
    uid = await _authenticate(websocket)

    try:
        try:
            first_message = StartMessage.model_validate(await websocket.receive_json())
        except (ValidationError, ValueError) as error:
            await websocket.send_json({"type": "error", "message": f"Invalid start message: {error}"})
            await websocket.close(code=4400)
            return

        if first_message.action != "start":
            await websocket.send_json({
                "type": "error",
                "message": "First message must be {'action': 'start', 'topic': ..., 'audience': ...}",
            })
            await websocket.close()
            return

        if not _allow_session(uid):
            await websocket.send_json({
                "type": "error",
                "message": "Too many sessions. Please wait a minute before trying again.",
            })
            await websocket.close(code=4429)
            return

        try:
            topic = _validate_text(first_message.topic or "", "topic", MAX_TOPIC_LENGTH)
            audience = _validate_text(first_message.audience, "audience", MAX_AUDIENCE_LENGTH)
        except ValueError as error:
            await websocket.send_json({"type": "error", "message": str(error)})
            await websocket.close(code=4400)
            return

        thread_id = first_message.thread_id or str(uuid.uuid4())
        config = {"configurable": {"thread_id": thread_id}}
        await websocket.send_json({"type": "started", "thread_id": thread_id})

        existing = await _graph.aget_state(config)
        if existing.values.get("topic"):
            if existing.values.get("user_id") != uid:
                await websocket.send_json({
                    "type": "error",
                    "message": "This session belongs to another user.",
                })
                await websocket.close(code=4403)
                return
            await websocket.send_json({
                "type": "error",
                "message": "Session reconnect is not supported yet. Start a new session.",
            })
            await websocket.close(code=4409)
            return
        else:
            initial_input = {
                "user_id": uid,
                "topic": topic,
                "audience": audience,
            }
            stream = _graph.astream(initial_input, config=config, stream_mode="updates")
            await _drain_stream(websocket, stream, thread_id, config)

        while True:
            try:
                message = ResumeMessage.model_validate(await websocket.receive_json())
            except (ValidationError, ValueError) as error:
                await websocket.send_json({"type": "error", "message": f"Invalid resume message: {error}"})
                continue

            if message.action != "resume":
                await websocket.send_json({
                    "type": "error",
                    "message": "Expected {'action': 'resume', 'decision': {...}}",
                })
                continue

            decision = message.decision
            if decision.action not in {"approve", "revise"}:
                await websocket.send_json({
                    "type": "error",
                    "message": "decision.action must be 'approve' or 'revise'",
                })
                continue
            if len(decision.feedback) > MAX_FEEDBACK_LENGTH:
                await websocket.send_json({
                    "type": "error",
                    "message": f"feedback exceeds the {MAX_FEEDBACK_LENGTH}-character limit",
                })
                continue

            stream = _graph.astream(
                Command(resume=decision.model_dump()),
                config=config,
                stream_mode="updates",
            )
            await _drain_stream(websocket, stream, thread_id, config)

    except WebSocketDisconnect:
        # Session state already lives in Firestore via the checkpointer - the
        # client can reconnect with the same thread_id and pick up from here
        # once the TODO above is filled in.
        pass


@app.get("/health")
async def health():
    return {"status": "ok"}
