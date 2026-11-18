import 'agent_provider.dart';
import 'multi_agent_type.dart';

/// Keys for storing API keys in secure storage.
class MultiAgentKeys {
  MultiAgentKeys._();

  static const String geminiKey = 'multi_agent_gemini_key';
  static const String groqKey = 'multi_agent_groq_key';
  static const String deepseekKey = 'multi_agent_deepseek_key';
}

/// Chat history entry for the multi-agent session.
class MultiAgentMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final String provider;
  final String agentType;
  final DateTime timestamp;
  final int? inputTokens;
  final int? outputTokens;

  MultiAgentMessage({
    required this.role,
    required this.content,
    required this.provider,
    required this.agentType,
    required this.timestamp,
    this.inputTokens,
    this.outputTokens,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  String get tokenInfo {
    if (inputTokens == null && outputTokens == null) return '';
    final parts = <String>[];
    if (inputTokens != null) parts.add('↑$inputTokens');
    if (outputTokens != null) parts.add('↓$outputTokens');
    return parts.join(' ');
  }
}

/// Multi-Agent Chat Session Model.
class MultiAgentSession {
  final String id;
  final String title;
  final MultiAgentType agentType;
  final AgentProvider provider;
  final List<MultiAgentMessage> messages;
  final DateTime createdAt;

  MultiAgentSession({
    required this.id,
    required this.title,
    required this.agentType,
    required this.provider,
    required this.messages,
    required this.createdAt,
  });
}
