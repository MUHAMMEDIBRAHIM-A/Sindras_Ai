import 'dart:convert';
import '../models/chat_message_model.dart';
import 'api_client.dart';

/// Service for RAG queries and chat history.
class RagService {
  /// Send a question to the RAG system. Returns the answer with sources.
  static Future<RagResponse> query(
    String question, {
    String? sessionId,
    int topK = 5,
  }) async {
    final body = <String, dynamic>{
      'question': question,
      'top_k': topK,
    };
    if (sessionId != null) {
      body['session_id'] = sessionId;
    }

    final response = await ApiClient.post('/rag/query', body: body);

    if (response.statusCode == 200) {
      return RagResponse.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Query failed');
    }
  }

  /// List all chat sessions.
  static Future<List<ChatSessionModel>> listSessions() async {
    final response = await ApiClient.get('/rag/sessions');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((s) => ChatSessionModel.fromJson(s)).toList();
    } else {
      throw Exception('Failed to load sessions');
    }
  }

  /// Get all messages for a session.
  static Future<List<ChatMessageModel>> getSessionMessages(String sessionId) async {
    final response = await ApiClient.get('/rag/sessions/$sessionId/messages');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((m) => ChatMessageModel.fromJson(m)).toList();
    } else {
      throw Exception('Failed to load messages');
    }
  }
}
