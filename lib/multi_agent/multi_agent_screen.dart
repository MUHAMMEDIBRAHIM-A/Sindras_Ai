import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'agent_provider.dart';
import 'multi_agent_models.dart';
import 'multi_agent_service.dart';
import 'multi_agent_storage.dart';
import 'multi_agent_type.dart';

class MultiAgentScreen extends StatefulWidget {
  const MultiAgentScreen({super.key});

  @override
  State<MultiAgentScreen> createState() => _MultiAgentScreenState();
}

class _MultiAgentScreenState extends State<MultiAgentScreen> {
  AgentProvider _selectedProvider = AgentProvider.gemini;
  MultiAgentType _selectedAgent = MultiAgentType.generalAssistant;

  final TextEditingController _promptController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isExecuting = false;

  final Map<AgentProvider, String> _apiKeys = {};
  final List<MultiAgentMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadApiKeys();
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKeys() async {
    final gemini = await MultiAgentStorage.readKey(MultiAgentKeys.geminiKey);
    final groq = await MultiAgentStorage.readKey(MultiAgentKeys.groqKey);
    final deepseek = await MultiAgentStorage.readKey(MultiAgentKeys.deepseekKey);

    if (mounted) {
      setState(() {
        _apiKeys[AgentProvider.gemini] = gemini;
        _apiKeys[AgentProvider.groq] = groq;
        _apiKeys[AgentProvider.deepseek] = deepseek;
      });
    }
  }

  Future<void> _saveApiKey(AgentProvider provider, String key) async {
    String storageKey;
    switch (provider) {
      case AgentProvider.gemini:
        storageKey = MultiAgentKeys.geminiKey;
        break;
      case AgentProvider.groq:
        storageKey = MultiAgentKeys.groqKey;
        break;
      case AgentProvider.deepseek:
        storageKey = MultiAgentKeys.deepseekKey;
        break;
    }
    await MultiAgentStorage.writeKey(storageKey, key.trim());
    setState(() {
      _apiKeys[provider] = key.trim();
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedProvider != AgentProvider.gemini) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image inputs are currently supported on Gemini provider.'),
        ),
      );
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        final bytes = await image.readAsBytes();
        if (!mounted) return;
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = image.name;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image selection error: $e')),
      );
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImageBytes = null;
      _selectedImageName = null;
    });
  }

  void _showApiKeyDialog(AgentProvider provider) {
    final controller = TextEditingController(text: _apiKeys[provider] ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(provider.icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text('${provider.label} API Key'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your ${provider.label} API key below.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Paste API key here...',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.key_rounded),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () => controller.clear(),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _saveApiKey(provider, controller.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${provider.label} API key updated.')),
              );
            },
            child: const Text('Save Key'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeAgentTask() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    final apiKey = _apiKeys[_selectedProvider] ?? '';
    if (apiKey.isEmpty) {
      _showApiKeyDialog(_selectedProvider);
      return;
    }

    setState(() {
      _isExecuting = true;
      _messages.insert(
        0,
        MultiAgentMessage(
          role: 'user',
          content: prompt,
          provider: _selectedProvider.label,
          agentType: _selectedAgent.title,
          timestamp: DateTime.now(),
        ),
      );
    });

    final service = MultiAgentService(
      provider: _selectedProvider,
      apiKey: apiKey,
    );

    final result = await service.runTask(
      agentType: _selectedAgent,
      prompt: prompt,
      imageBytes: _selectedImageBytes,
    );

    if (mounted) {
      setState(() {
        _isExecuting = false;
        _selectedImageBytes = null;
        _selectedImageName = null;
        _promptController.clear();
        _messages.insert(
          0,
          MultiAgentMessage(
            role: 'assistant',
            content: result.text,
            provider: result.provider,
            agentType: _selectedAgent.title,
            timestamp: DateTime.now(),
            inputTokens: result.inputTokens,
            outputTokens: result.outputTokens,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Multi-Agent System',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'NEW ENGINE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'Gemini · Groq (JARVIS/FRIDAY) · DeepSeek',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.vpn_key_rounded),
            tooltip: 'Manage Provider API Keys',
            onPressed: () => _showApiKeyDialog(_selectedProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Provider Selector (FRIDAY / JARVIS / DEEPSEEK) ────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
            child: Row(
              children: AgentProvider.values.map((provider) {
                final isSelected = provider == _selectedProvider;
                final hasKey = (_apiKeys[provider] ?? '').isNotEmpty;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: InkWell(
                      onTap: () => setState(() => _selectedProvider = provider),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Color(provider.color).withAlpha(40)
                              : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? Color(provider.color)
                                : theme.colorScheme.outlineVariant,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(provider.icon, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                provider.label,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected
                                      ? Color(provider.color)
                                      : theme.colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              hasKey ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                              size: 12,
                              color: hasKey ? Colors.green : Colors.orange,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Agent Selector Chips ──────────────────────────────────────
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              scrollDirection: Axis.horizontal,
              itemCount: MultiAgentType.values.length,
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final agent = MultiAgentType.values[index];
                final isSelected = agent == _selectedAgent;

                return FilterChip(
                  selected: isSelected,
                  avatar: Icon(agent.icon, size: 14),
                  label: Text(agent.title),
                  onSelected: (_) => setState(() => _selectedAgent = agent),
                );
              },
            ),
          ),

          // ── Selected Agent Info Bar ────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: theme.colorScheme.surfaceContainerLow,
            child: Row(
              children: [
                Icon(_selectedAgent.icon, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_selectedAgent.title} — ${_selectedAgent.description}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Execution Output / History ──────────────────────────────────
          Expanded(
            child: _messages.isEmpty && !_isExecuting
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selectedAgent.icon,
                          size: 48,
                          color: theme.colorScheme.primary.withAlpha(128),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Ready to execute ${_selectedAgent.title}',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Provider: ${_selectedProvider.label} (${_selectedProvider.modelName})',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    reverse: true,
                    itemCount: _messages.length + (_isExecuting ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isExecuting && index == 0) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${_selectedProvider.label} agent is thinking & processing...',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        );
                      }

                      final msgIndex = _isExecuting ? index - 1 : index;
                      final msg = _messages[msgIndex];

                      return _buildMessageCard(msg, theme);
                    },
                  ),
          ),

          // ── Attached Image Preview ─────────────────────────────────────
          if (_selectedImageBytes != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.colorScheme.surfaceContainerHigh,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.memory(
                      _selectedImageBytes!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedImageName ?? 'Attached Image',
                      style: theme.textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: _clearImage,
                  ),
                ],
              ),
            ),

          // ── Prompt Input Bar ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_selectedProvider == AgentProvider.gemini) ...[
                  IconButton(
                    icon: const Icon(Icons.image_outlined),
                    tooltip: 'Attach Image (Gallery)',
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt_outlined),
                    tooltip: 'Attach Image (Camera)',
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                ],
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    maxLines: 4,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'Task for ${_selectedAgent.title} (${_selectedProvider.label})...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: _isExecuting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded),
                  onPressed: _isExecuting ? null : _executeAgentTask,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(MultiAgentMessage msg, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: msg.isUser
            ? theme.colorScheme.primaryContainer.withAlpha(150)
            : theme.colorScheme.surfaceContainerHighest.withAlpha(150),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: msg.isUser
              ? theme.colorScheme.primary.withAlpha(80)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    msg.isUser ? Icons.person_rounded : Icons.smart_toy_rounded,
                    size: 16,
                    color: msg.isUser ? theme.colorScheme.primary : theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    msg.isUser ? 'You' : '${msg.agentType} (${msg.provider})',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (msg.tokenInfo.isNotEmpty) ...[
                    Text(
                      msg.tokenInfo,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Copy',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: msg.content));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            msg.content,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
