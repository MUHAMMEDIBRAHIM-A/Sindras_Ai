import 'package:flutter_test/flutter_test.dart';
import 'package:sinras/jarvis/jarvis_controller.dart';
import 'package:sinras/multi_agent/agent_provider.dart';
import 'package:sinras/multi_agent/multi_agent_type.dart';

void main() {
  group('SINRAS AI Multi-Agent & Provider Tests', () {
    test('AgentProvider enum contains Gemini, Groq, and DeepSeek', () {
      expect(AgentProvider.values.length, 3);
      expect(AgentProvider.gemini.label, 'Gemini');
      expect(AgentProvider.groq.label, 'Groq');
      expect(AgentProvider.deepseek.label, 'DeepSeek');
    });

    test('MultiAgentType contains 17 specialized agent roles', () {
      expect(MultiAgentType.values.length, 17);
      final categories = MultiAgentType.byCategory;
      expect(categories.containsKey('General'), true);
      expect(categories.containsKey('Code'), true);
      expect(categories.containsKey('Writing'), true);
      expect(categories.containsKey('Analysis'), true);
      expect(categories.containsKey('Productivity'), true);
      expect(categories.containsKey('Creative'), true);
      expect(categories.containsKey('Learning'), true);
    });

    test('JarvisController returns system info successfully', () async {
      final result = await JarvisController.executeAction('get_system_info', {});
      expect(result.success, true);
      expect(result.actionName, 'get_system_info');
      expect(result.data != null, true);
      expect(result.data!['status'], 'SINRAS PRO OS NOMINAL');
    });

    test('JarvisController runs auto-test suite successfully', () async {
      final result = await JarvisController.executeAction('run_auto_test', {});
      expect(result.success, true);
      expect(result.actionName, 'run_auto_test');
      expect(result.data!['status'], 'ALL TESTS PASSED');
    });
  });
}
