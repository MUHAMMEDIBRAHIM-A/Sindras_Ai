import 'package:flutter/material.dart';
import '../multi_agent/multi_agent_models.dart';
import '../multi_agent/multi_agent_storage.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<MultiAgentSession> _allSessions = [];
  List<MultiAgentSession> _filteredSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _searchController.addListener(_filterSessions);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final sessions = await MultiAgentStorage.loadSessions();
    if (mounted) {
      setState(() {
        _allSessions = sessions;
        _filteredSessions = sessions;
        _isLoading = false;
      });
    }
  }

  void _filterSessions() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() => _filteredSessions = _allSessions);
    } else {
      setState(() {
        _filteredSessions = _allSessions.where((s) {
          final titleMatch = s.title.toLowerCase().contains(query);
          final msgMatch = s.messages.any((m) => m.content.toLowerCase().contains(query));
          return titleMatch || msgMatch;
        }).toList();
      });
    }
  }

  Future<void> _deleteSession(String sessionId) async {
    await MultiAgentStorage.deleteSession(sessionId);
    await _loadHistory();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat session deleted.')),
      );
    }
  }

  Future<void> _clearAllHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Clear All History', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to permanently delete all saved chat conversations?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await MultiAgentStorage.clearAllSessions();
      await _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B101D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF060913),
        title: const Text(
          'Saved Chat History',
          style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
            tooltip: 'Clear All History',
            onPressed: _clearAllHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search Input Bar ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF0F172A),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search past conversations...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF00E5FF)),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),

          // ── History List ───────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)))
                : _filteredSessions.isEmpty
                    ? const Center(
                        child: Text(
                          'No saved chat history found.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filteredSessions.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final session = _filteredSessions[index];
                          final formattedTime = '${session.createdAt.day}/${session.createdAt.month}/${session.createdAt.year} ${session.createdAt.hour}:${session.createdAt.minute.toString().padLeft(2, '0')}';

                          return Card(
                            color: const Color(0xFF131C31),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: const Color(0xFF00E5FF).withAlpha(40)),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF00E5FF).withAlpha(30),
                                child: Text(
                                  session.agentType.name.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                session.title,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${session.provider.label} Engine · ${session.messages.length} messages · $formattedTime',
                                style: const TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                onPressed: () => _deleteSession(session.id),
                              ),
                              onTap: () {
                                _showSessionDetailsDialog(session);
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showSessionDetailsDialog(MultiAgentSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: Text(session.title, style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 16)),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: ListView.builder(
            itemCount: session.messages.length,
            itemBuilder: (context, index) {
              final msg = session.messages[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: msg.isUser ? const Color(0xFF1E293B) : const Color(0xFF131C31),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${msg.isUser ? "User" : "SINRAS"}: ${msg.content}',
                  style: TextStyle(color: msg.isUser ? Colors.white70 : Colors.white, fontSize: 12),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF00E5FF))),
          ),
        ],
      ),
    );
  }
}
