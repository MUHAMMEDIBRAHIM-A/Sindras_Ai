import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'agent_role.dart';

class AgentService {
  final String apiKey;

  AgentService({required this.apiKey});

  Future<String> runTask({
    required AgentRole role,
    required String prompt,
    Uint8List? imageBytes,
    String mimeType = 'image/jpeg',
  }) async {
    if (apiKey.isEmpty || apiKey == 'YOUR_GEMINI_API_KEY') {
      return 'Please set a valid Gemini API key in AgentService or pass it from your configuration.';
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
        systemInstruction: Content.system(role.systemInstruction),
      );

      final parts = <Part>[];
      if (imageBytes != null) {
        parts.add(DataPart(mimeType, imageBytes));
      }
      parts.add(TextPart(prompt));

      final content = Content.multi(parts);
      final response = await model.generateContent([content]);
      return response.text ?? 'Agent completed task with no text output.';
    } catch (e) {
      return 'Agent Task Execution Error:\n$e';
    }
  }
}
