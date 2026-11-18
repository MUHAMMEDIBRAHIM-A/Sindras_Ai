import 'package:flutter/material.dart';
import '../multi_agent/multi_agent_models.dart';
import '../multi_agent/multi_agent_storage.dart';
import '../theme/theme_notifier.dart';
import '../utils/responsive_layout.dart';
import '../widgets/app_drawer.dart';

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
        title: const Text('Clear All History'),
        content: const Text(
          'Are you sure you want to permanently delete all saved chat conversations?',
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
    final isNight = Theme.of(context).brightness == Brightness.dark;
    final primary = isNight ? CyberPalette.nightPrimary : CyberPalette.morningPrimary;
    final secondary = isNight ? CyberPalette.nightSecondary : CyberPalette.morningSecondary;
    final cardBg = isNight ? CyberPalette.nightCard : CyberPalette.morningCard;
    final borderCol = isNight ? CyberPalette.nightBorder : CyberPalette.morningBorder;
    final textPri = isNight ? CyberPalette.nightTextPrimary : CyberPalette.morningTextPrimary;
    final textSec = isNight ? CyberPalette.nightTextSecondary : CyberPalette.morningTextSecondary;
    final inputBg = isNight ? CyberPalette.nightInput : CyberPalette.morningInput;

    return ResponsiveLayout.screenScaffold(
      context: context,
      backgroundColor: isNight ? CyberPalette.nightScaffold : CyberPalette.morningScaffold,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'SAVED CHAT & CALL LOGS',
          style: TextStyle(
            fontSize: ResponsiveLayout.scale(context, 14),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(bottom: BorderSide(color: borderCol)),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: textPri, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search conversations & voicemail summaries...',
                hintStyle: TextStyle(color: textSec.withAlpha(120), fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded, color: primary),
                filled: true,
                fillColor: inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: borderCol),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),

          // ── History List ───────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primary))
                : _filteredSessions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 48, color: textSec.withAlpha(100)),
                            const SizedBox(height: 12),
                            Text(
                              'No saved conversations found.',
                              style: TextStyle(color: textSec, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: ResponsiveLayout.pagePadding(context),
                        itemCount: _filteredSessions.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final session = _filteredSessions[index];
                          final formattedTime =
                              '${session.createdAt.day}/${session.createdAt.month}/${session.createdAt.year} ${session.createdAt.hour}:${session.createdAt.minute.toString().padLeft(2, '0')}';

                          return Container(
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderCol),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: primary.withAlpha(25),
                                child: Text(
                                  session.agentType.name.substring(0, 1).toUpperCase(),
                                  style: TextStyle(color: primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                session.title,
                                style: TextStyle(color: textPri, fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${session.provider.label} Engine · ${session.messages.length} messages · $formattedTime',
                                style: TextStyle(color: textSec, fontSize: 11),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                onPressed: () => _deleteSession(session.id),
                              ),
                              onTap: () {
                                _showSessionDetailsDialog(session, isNight, primary, secondary, cardBg, borderCol, textPri, textSec);
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

  void _showSessionDetailsDialog(
    MultiAgentSession session,
    bool isNight,
    Color primary,
    Color secondary,
    Color cardBg,
    Color borderCol,
    Color textPri,
    Color textSec,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBg,
        title: Text(
          session.title,
          style: TextStyle(color: primary, fontSize: 15, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 380,
          child: ListView.builder(
            itemCount: session.messages.length,
            itemBuilder: (context, index) {
              final msg = session.messages[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: msg.isUser
                      ? (isNight ? CyberPalette.nightInput : CyberPalette.morningInput)
                      : (isNight ? CyberPalette.nightCard : Colors.white),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderCol.withAlpha(80)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      msg.isUser ? "AGENT / OPERATOR" : "SINRAS AI",
                      style: TextStyle(
                        color: msg.isUser ? secondary : primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      msg.content,
                      style: TextStyle(color: textPri, fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: primary)),
          ),
        ],
      ),
    );
  }
}
