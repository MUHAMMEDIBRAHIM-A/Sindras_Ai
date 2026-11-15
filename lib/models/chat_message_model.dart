/// A single chat message (user or assistant).
class ChatMessageModel {
  final String id;
  final String role;
  final String content;
  final Map<String, dynamic>? sourceChunks;
  final String createdAt;

  ChatMessageModel({
    required this.id,
    required this.role,
    required this.content,
    this.sourceChunks,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'],
      role: json['role'],
      content: json['content'],
      sourceChunks: json['source_chunks'],
      createdAt: json['created_at'],
    );
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}

/// A chat session (group of messages).
class ChatSessionModel {
  final String id;
  final String title;
  final String createdAt;

  ChatSessionModel({
    required this.id,
    required this.title,
    required this.createdAt,
  });

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) {
    return ChatSessionModel(
      id: json['id'],
      title: json['title'],
      createdAt: json['created_at'],
    );
  }
}

/// Source reference for a RAG answer.
class SourceReference {
  final String documentName;
  final int pageNumber;
  final String chunkText;
  final double relevanceScore;

  SourceReference({
    required this.documentName,
    required this.pageNumber,
    required this.chunkText,
    required this.relevanceScore,
  });

  factory SourceReference.fromJson(Map<String, dynamic> json) {
    return SourceReference(
      documentName: json['document_name'],
      pageNumber: json['page_number'],
      chunkText: json['chunk_text'],
      relevanceScore: (json['relevance_score'] as num).toDouble(),
    );
  }
}

/// Full RAG query response.
class RagResponse {
  final String answer;
  final List<SourceReference> sources;
  final String sessionId;

  RagResponse({
    required this.answer,
    required this.sources,
    required this.sessionId,
  });

  factory RagResponse.fromJson(Map<String, dynamic> json) {
    return RagResponse(
      answer: json['answer'],
      sources: (json['sources'] as List)
          .map((s) => SourceReference.fromJson(s))
          .toList(),
      sessionId: json['session_id'],
    );
  }
}
