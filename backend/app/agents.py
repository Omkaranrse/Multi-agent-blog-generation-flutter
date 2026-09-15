"""
LLM agent functions for the blog pipeline: researcher, writer, editor.

Each agent is a plain function (llm, ...) -> str. They're kept framework-light
on purpose so graph.py can call them from LangGraph nodes without any
LangGraph-specific code leaking in here.
"""

import logging
import os

from langchain_core.prompts import ChatPromptTemplate
from langchain_groq import ChatGroq

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# LLM factory
# ---------------------------------------------------------------------------

_DEFAULT_MODEL = "openai/gpt-oss-20b"


def get_llm(temperature: float = 0.5) -> ChatGroq:
    api_key = os.environ.get("GROQ_API_KEY", "").strip()
    if not api_key:
        raise ValueError("GROQ_API_KEY environment variable is not set.")
    if api_key.startswith("your_") or len(api_key) < 20:
        raise ValueError(
            "GROQ_API_KEY looks like a placeholder. "
            "Get a real key from https://console.groq.com/keys"
        )
    model_name = os.environ.get("GROQ_MODEL", _DEFAULT_MODEL).strip() or _DEFAULT_MODEL
    logger.info("Using Groq model: %s", model_name)
    return ChatGroq(
        model=model_name,
        api_key=api_key,
        temperature=temperature,
    )


# ---------------------------------------------------------------------------
# Researcher Agent
# ---------------------------------------------------------------------------

RESEARCHER_PROMPT = ChatPromptTemplate.from_messages([
    ("system", """You are a Research Agent. Given a blog topic and target audience, produce a clear,
structured research outline. Include:
1. 5-7 key points the blog should cover
2. Important facts, statistics, or examples for each point
3. A suggested comparison, taxonomy, or breakdown table (with columns and sample rows) to organize key concepts
4. A suggested angle or hook
Be concise. Use bullet points and markdown tables where appropriate. Do NOT write the full blog yet."""),
    ("user", "Topic: {topic}, Audience: {audience}, {revision_hints}, Write the research outline now."),
])


def researcher_agent(llm: ChatGroq, topic: str, audience: str, feedback: str = "") -> str:
    if feedback:
        revision_hints = (
            f"Human provided this feedback on your previous research - "
            f"please address it: {feedback}."
        )
    else:
        revision_hints = "This is your first attempt."

    chain = RESEARCHER_PROMPT | llm
    result = chain.invoke({
        "topic": topic,
        "audience": audience,
        "revision_hints": revision_hints,
    })
    return result.content


# ---------------------------------------------------------------------------
# Writer Agent
# ---------------------------------------------------------------------------

WRITER_PROMPT = ChatPromptTemplate.from_messages([
    ("system", """You are a Blog Writer Agent. Using the research notes provided, write a complete,
engaging blog post.
Rules:
- Length: 500-800 words
- Structured: catchy title, intro hook, 3-5 sections with H2 headings, conclusion
- Include at least one clear, well-structured Markdown table (e.g., comparing approaches, component breakdown, or pros/cons) to make the content scannable and insightful
- Tone: clear, friendly, suited to the target audience
- Use markdown formatting
- Do NOT add a 'word count' line at the end"""),
    ("user", """Topic: {topic},
Audience: {audience},
Researcher Notes: {research}

{revision_hints}
Write the full blog post now."""),
])


def writer_agent(llm: ChatGroq, topic: str, audience: str, research: str, feedback: str = "") -> str:
    if feedback:
        revision_hints = (
            f"The Human provided this feedback on your previous draft and asked for these "
            f"changes: {feedback}. Please apply these changes while writing the blog."
        )
    else:
        revision_hints = "This is your first attempt."

    chain = WRITER_PROMPT | llm
    result = chain.invoke({
        "topic": topic,
        "audience": audience,
        "research": research,
        "revision_hints": revision_hints,
    })
    return result.content


# ---------------------------------------------------------------------------
# Editor Agent
# ---------------------------------------------------------------------------

EDITOR_PROMPT = ChatPromptTemplate.from_messages([
    ("system", """You are an Editor Agent - the final quality gate before publishing.
Take the draft and produce the FINAL polished version. Specifically:
- Fix grammar, spelling, and awkward phrasing
- Tighten wordy sentences
- Improve flow and transitions between sections
- Make the title and introduction more compelling if needed
- Preserve and ensure well-formatted markdown tables and clean headings
- Keep the same structure and markdown formatting
- Blog wording should sound human, not AI-generated. Avoid special characters and overly complex or fancy words.
Output only the final polished blog post. Do not include any commentary."""),
    ("user", """Topic: {topic},
Draft: {draft}

Return the published blog post."""),
])


def editor_agent(llm: ChatGroq, topic: str, draft: str) -> str:
    chain = EDITOR_PROMPT | llm
    result = chain.invoke({
        "topic": topic,
        "draft": draft,
    })
    return result.content
