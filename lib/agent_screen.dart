import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'agent_role.dart';
import 'agent_service.dart';

class AgentScreen extends StatefulWidget {
  final String apiKey;

  const AgentScreen({super.key, required this.apiKey});

  @override
  State<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen> {
  AgentRole _selectedRole = AgentRole.general;
  final TextEditingController _promptController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isThinking = false;
  String _agentOutput = '';

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
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
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImageBytes = null;
      _selectedImageName = null;
    });
  }

  Future<void> _runTask() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isThinking = true;
      _agentOutput = '';
    });

    final service = AgentService(apiKey: widget.apiKey);
    final result = await service.runTask(
      role: _selectedRole,
      prompt: prompt,
      imageBytes: _selectedImageBytes,
    );

    if (mounted) {
      setState(() {
        _isThinking = false;
        _agentOutput = result;
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
            Text(
              'Sinras AI Agent',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Flutter Cross-Platform Agent Engine',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Agent Persona Selector
            Text(
              'Select Agent Persona',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),

            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: AgentRole.values.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final role = AgentRole.values[index];
                  final isSelected = (role == _selectedRole);

                  return InkWell(
                    onTap: () => setState(() => _selectedRole = role),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 170,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                role.icon,
                                size: 18,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  role.title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            role.description,
                            style: theme.textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Image attachment section
            if (_selectedImageBytes != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.memory(
                        _selectedImageBytes!,
                        width: 48,
                        height: 48,
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
                      icon: const Icon(Icons.close_rounded),
                      onPressed: _clearImage,
                      tooltip: 'Remove image',
                    ),
                  ],
                ),
              ),

            // Task input field
            TextField(
              controller: _promptController,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Describe agent task or request...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.image_outlined),
                  onPressed: () => _pickImage(ImageSource.gallery),
                  tooltip: 'Attach Image from Gallery',
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Action row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('Camera'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isThinking ? null : _runTask,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: const Text('Run Agent Task'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Output section
            Text(
              'Agent Execution Output',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(102),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SingleChildScrollView(
                  child: _isThinking
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: 32),
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Agent is reasoning and processing task...'),
                            ],
                          ),
                        )
                      : Text(
                          _agentOutput.isEmpty
                              ? 'Select an agent persona above and enter a task prompt to execute.'
                              : _agentOutput,
                          style: theme.textTheme.bodyMedium,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
