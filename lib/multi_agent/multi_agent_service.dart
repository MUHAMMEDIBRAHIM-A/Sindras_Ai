import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'agent_provider.dart';
import 'multi_agent_type.dart';

/// Result from running a multi-provider agent task.
class AgentResult {
  final String text;
  final String provider;
  final String model;
  final int? inputTokens;
  final int? outputTokens;

  const AgentResult({
    required this.text,
    required this.provider,
    required this.model,
    this.inputTokens,
    this.outputTokens,
  });
}

/// Service that routes agent tasks to Gemini, Groq, or DeepSeek.
class MultiAgentService {
  final AgentProvider provider;
  final String apiKey;

  MultiAgentService({required this.provider, required this.apiKey});

  /// Run an agent task on the selected provider.
  /// [imageBytes] is only supported on Gemini.
  Future<AgentResult> runTask({
    required MultiAgentType agentType,
    required String prompt,
    Uint8List? imageBytes,
    String imageMimeType = 'image/jpeg',
  }) async {
    if (apiKey.trim().isEmpty) {
      return AgentResult(
        text: '❌ No API key set for ${provider.label}. '
            'Please add your key in Settings.',
        provider: provider.label,
        model: provider.modelName,
      );
    }

    try {
      switch (provider) {
        case AgentProvider.gemini:
          return await _runGemini(agentType, prompt, imageBytes, imageMimeType);
        case AgentProvider.groq:
          return await _runOpenAiCompatible(agentType, prompt);
        case AgentProvider.deepseek:
          return await _runOpenAiCompatible(agentType, prompt);
      }
    } catch (e) {
      return AgentResult(
        text: '❌ ${provider.label} Error:\n\n$e',
        provider: provider.label,
        model: provider.modelName,
      );
    }
  }

  // ── Gemini ─────────────────────────────────────────────────────────────

  Future<AgentResult> _runGemini(
    MultiAgentType agentType,
    String prompt,
    Uint8List? imageBytes,
    String imageMimeType,
  ) async {
    final model = GenerativeModel(
      model: provider.modelName,
      apiKey: apiKey,
      systemInstruction: Content.system(agentType.systemInstruction),
    );

    final parts = <Part>[];
    if (imageBytes != null) {
      parts.add(DataPart(imageMimeType, imageBytes));
    }
    parts.add(TextPart(prompt));

    final response = await model.generateContent([Content.multi(parts)]);
    final text = response.text ?? 'Agent completed with no text output.';

    return AgentResult(
      text: text,
      provider: provider.label,
      model: provider.modelName,
    );
  }

  // ── OpenAI-Compatible (Groq / DeepSeek) ───────────────────────────────

  Future<AgentResult> _runOpenAiCompatible(
    MultiAgentType agentType,
    String prompt,
  ) async {
    final baseUrl = provider.baseUrl!;
    final url = Uri.parse('$baseUrl/chat/completions');

    final body = jsonEncode({
      'model': provider.modelName,
      'messages': [
        {'role': 'system', 'content': agentType.systemInstruction},
        {'role': 'user', 'content': prompt},
      ],
      'temperature': 0.7,
      'max_tokens': 4096,
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      final errorMsg =
          errorBody['error']?['message'] ?? 'Unknown error (${response.statusCode})';
      throw Exception(errorMsg);
    }

    final data = jsonDecode(response.body);
    final text =
        (data['choices'] as List).first['message']['content'] as String? ??
            'No content returned.';

    final usage = data['usage'] as Map<String, dynamic>?;

    return AgentResult(
      text: text,
      provider: provider.label,
      model: provider.modelName,
      inputTokens: usage?['prompt_tokens'] as int?,
      outputTokens: usage?['completion_tokens'] as int?,
    );
  }
}
