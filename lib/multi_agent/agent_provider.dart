/// Supported AI provider backends for the Multi-Provider Agent.
enum AgentProvider {
  gemini(
    label: 'Gemini',
    subtitle: 'Google · gemini-2.0-flash',
    icon: '✦',
    color: 0xFF4285F4,
  ),
  groq(
    label: 'Groq',
    subtitle: 'Groq · llama-3.3-70b-versatile',
    icon: '⚡',
    color: 0xFF7C3AED,
  ),
  deepseek(
    label: 'DeepSeek',
    subtitle: 'DeepSeek · deepseek-chat',
    icon: '🔮',
    color: 0xFF06B6D4,
  );

  final String label;
  final String subtitle;
  final String icon;
  final int color;

  const AgentProvider({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  /// OpenAI-compatible base URL (Gemini uses its own SDK)
  String? get baseUrl {
    switch (this) {
      case AgentProvider.groq:
        return 'https://api.groq.com/openai/v1';
      case AgentProvider.deepseek:
        return 'https://api.deepseek.com/v1';
      case AgentProvider.gemini:
        return null; // uses Google Generative AI SDK
    }
  }

  /// Model name for the provider
  String get modelName {
    switch (this) {
      case AgentProvider.groq:
        return 'llama-3.3-70b-versatile';
      case AgentProvider.deepseek:
        return 'deepseek-chat';
      case AgentProvider.gemini:
        return 'gemini-2.0-flash';
    }
  }
}
