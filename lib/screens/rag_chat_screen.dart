import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_client.dart';

class RagChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final List<Map<String, dynamic>> citations;
  final DateTime timestamp;

  RagChatMessage({
    required this.role,
    required this.content,
    this.citations = const [],
    required this.timestamp,
  });

  bool get isUser => role == 'user';
}

class RagChatScreen extends StatefulWidget {
  const RagChatScreen({super.key});

  @override
  State<RagChatScreen> createState() => _RagChatScreenState();
}

class _RagChatScreenState extends State<RagChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<RagChatMessage> _messages = [];

  bool _isSending = false;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final query = _inputController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSending = true;
      _messages.insert(
        0,
        RagChatMessage(
          role: 'user',
          content: query,
          timestamp: DateTime.now(),
        ),
      );
      _inputController.clear();
    });

    try {
      final response = await ApiClient.post(
        '/chat/query',
        body: {'query': query},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final answer = data['answer'] ?? 'No answer provided.';
        final rawCitations = data['citations'] as List<dynamic>? ?? [];

        final citations = rawCitations.map((c) {
          return {
            'filename': c['filename'] ?? 'Document',
            'score': c['score'] ?? 0.0,
            'text': c['text'] ?? '',
          };
        }).toList();

        setState(() {
          _isSending = false;
          _messages.insert(
            0,
            RagChatMessage(
              role: 'assistant',
              content: answer,
              citations: citations,
              timestamp: DateTime.now(),
            ),
          );
        });
      } else {
        final data = jsonDecode(response.body);
        final errorMsg = data['detail'] ?? 'Query failed (${response.statusCode})';
        setState(() {
          _isSending = false;
          _messages.insert(
            0,
            RagChatMessage(
              role: 'assistant',
              content: '❌ Error: $errorMsg',
              timestamp: DateTime.now(),
            ),
          );
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _messages.insert(
          0,
          RagChatMessage(
            role: 'assistant',
            content: '❌ Network error: $e',
            timestamp: DateTime.now(),
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
            Text(
              'Document RAG Chat',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Grounded Q&A with Source Citations',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty && !_isSending
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          size: 48,
                          color: theme.colorScheme.primary.withAlpha(128),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Ask questions about your uploaded documents',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SINRAS AI will answer using verified citations from your knowledge base.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    reverse: true,
                    itemCount: _messages.length + (_isSending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isSending && index == 0) {
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
                                'Searching documents and generating response...',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        );
                      }

                      final msgIndex = _isSending ? index - 1 : index;
                      final msg = _messages[msgIndex];

                      return _buildMessageBubble(msg, theme);
                    },
                  ),
          ),
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
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    maxLines: 4,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'Ask a question grounded in your documents...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  onPressed: _isSending ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(RagChatMessage msg, ThemeData theme) {
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
                    msg.isUser ? Icons.person_rounded : Icons.auto_awesome_rounded,
                    size: 16,
                    color: msg.isUser ? theme.colorScheme.primary : theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    msg.isUser ? 'You' : 'SINRAS AI',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
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
          const SizedBox(height: 8),
          SelectableText(
            msg.content,
            style: theme.textTheme.bodyMedium,
          ),
          if (msg.citations.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            Text(
              'Source Citations:',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            ...msg.citations.map((c) {
              return Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '📄 ${c['filename']}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          'Relevance: ${(c['score'] * 100).toStringAsFixed(0)}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '"${c['text']}"',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
