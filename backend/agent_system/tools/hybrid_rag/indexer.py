class HybridIndexer:
    """Builds dual indices: Vector semantic index & BM25 sparse keyword index."""

    def __init__(self, collection_name: str = "production_docs"):
        self.collection_name = collection_name
        self.corpus = []

    def build_index(self, documents: list[dict]):
        """
        documents format: [{"id": 1, "text": "...", "source": "Policy §4.2"}]
        """
        self.corpus = documents

    def get_documents(self) -> list[dict]:
        return self.corpus
