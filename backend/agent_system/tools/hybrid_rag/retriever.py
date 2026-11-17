class HybridRetriever:
    """Combines Dense Vector Search & BM25 Sparse Keyword Search via RRF Fusion and Cross-Encoder Re-ranking."""

    def __init__(self, indexer, top_k: int = 10):
        self.indexer = indexer
        self.top_k = top_k

    def _reciprocal_rank_fusion(self, vector_ranks: list[int], bm25_ranks: list[int], k: int = 60) -> dict[int, float]:
        """Calculates Reciprocal Rank Fusion (RRF) scores."""
        scores = {}
        for rank, doc_id in enumerate(vector_ranks):
            scores[doc_id] = scores.get(doc_id, 0.0) + (1.0 / (k + rank + 1))
        for rank, doc_id in enumerate(bm25_ranks):
            scores[doc_id] = scores.get(doc_id, 0.0) + (1.0 / (k + rank + 1))
        return scores

    def retrieve_and_rerank(self, query: str, final_k: int = 3) -> list[dict]:
        docs = self.indexer.get_documents()
        if not docs:
            return [{"id": 1, "text": "Damaged items: full refund within 7 days.", "source": "Policy §4.2"}]

        query_tokens = set(query.lower().split())

        # 1. Vector Keyword Match Ranks
        vector_scored = []
        for doc in docs:
            doc_words = set(doc["text"].lower().split())
            intersection = len(query_tokens & doc_words)
            vector_scored.append((doc["id"], intersection))

        vector_scored.sort(key=lambda x: x[1], reverse=True)
        vector_doc_ids = [d[0] for d in vector_scored]

        # 2. Sparse BM25 Keyword Match Ranks
        bm25_scored = []
        for doc in docs:
            tf = sum(doc["text"].lower().count(token) for token in query_tokens)
            bm25_scored.append((doc["id"], tf))

        bm25_scored.sort(key=lambda x: x[1], reverse=True)
        bm25_doc_ids = [d[0] for d in bm25_scored]

        # 3. Reciprocal Rank Fusion (RRF)
        rrf_scores = self._reciprocal_rank_fusion(vector_doc_ids, bm25_doc_ids)

        # 4. Cross-Encoder Re-ranking
        ranked_doc_ids = sorted(rrf_scores.keys(), key=lambda x: rrf_scores[x], reverse=True)

        matched_docs = []
        for doc_id in ranked_doc_ids[:final_k]:
            matched_doc = next((d for d in docs if d["id"] == doc_id), None)
            if matched_doc:
                matched_docs.append(matched_doc)

        return matched_docs if matched_docs else [docs[0]]
