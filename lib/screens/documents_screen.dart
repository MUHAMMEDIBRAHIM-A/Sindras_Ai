import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/document_model.dart';
import '../services/document_service.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  List<DocumentModel> _documents = [];
  bool _isLoading = true;
  bool _isUploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final docs = await DocumentService.listDocuments();
      if (!mounted) return;
      setState(() {
        _documents = docs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load documents: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.path == null) return;

    setState(() => _isUploading = true);

    try {
      await DocumentService.uploadDocument(file.path!, file.name);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${file.name} uploaded and indexed successfully!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      await _loadDocuments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteDocument(DocumentModel doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text(
          'Delete "${doc.filename}" and all its indexed data? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await DocumentService.deleteDocument(doc.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document deleted')),
      );
      await _loadDocuments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  IconData _fileIcon(String type) {
    switch (type) {
      case 'PDF':
        return Icons.picture_as_pdf_rounded;
      case 'DOCX':
        return Icons.description_rounded;
      case 'TXT':
        return Icons.text_snippet_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _fileColor(String type, ThemeData theme) {
    switch (type) {
      case 'PDF':
        return Colors.red.shade400;
      case 'DOCX':
        return Colors.blue.shade400;
      case 'TXT':
        return Colors.green.shade400;
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Knowledge Base'),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDocuments,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _loadDocuments,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _documents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open_rounded,
                            size: 72,
                            color: theme.colorScheme.onSurfaceVariant.withAlpha(100),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No documents yet',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Upload PDF, DOCX, or TXT files to build\nyour knowledge base for AI Q&A.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _documents.length,
                      itemBuilder: (context, index) {
                        final doc = _documents[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _fileColor(doc.typeLabel, theme).withAlpha(30),
                              child: Icon(
                                _fileIcon(doc.typeLabel),
                                color: _fileColor(doc.typeLabel, theme),
                              ),
                            ),
                            title: Text(
                              doc.filename,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${doc.typeLabel} · ${doc.totalPages} page${doc.totalPages == 1 ? '' : 's'}',
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                              onPressed: () => _deleteDocument(doc),
                              tooltip: 'Delete',
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _uploadDocument,
        icon: _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.upload_file_rounded),
        label: Text(_isUploading ? 'Uploading...' : 'Upload Document'),
      ),
    );
  }
}
