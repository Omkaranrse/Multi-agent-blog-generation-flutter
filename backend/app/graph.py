from typing import Literal

from langgraph.checkpoint.base import BaseCheckpointSaver
from langgraph.graph import StateGraph, START, END
from langgraph.types import interrupt

from .agents import get_llm, researcher_agent, writer_agent, editor_agent
from .state import BlogState

MAX_DRAFT_REVISIONS = 3
MAX_RESEARCH_REVISIONS = 3  # was previously uncapped - a human stuck in a loop
                            # of rejecting research would never reach the writer.


def researcher_node(state: BlogState) -> BlogState:
    """Researcher Agent generates (or revises) the research outline."""
    llm = get_llm()
    state.research = researcher_agent(
        llm=llm,
        topic=state.topic,
        audience=state.audience,
        feedback=state.research_feedback,
    )
    if state.research_feedback:
        state.research_revision_count += 1
    state.research_feedback = ""
    return state


def human_review_research_node(state: BlogState) -> BlogState:
    """Pause and ask the human to approve the research or send feedback."""
    decision = interrupt({
        "stage": "research_review",
        "research": state.research,
        "instructions": (
            "Reply with 'approve' to continue to writing, "
            "or provide feedback for the researcher to revise the research."
        ),
    })

    action, feedback = _parse_decision(decision)
    # Once we hit the revision cap, force approval so the pipeline can proceed.
    if action == "revise" and state.research_revision_count >= MAX_RESEARCH_REVISIONS:
        action, feedback = "approve", ""

    state.research_feedback = feedback
    return state


def writer_node(state: BlogState) -> BlogState:
    """Writer Agent produces the full draft blog (or revises it)."""
    llm = get_llm()
    state.draft = writer_agent(
        llm=llm,
        topic=state.topic,
        audience=state.audience,
        research=state.research,
        feedback=state.draft_feedback,
    )
    if state.draft_feedback:
        state.revision_count += 1
    state.draft_feedback = ""
    return state


def human_review_draft_node(state: BlogState) -> BlogState:
    """Pause and ask the human to approve the draft or send feedback."""
    decision = interrupt({
        "stage": "draft_review",
        "draft": state.draft,
        "instructions": (
            "Reply with 'approve' to send this to the editor, "
            "or describe what to change to send it back to the writer."
        ),
    })

    action, feedback = _parse_decision(decision)
    if action == "revise" and state.revision_count >= MAX_DRAFT_REVISIONS:
        action, feedback = "approve", ""

    state.draft_feedback = feedback
    return state


def editor_node(state: BlogState) -> BlogState:
    llm = get_llm()
    state.final_blog = editor_agent(llm=llm, topic=state.topic, draft=state.draft)
    return state


def _parse_decision(decision) -> tuple[str, str]:
    """Normalize whatever the client sent via resume() into (action, feedback)."""
    if isinstance(decision, dict):
        action = decision.get("action", "approve")
        feedback = decision.get("feedback", "")
    else:
        text = str(decision)
        action = "approve" if text.strip().lower() in ("approve", "yes", "approved", "ok", "", "proceed") else "revise"
        feedback = "" if action == "approve" else text
    return action, feedback


# ---------------------------------------------------------------------------
# Conditional edges
# ---------------------------------------------------------------------------

def route_after_research_review(state: BlogState) -> Literal["researcher_node", "writer_node"]:
    return "researcher_node" if state.research_feedback else "writer_node"


def route_after_draft_review(state: BlogState) -> Literal["writer_node", "editor_node"]:
    if state.draft_feedback and state.revision_count < MAX_DRAFT_REVISIONS:
        return "writer_node"
    return "editor_node"


# ---------------------------------------------------------------------------
# Build and compile the graph
# ---------------------------------------------------------------------------

def build_blog_graph(checkpointer: BaseCheckpointSaver) -> StateGraph:
    """
    checkpointer is injected rather than hardcoded so the same graph definition
    can run against InMemorySaver locally and a persistent saver (Firestore,
    Postgres, ...) in production - see checkpointer_factory.py.
    """
    builder = StateGraph(BlogState)

    builder.add_node("researcher_node", researcher_node)
    builder.add_node("human_review_research_node", human_review_research_node)
    builder.add_node("writer_node", writer_node)
    builder.add_node("human_review_draft_node", human_review_draft_node)
    builder.add_node("editor_node", editor_node)

    builder.add_edge(START, "researcher_node")
    builder.add_edge("researcher_node", "human_review_research_node")
    builder.add_conditional_edges(
        "human_review_research_node",
        route_after_research_review,
        {"researcher_node": "researcher_node", "writer_node": "writer_node"},
    )
    builder.add_edge("writer_node", "human_review_draft_node")
    builder.add_conditional_edges(
        "human_review_draft_node",
        route_after_draft_review,
        {"writer_node": "writer_node", "editor_node": "editor_node"},
    )
    builder.add_edge("editor_node", END)

    return builder.compile(checkpointer=checkpointer)
