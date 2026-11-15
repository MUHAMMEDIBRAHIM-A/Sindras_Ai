import 'dart:convert';
import '../models/document_model.dart';
import 'api_client.dart';

/// Service for managing documents (upload, list, delete).
class DocumentService {
  /// Upload a document file. Returns the created document or throws.
  static Future<DocumentModel> uploadDocument(String filePath, String filename) async {
    final response = await ApiClient.uploadFile(
      '/documents/upload',
      filePath,
      'file',
      filename: filename,
    );

    final body = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      return DocumentModel.fromJson(jsonDecode(body));
    } else {
      final error = jsonDecode(body);
      throw Exception(error['detail'] ?? 'Upload failed');
    }
  }

  /// List all documents for the current user.
  static Future<List<DocumentModel>> listDocuments() async {
    final response = await ApiClient.get('/documents');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final docs = (data['documents'] as List)
          .map((d) => DocumentModel.fromJson(d))
          .toList();
      return docs;
    } else {
      throw Exception('Failed to load documents');
    }
  }

  /// Delete a document by ID.
  static Future<void> deleteDocument(String documentId) async {
    final response = await ApiClient.delete('/documents/$documentId');
    if (response.statusCode != 204) {
      throw Exception('Failed to delete document');
    }
  }
}
