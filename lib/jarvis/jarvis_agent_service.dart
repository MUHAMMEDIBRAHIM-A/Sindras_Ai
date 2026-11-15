import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import '../multi_agent/agent_provider.dart';
import 'jarvis_controller.dart';

class JarvisResponse {
  final String speechText;
  final String fullOutput;
  final JarvisActionResult? executedAction;
  final String provider;

  const JarvisResponse({
    required this.speechText,
    required this.fullOutput,
    this.executedAction,
    required this.provider,
  });
}

class JarvisAgentService {
  final AgentProvider provider;
  final String apiKey;

  JarvisAgentService({
    required this.provider,
    required this.apiKey,
  });

  static const String systemInstruction = '''
You are SINRAS PRO, the ultimate autonomous AI Mobile OS Controller and System Assistant.
You have FULL authority to control mobile system actions, launch apps, run auto-tests, and execute commands for the user.

RULES:
1. Speak with polite executive authority ("At your service, sir", "Right away, sir", "SINRAS PRO systems nominal").
2. When the user asks to perform a mobile task, check device, open any app, run auto-test, or exit, trigger executable tool tags:
   - [[TOOL: {"action": "open_settings"}]] -> Opens mobile settings
   - [[TOOL: {"action": "open_camera"}]] -> Launches mobile camera
   - [[TOOL: {"action": "open_app", "app_name": "app name"}]] -> Launches any custom mobile app
   - [[TOOL: {"action": "open_maps", "query": "search query"}]] -> Searches Google Maps
   - [[TOOL: {"action": "open_dialer", "phone": "123456"}]] -> Opens phone dialer
   - [[TOOL: {"action": "send_sms", "phone": "123", "body": "msg"}]] -> Opens SMS composer
   - [[TOOL: {"action": "send_email", "email": "to@domain", "subject": "hi"}]] -> Opens email composer
   - [[TOOL: {"action": "open_calendar"}]] -> Launches calendar
   - [[TOOL: {"action": "open_alarm"}]] -> Launches clock & alarm
   - [[TOOL: {"action": "get_system_info"}]] -> Inspects CPU, Memory, OS & Battery
   - [[TOOL: {"action": "run_auto_test"}]] -> Runs automated mobile system diagnostics suite
   - [[TOOL: {"action": "exit_app"}]] -> Closes & exits the application

3. Keep speech concise, clear, and direct. Output clean Markdown if providing code or data.
''';

  Future<JarvisResponse> processVoiceCommand(String command) async {
    if (apiKey.isEmpty) {
      return const JarvisResponse(
        speechText: "API key is missing, sir. Please configure your key in Settings.",
        fullOutput: "❌ No API key set for provider. Please set your API key.",
        provider: 'SINRAS Core',
      );
    }

    String rawText = '';
    try {
      if (provider == AgentProvider.gemini) {
        final model = GenerativeModel(
          model: 'gemini-2.0-flash',
          apiKey: apiKey,
          systemInstruction: Content.system(systemInstruction),
        );
        final response = await model.generateContent([Content.text(command)]);
        rawText = response.text ?? 'Command received, sir.';
      } else {
        final baseUrl = provider.baseUrl!;
        final url = Uri.parse('$baseUrl/chat/completions');
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': provider.modelName,
            'messages': [
              {'role': 'system', 'content': systemInstruction},
              {'role': 'user', 'content': command},
            ],
            'temperature': 0.6,
          }),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          rawText = (data['choices'] as List).first['message']['content'] ?? '';
        } else {
          rawText = 'Server error (${response.statusCode}), sir.';
        }
      }
    } catch (e) {
      rawText = 'System error encountered, sir: $e';
    }

    // Parse Tool Tag: [[TOOL: {"action": "...", ...}]]
    JarvisActionResult? actionResult;
    final toolRegExp = RegExp(r'\[\[TOOL:\s*(\{.*?\})\s*\]\]');
    final match = toolRegExp.firstMatch(rawText);

    if (match != null) {
      try {
        final jsonString = match.group(1)!;
        final toolMap = jsonDecode(jsonString) as Map<String, dynamic>;
        final actionName = toolMap['action']?.toString() ?? '';
        actionResult = await JarvisController.executeAction(actionName, toolMap);
      } catch (e) {
        actionResult = JarvisActionResult(
          success: false,
          actionName: 'parse_error',
          message: 'Tool parse error: $e',
        );
      }
    }

    // Clean speech text by removing tool tags
    final speechText = rawText.replaceAll(toolRegExp, '').trim();

    return JarvisResponse(
      speechText: speechText.isEmpty ? 'Action executed, sir.' : speechText,
      fullOutput: rawText,
      executedAction: actionResult,
      provider: provider.label,
    );
  }
}
