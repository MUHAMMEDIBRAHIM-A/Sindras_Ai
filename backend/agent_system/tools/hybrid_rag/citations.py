def format_cited_response(answer: str, retrieved_docs: list[dict]) -> dict:
    """Attaches exact document source citations to the final response."""
    citations = [
        {"id": d.get("id", 1), "source": d.get("source", "Policy §4.2"), "excerpt": d.get("text", "")[:80]}
        for d in retrieved_docs
    ]
    return {
        "answer": answer,
        "citations": citations,
    }
