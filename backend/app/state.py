from pydantic import BaseModel


class BlogState(BaseModel):
    # Ownership (set from the verified Firebase ID token, not from client input)
    user_id: str = ""

    # User Input
    topic: str = ""
    audience: str = "general readers"

    # Researcher Output
    research: str = ""
    research_feedback: str = ""
    research_revision_count: int = 0

    # Writer Output
    draft: str = ""
    draft_feedback: str = ""
    revision_count: int = 0

    # Editor Output
    final_blog: str = ""
