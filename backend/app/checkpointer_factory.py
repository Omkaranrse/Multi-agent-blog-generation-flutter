"""
Returns the checkpoint saver LangGraph uses to persist paused/resumed state.

This is what makes interrupt()/resume work across requests and, in
production, across server restarts and multiple instances. InMemorySaver
loses everything on restart - fine for local dev, not for anything real.

Firestore backend uses the community `langgraph-checkpoint-firestore` package
(https://pypi.org/project/langgraph-checkpoint-firestore/), not a hand-rolled
implementation - re-implementing LangGraph's checkpoint interface correctly
(parent-checkpoint chains, pending writes per channel) is nontrivial and easy
to get subtly wrong. Pin the version in requirements.txt and re-test this
factory after any upgrade of that package or of langgraph itself, since the
checkpoint interface has changed across langgraph releases before.
"""

import os

from langgraph.checkpoint.base import BaseCheckpointSaver
from langgraph.checkpoint.memory import InMemorySaver


def get_checkpointer() -> BaseCheckpointSaver:
    backend = os.environ.get("CHECKPOINT_BACKEND", "memory").strip().lower() or "memory"

    if backend == "memory":
        return InMemorySaver()

    if backend != "firestore":
        raise ValueError(f"Unknown CHECKPOINT_BACKEND: {backend!r} (expected 'firestore' or 'memory')")

    # Imported lazily so `CHECKPOINT_BACKEND=memory` works without the
    # google-cloud-firestore dependency installed / GCP credentials configured.
    from langgraph_checkpoint_firestore import FirestoreSaver

    project_id = os.environ.get("GCP_PROJECT_ID")
    if not project_id:
        raise ValueError("GCP_PROJECT_ID must be set when CHECKPOINT_BACKEND=firestore")

    collection = os.environ.get("CHECKPOINT_COLLECTION", "blog_checkpoints")

    # Uses Application Default Credentials - `gcloud auth application-default
    # login` locally, or a service account + GOOGLE_APPLICATION_CREDENTIALS /
    # attached service account identity on Cloud Run.
    return FirestoreSaver(project_id=project_id, checkpoints_collection=collection)
